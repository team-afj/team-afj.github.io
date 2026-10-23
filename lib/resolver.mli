(** The Resolver locates sources, targets and cache files. It is created when
    the generator starts and passed to every rule. *)

(** {1 Types} *)

type t

val make :
  ?cache_folder:Yocaml.Path.t ->
  ?source_folder:Yocaml.Path.t ->
  ?target_folder:Yocaml.Path.t ->
  unit ->
  t
(** Initialise a resolver.
    - [cache_folder]: where the cache is stored, by default [./_cache]
    - [source_folder]: where sources are stored, by default [./]
    - [target_folder]: where the site is generated, by default [./_www] *)

val binary : Yocaml.Path.t
(** The generator itself, every output depends on it. *)

(** {1 Source} *)

module Source : sig
  val configuration : t -> Yocaml.Path.t
  val assets : t -> Yocaml.Path.t
  val templates : t -> Yocaml.Path.t
  val template : t -> string -> Yocaml.Path.t

  val pages : t -> Yocaml.Path.t
  (** The tree of pages, Grav style. *)

  val calendar : t -> Yocaml.Path.t
  (** The ICS snapshot of the conventions calendar. *)
end

(** {1 Target} *)

module Target : sig
  val root : t -> Yocaml.Path.t

  val page_dir : t -> string list -> Yocaml.Path.t
  (** [page_dir r slugs] is the directory of the page served at [/slugs/]. *)

  val page : t -> string list -> Yocaml.Path.t

  val asset_dir : t -> source:Yocaml.Path.t -> Yocaml.Path.t
  (** [asset_dir r ~source] is where the files of the asset directory [source]
      are copied. *)
end

(** {1 Cache} *)

module Cache : sig
  val global : t -> Yocaml.Path.t
  (** The YOCaml build cache. *)

  val today : t -> Yocaml.Path.t
  (** A file holding the build date, rewritten when the date changes so that
      date-dependent pages (the calendar) are rebuilt. *)
end
