type _ Effect.t += Afj_get_configuration : Model.Configuration.t Effect.t

let get_configuration () = Yocaml.Eff.perform Afj_get_configuration

let read_configuration configuration_path =
  let open Yocaml.Eff in
  function
  | Some configuration -> return configuration
  | None ->
      let* () =
        logf "Read configuration from [%a]" Yocaml.Path.pp configuration_path
      in
      Yocaml_yaml.Eff.read_file_as_metadata
        (module Model.Configuration)
        ~on:`Source configuration_path

let handle resolver program input =
  let config : Model.Configuration.t option ref = ref None in
  let configuration_path = Resolver.Source.configuration resolver in
  match program input with
  | x -> x
  | effect Afj_get_configuration, k ->
      let open Yocaml.Eff in
      let* result = read_configuration configuration_path !config in
      let () = config := Some result in
      Effect.Deep.continue k result

let configuration resolver =
  let path = Resolver.Source.configuration resolver in
  Yocaml.Task.make ~has_dynamic_dependencies:false
    (Yocaml.Deps.singleton path)
    get_configuration
