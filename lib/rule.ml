module Page = Archetype.Page
module Home = Archetype.Home
open Yocaml

let track_binary = Pipeline.track_file Resolver.binary
let is_markdown = Path.has_extension "md"

let is_image path =
  List.exists
    (fun ext -> Path.has_extension ext path)
    [ "jpg"; "jpeg"; "png"; "gif"; "webp"; "JPG"; "JPEG"; "PNG" ]

let assets resolver =
  let templates = Resolver.Source.templates resolver in
  Batch.iter_tree
    ~where:(fun kind path ->
      match kind with
      | `Directory -> not (Path.equal path templates)
      | `File -> true)
    (Resolver.Source.assets resolver)
    (fun file ->
      let into =
        Resolver.Target.asset_dir resolver ~source:(Path.dirname file)
      in
      Action.copy_file ~into file)

(* Files of a page folder (PDFs, images…) and of its sub-folders that are not
   pages (e.g. the posters of a gallery) are published next to the page. *)
let files resolver (node : Model.Site.node) =
  let into = Resolver.Target.page_dir resolver node.slugs in
  let open Eff in
  Batch.iter_files ~where:(Fun.negate is_markdown) node.dir
    (Action.copy_file ~into)
  >=> Batch.iter node.asset_dirs (fun (dir, _) ->
      Batch.iter_files
        Path.(node.dir / dir)
        (Action.copy_file ~into:Path.(into / dir)))

(* ImageMagick 7 provides [magick], ImageMagick 6 (e.g. Ubuntu) [convert]. *)
let imagemagick =
  lazy
    (if Sys.command "command -v magick > /dev/null 2>&1" = 0 then "magick"
     else "convert")

(* A 400px high thumbnail (galleries display them 200px high).
   [Action.exec_cmd] is not used because [Cmd] does not quote arguments, and
   the names of the posters contain spaces and parentheses. *)
let thumbnail ~into source =
  let target = Path.(into / Option.value ~default:"" (Path.basename source)) in
  let task =
    Task.make ~has_dynamic_dependencies:false (Deps.singleton source) (fun () ->
        let open Eff in
        let quote path = Filename.quote (Path.to_string path) in
        let* () = create_directory ~on:`Target into in
        let+ _output =
          exec (Lazy.force imagemagick)
            ~args:
              [
                quote source;
                "-auto-orient";
                "-thumbnail";
                Filename.quote "x400>";
                "-quality";
                "82";
                quote target;
              ]
        in
        ())
  in
  let run _ _ eff cache = Eff.map (fun () -> cache) (eff ()) in
  Action.perform target task ~when_creation:run ~when_update:run

let thumbnails resolver (node : Model.Site.node) =
  let into = Resolver.Target.page_dir resolver node.slugs in
  let open Eff in
  Batch.iter_files ~where:is_image node.dir
    (thumbnail ~into:Path.(into / "thumbs"))
  >=> Batch.iter node.asset_dirs (fun (dir, _) ->
      Batch.iter_files ~where:is_image
        Path.(node.dir / dir)
        (thumbnail ~into:Path.(into / dir / "thumbs")))

let markdown_to_html ?list_dir content =
  content
  |> Util.Shortcodes.expand ?list_dir
  |> Yocaml_markdown.from_string_to_html
       ~highlight:Yocaml_markdown.Doc.no_highlighting
  |> Util.Shortcodes.target_blank

let page resolver ~site ((node : Model.Site.node), ancestors) =
  let list_dir dir =
    Model.Site.files_of node dir
    |> List.filter (fun f -> is_image (Path.rel [ f ]))
  in
  let pipeline =
    let open Task in
    let+ () = track_binary
    (* The navigation is built from all the pages. *)
    and+ () = Pipeline.track_file (Resolver.Source.pages resolver)
    and+ configuration = Env.configuration resolver
    and+ templates = Util.Template.chain resolver [ "page"; "layout" ]
    and+ page, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata
        (module Model.Page)
        (Model.Site.source node)
    in
    let document =
      Page.as_document ~configuration ~site ~node ~ancestors page
    in
    content |> markdown_to_html ~list_dir
    |> templates (module Page.Html) ~metadata:document
  in
  Action.Static.write_file (Resolver.Target.page resolver node.slugs) pipeline

(* Blocks of the home page are the Markdown files next to its default.md. *)
let fetch_blocks (node : Model.Site.node) =
  let open Task in
  let+ blocks =
    Pipeline.fetch ~only:`Files
      ~where:(fun path ->
        is_markdown path && Path.basename path <> Some Model.Site.page_file)
      (fun path ->
        let open Eff in
        let+ block, content =
          Yocaml_yaml.Eff.read_file_with_metadata
            (module Model.Home_block)
            ~on:`Source path
        in
        (path, (block, content)))
      node.dir
  in
  blocks
  |> List.sort (fun (a, _) (b, _) -> Path.compare a b)
  |> List.map (fun (_, (block, content)) -> (block, markdown_to_html content))

let home resolver ~site ~today (node : Model.Site.node) =
  let pipeline =
    let open Task in
    let+ () = track_binary
    and+ () = Pipeline.track_file (Resolver.Source.pages resolver)
    (* The agenda only shows upcoming events. *)
    and+ () = Pipeline.track_file (Resolver.Cache.today resolver)
    and+ configuration = Env.configuration resolver
    and+ templates = Util.Template.chain resolver [ "home"; "layout" ]
    and+ page, _content =
      Yocaml_yaml.Pipeline.read_file_with_metadata
        (module Model.Page)
        (Model.Site.source node)
    and+ blocks = fetch_blocks node
    and+ ics = Pipeline.read_file (Resolver.Source.calendar resolver) in
    let calendar = Model.Calendar.agenda ~today ics in
    let document =
      Home.as_document ~configuration ~site ~node ~blocks ~calendar page
    in
    "" |> templates (module Home.Html) ~metadata:document
  in
  Action.Static.write_file (Resolver.Target.page resolver node.slugs) pipeline

let pages resolver ~site ~today =
  Batch.iter (Model.Site.flatten site)
    (fun (((node : Model.Site.node), _) as entry) ->
      let open Eff in
      let html =
        if not node.page.clickable then return
        else if Model.Site.is_home node then home resolver ~site ~today node
        else page resolver ~site entry
      in
      files resolver node
      >=> (if node.has_gallery then thumbnails resolver node else return)
      >=> html)

(* The date stamp is only rewritten when the date changes. *)
let stamp_today resolver ((year, month, day) : Model.Calendar.date) =
  let open Eff in
  let file = Resolver.Cache.today resolver in
  let stamp = Printf.sprintf "%04d-%02d-%02d" year month day in
  let* exists = file_exists ~on:`Source file in
  let* current = if exists then read_file ~on:`Source file else return "" in
  if String.equal current stamp then return ()
  else write_file ~on:`Source file stamp

let run ~resolver ~today () =
  let open Eff in
  let cache_file = Resolver.Cache.global resolver in
  let* () = stamp_today resolver today in
  let* site = Model.Site.scan (Resolver.Source.pages resolver) in
  Action.restore_cache ~on:`Source cache_file
  >>= assets resolver
  >>= pages resolver ~site ~today
  >>= Action.remove_residuals ~target:(Resolver.Target.root resolver)
  >>= Action.store_cache ~on:`Source cache_file
