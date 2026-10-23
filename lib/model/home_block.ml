type kind = Hero | Text | Button | Calendar
type column = Left | Right

type t = {
  kind : kind;
  title : string;
  column : column;
  image : string option;
  hero_image : string option;
  hero_visual : string option;
  hero_classes : string option;
  link : string option;
  target : string option;
  color : string option;
}

let entity_name = "Home block"
let neutral = Yocaml.Metadata.required entity_name

let validate_kind =
  let open Yocaml.Data.Validation in
  string & function
  | "hero" -> Ok Hero
  | "text" -> Ok Text
  | "button" -> Ok Button
  | "calendar" -> Ok Calendar
  | given -> fail_with ~given "hero, text, button or calendar"

let validate_column =
  let open Yocaml.Data.Validation in
  string & function
  | "left" -> Ok Left
  | "right" -> Ok Right
  | given -> fail_with ~given "left or right"

let validate =
  let open Yocaml.Data.Validation in
  record (fun fields ->
      let+ kind = optional_or fields "kind" ~default:Text validate_kind
      and+ title = optional_or fields "title" ~default:"" string
      and+ column = optional_or fields "column" ~default:Left validate_column
      and+ image = optional fields "image" string
      and+ hero_image = optional fields "hero_image" string
      and+ hero_visual = optional fields "hero_visual" string
      and+ hero_classes = optional fields "hero_classes" string
      and+ media = optional fields "media" string
      and+ link = optional fields "link" string
      and+ target = optional fields "target" string
      and+ color = optional fields "color" string in
      {
        kind;
        title;
        column;
        image;
        hero_image;
        hero_visual;
        hero_classes;
        (* A button points either to a file of the page (media) or to a link. *)
        link = (if Option.is_some media then media else link);
        target;
        color;
      })

let normalize
    ( {
        kind;
        title;
        column = _;
        image;
        hero_image;
        hero_visual;
        hero_classes;
        link;
        target;
        color;
      },
      content ) =
  let open Yocaml.Data in
  let url = option (fun s -> string (Util.Url.encode s)) in
  let kind =
    match kind with
    | Hero -> "hero"
    | Text -> "text"
    | Button -> "button"
    | Calendar -> "calendar"
  in
  record
    [
      ("kind", string kind);
      ("title", string title);
      ("content", string content);
      ("image", url image);
      ("hero_image", url hero_image);
      ("hero_visual", url hero_visual);
      ("hero_classes", option string hero_classes);
      ("link", option string link);
      ("target", string (Option.value target ~default:"_blank"));
      ("color", string (Option.value color ~default:"primary"));
    ]
