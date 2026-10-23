(** Small helpers for URLs and HTML attributes. *)

val encode : string -> string
(** Percent-encode a (relative) URL path, keeping [/]. File names of the content
    contain spaces and parentheses. *)

val html_escape : string -> string
(** Escape a string for HTML text and attribute values. *)
