(** The home page: blocks laid out in two columns under a banner, one of them
    showing the agenda of the conventions. *)

type t

val as_document :
  configuration:Model.Configuration.t ->
  site:Model.Site.t ->
  node:Model.Site.node ->
  blocks:(Model.Home_block.t * string) list ->
  calendar:Model.Calendar.year list ->
  Model.Page.t ->
  t Html.Document.t

module Html : Yocaml.Required.DATA_INJECTABLE with type t = t Html.Document.t
