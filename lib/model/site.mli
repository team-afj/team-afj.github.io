(** The tree of pages. As with Grav, every folder containing a [default.md] is a
    page, numeric prefixes ("02.lassociation") give the order and are removed
    from URLs, and the top-level "home" folder is the root of the site. Other
    folders hold files (e.g. gallery images). *)

type node = {
  dir : Yocaml.Path.t;
  folder : string;
  slugs : string list;  (** URL segments, [[]] for the home page. *)
  page : Page.t;
  has_gallery : bool;
  asset_dirs : (string * string list) list;
      (** Sub-folders that are not pages, with their (sorted) files. *)
  children : node list;
}

type t = node list

val page_file : string
(** The name of the file describing a page. *)

val scan : Yocaml.Path.t -> t Yocaml.Eff.t
(** Reads the tree of (published) pages rooted at the given directory. *)

val flatten : t -> (node * node list) list
(** Every page with its ancestors (closest first). *)

val source : node -> Yocaml.Path.t
val url : node -> string
val is_home : node -> bool

val book_root : node * node list -> node option
(** The root of the book (see {!Page.book}) a page belongs to, if any. *)

val files_of : node -> string -> string list
(** Files of the sub-folder [dir] of a page. *)

(** {1 YOCaml related stuff} *)

val normalize_nav : current:string list -> t -> Yocaml.Data.t
(** The main menu, with active entries for the page at [current]. *)

val normalize_book : current:string list -> node -> Yocaml.Data.t
(** The table of contents of a book: hidden pages included. *)
