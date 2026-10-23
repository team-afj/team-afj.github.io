(** Expansion of the Grav shortcodes used in the content, done on the Markdown
    source. Expansions are raw HTML blocks that CommonMark passes through
    untouched.

    - [[button link=".." color=".." target=".."]Label[/button]]
    - [[gallery] ![caption](image.jpg) ... [/gallery]]
    - [[gallery dir="sub-folder"][/gallery]]: every image of a sub-folder,
      listed by [list_dir]. *)

val expand : ?list_dir:(string -> string list) -> string -> string

val has_gallery : string -> bool
(** Does the Markdown source contain a gallery (whose images need thumbnails)?
*)

val thumbnail_url : string -> string
(** [thumbnail_url "dir/image.jpg"] is ["dir/thumbs/image.jpg"]. *)

val target_blank : string -> string
(** Grav opens links ending with [?target=_blank] in a new tab: rewrite them in
    the HTML output. *)
