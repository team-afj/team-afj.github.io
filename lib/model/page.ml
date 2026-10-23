type file = { name : string; file : string }
type section = { section_name : string option; files : file list }

type t = {
  title : string;
  description : string option;
  visible : bool option;
  clickable : bool;
  book : bool;
  published : bool;
  template : string option;
  body_classes : string option;
  sidebar_files : section list;
}

let entity_name = "Page"
let neutral = Yocaml.Metadata.required entity_name

let validate_file =
  let open Yocaml.Data.Validation in
  record (fun fields ->
      let+ name = required fields "name" string
      and+ file = required fields "file" string in
      { name; file })

let validate_section =
  let open Yocaml.Data.Validation in
  record (fun fields ->
      let+ section_name = optional fields "section_name" string
      and+ files =
        optional_or fields "files" ~default:[] (list_of validate_file)
      in
      { section_name; files })

let validate =
  let open Yocaml.Data.Validation in
  record (fun fields ->
      let+ title = required fields "title" string
      and+ metadata =
        optional fields "metadata"
          (record (fun m -> optional m "description" string))
      and+ visible = optional fields "visible" bool
      and+ clickable = optional_or fields "clickable" ~default:true bool
      and+ book = optional_or fields "book" ~default:false bool
      and+ published = optional_or fields "published" ~default:true bool
      and+ template = optional fields "template" string
      and+ body_classes = optional fields "body_classes" string
      and+ sidebar_files =
        optional_or fields "sidebar_files" ~default:[]
          (list_of validate_section)
      in
      {
        title;
        description = Option.join metadata;
        visible;
        clickable;
        book;
        published;
        template;
        body_classes;
        sidebar_files;
      })

let icon file =
  match Filename.extension file |> String.lowercase_ascii with
  | ".pdf" -> "la-file-pdf"
  | ".zip" -> "la-file-archive"
  | _ -> "la-file"

let normalize_file { name; file } =
  let open Yocaml.Data in
  record
    [
      ("name", string name);
      ("url", string (Util.Url.encode file));
      ("icon", string (icon file));
    ]

let normalize_section { section_name; files } =
  let open Yocaml.Data in
  record
    [
      ("section_name", option string section_name);
      ("files", list_of normalize_file files);
    ]
