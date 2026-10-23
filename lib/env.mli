(** An extension of the YOCaml interpreter providing the site configuration
    through an effect: the configuration file is read once, whatever the number
    of pages using it. *)

val get_configuration : unit -> Model.Configuration.t Yocaml.Eff.t
(** Retrieve the configuration. *)

val configuration : Resolver.t -> (unit, Model.Configuration.t) Yocaml.Task.t
(** A task that retrieves the configuration (and depends on its file). *)

val handle : Resolver.t -> (unit -> 'a Yocaml.Eff.t) -> unit -> 'a Yocaml.Eff.t
(** A handler for the configuration effect, to wrap the program with. *)
