(** Frontmatter of a page ([default.md]). Field names follow Grav's, so that the
    content did not need to be rewritten. *)

type file = {
  name : string;
  file : string;  (** Name of a file of the page folder. *)
}
(** A downloadable file of the sidebar. *)

type section = { section_name : string option; files : file list }

type t = {
  title : string;
  description : string option;  (** [metadata.description] *)
  visible : bool option;
      (** In the main menu. Grav default: visible iff the folder is numbered. *)
  clickable : bool;  (** [false] for a menu entry without a page. *)
  book : bool;  (** The page and its sub-pages share a table of contents. *)
  published : bool;
  template : string option;  (** ["home"] for the home page. *)
  body_classes : string option;
  sidebar_files : section list;
}

(** {1 YOCaml related stuff} *)

val entity_name : string
val neutral : (t, Yocaml.Required.provider_error) result
val validate : Yocaml.Data.t -> t Yocaml.Data.Validation.validated_value
val normalize_section : section -> Yocaml.Data.t
