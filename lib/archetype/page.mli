(** A regular page: Markdown content with an optional sidebar (downloads and/or
    the table of contents of its book). *)

type t

val as_document :
  configuration:Model.Configuration.t ->
  site:Model.Site.t ->
  node:Model.Site.node ->
  ancestors:Model.Site.node list ->
  Model.Page.t ->
  t Html.Document.t

module Html : Yocaml.Required.DATA_INJECTABLE with type t = t Html.Document.t
