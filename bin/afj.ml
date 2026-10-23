module Path = Yocaml.Path

let default_port = 8000
let default_target = Path.rel [ "_www" ]
let default_cache = Path.rel [ "_cache" ]

let current_date () =
  let t = Unix.localtime (Unix.time ()) in
  (t.tm_year + 1900, t.tm_mon + 1, t.tm_mday)

let run ~target_folder ~cache_folder ~today =
  let resolver = Afj.Resolver.make ~cache_folder ~target_folder () in
  let today = Option.value today ~default:(current_date ()) in
  Afj.Env.handle resolver (Afj.Rule.run ~resolver ~today)

module Cmd = struct
  open Cmdliner

  let docs = Manpage.s_common_options
  let exits = Cmd.Exit.defaults
  let version = "dev"

  let path_conv =
    Arg.conv ~docv:"PATH"
      ((fun str -> str |> Path.from_string |> Result.ok), Path.pp)

  let date_conv =
    let parser str =
      match Afj.Model.Calendar.date_of_string str with
      | Some date -> Ok date
      | None -> Error (`Msg "Expected a date YYYY-MM-DD")
    and printer ppf ((year, month, day) : Afj.Model.Calendar.date) =
      Format.fprintf ppf "%04d-%02d-%02d" year month day
    in
    Arg.conv ~docv:"DATE" (parser, printer)

  let target_arg =
    let doc = "target directory" in
    let arg = Arg.info ~doc ~docs [ "target"; "output" ] in
    Arg.(value @@ opt path_conv default_target arg)

  let cache_arg =
    let doc = "cache directory" in
    let arg = Arg.info ~doc ~docs [ "cache" ] in
    Arg.(value @@ opt path_conv default_cache arg)

  let today_arg =
    let doc =
      "The date of the build: only events not finished at this date are shown \
       in the agenda (default: today)."
    in
    let arg = Arg.info ~doc ~docs [ "today" ] in
    Arg.(value @@ opt (some date_conv) None arg)

  let port_arg =
    let doc = "The port for the server (default: [%d])." in
    let arg = Arg.info ~doc ~docs [ "port"; "P" ] in
    Arg.(value @@ opt int default_port arg)

  let build =
    let doc = "Build the website" in
    let info = Cmd.info "build" ~version ~doc ~exits in
    let term =
      Term.(
        const (fun target_folder cache_folder today ->
            Yocaml_unix.run ~level:`Info
              (run ~target_folder ~cache_folder ~today))
        $ target_arg $ cache_arg $ today_arg)
    in
    Cmd.v info term

  let watch =
    let doc = "Launch a local server, rebuilding the site on each request" in
    let info = Cmd.info "watch" ~version ~doc ~exits in
    let term =
      Term.(
        const (fun target_folder cache_folder today port ->
            Yocaml_unix.serve ~target:target_folder ~level:`Info ~port
              (run ~target_folder ~cache_folder ~today))
        $ target_arg $ cache_arg $ today_arg $ port_arg)
    in
    Cmd.v info term

  let index =
    let doc =
      "Generator of the website of the Association Française de Jonglerie"
    in
    let info = Cmd.info "afj" ~version ~doc ~sdocs:docs ~exits in
    let default = Term.(ret @@ const (`Help (`Pager, None))) in
    Cmd.group info ~default [ build; watch ]
end

let () = exit @@ Cmdliner.Cmd.eval Cmd.index
