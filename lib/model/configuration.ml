type t = {
  title : string;
  url : string;
  description : string;
  body_classes : string list;
}

let entity_name = "Configuration"
let neutral = Yocaml.Metadata.required entity_name

let validate =
  let open Yocaml.Data.Validation in
  record (fun fields ->
      let+ title = required fields "title" (string & String.not_blank)
      and+ url = required fields "url" (string & String.not_blank)
      and+ description = required fields "description" string
      and+ body_classes =
        optional_or fields "body_classes" ~default:[] (list_of string)
      in
      { title; url; description; body_classes })

let normalize { title; url; description; body_classes = _ } =
  let open Yocaml.Data in
  record
    [
      ("title", string title);
      ("url", string url);
      ("description", string description);
    ]
