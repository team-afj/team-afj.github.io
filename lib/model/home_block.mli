(** A block of the home page ([NN-name.md] next to the home [default.md]),
    formerly a Grav modular sub-page. *)

type kind =
  | Hero  (** The banner. *)
  | Text
  | Button  (** A button linking to [media] or [link]. *)
  | Calendar  (** The agenda of the conventions. *)

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

(** {1 YOCaml related stuff} *)

val entity_name : string
val neutral : (t, Yocaml.Required.provider_error) result
val validate : Yocaml.Data.t -> t Yocaml.Data.Validation.validated_value

val normalize : t * string -> Yocaml.Data.t
(** [normalize (block, html)] where [html] is the rendered content. *)
