val run :
  resolver:Resolver.t -> today:Model.Calendar.date -> unit -> unit Yocaml.Eff.t
(** The rules building the site. [today] is the date used to select the upcoming
    events of the agenda. *)
