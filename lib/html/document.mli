(** Data shared by every page of the site: title, description, URLs, navigation…
    wrapping data specific to a kind of page (['a]). *)

type 'a t

val make :
  configuration:Model.Configuration.t ->
  site:Model.Site.t ->
  node:Model.Site.node ->
  ancestors:Model.Site.node list ->
  page:Model.Page.t ->
  'a ->
  'a t

val normalize :
  ('a -> string * Yocaml.Data.t) -> 'a t -> (string * Yocaml.Data.t) list
(** [normalize on_content document] exposes [document], [configuration] and the
    variables produced by [on_content] to the templates. *)
