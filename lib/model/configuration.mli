(** The site configuration, read from [configuration.yml]. *)

type t = {
  title : string;
  url : string;  (** Public URL of the site, without trailing slash. *)
  description : string;  (** Default description of the pages. *)
  body_classes : string list;  (** Classes of the theme set on [<body>]. *)
}

(** {1 YOCaml related stuff} *)

val entity_name : string
val neutral : (t, Yocaml.Required.provider_error) result
val validate : Yocaml.Data.t -> t Yocaml.Data.Validation.validated_value
val normalize : t -> Yocaml.Data.t
