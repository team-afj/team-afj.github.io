(* Expansion of the Grav shortcodes used in the content, done on the Markdown
   source before the Markdown → HTML conversion. Expansions are emitted as raw
   HTML blocks (surrounded by blank lines, without blank lines inside) so that
   CommonMark passes them through untouched.

   - [button link=".." color=".." target=".."]Label[/button]
   - [gallery] ![caption](image.jpg) ... [/gallery]
   - [gallery dir="sub-folder"][/gallery] lists every image of a sub-folder *)

let attributes s =
  let re = Str.regexp "\\([a-zA-Z_]+\\)=\"\\([^\"]*\\)\"" in
  let rec go pos acc =
    match Str.search_forward re s pos with
    | exception Not_found -> List.rev acc
    | _ ->
        let kv = (Str.matched_group 1 s, Str.matched_group 2 s) in
        go (Str.match_end ()) (kv :: acc)
  in
  go 0 []

let find s sub from =
  try Some (Str.search_forward (Str.regexp_string sub) s from)
  with Not_found -> None

(* Replace every [name attrs]inner[/name] of [text] with [f attrs inner]. *)
let replace name f text =
  let opening = "[" ^ name and closing = "[/" ^ name ^ "]" in
  let b = Buffer.create (String.length text) in
  let rec go pos =
    let tag =
      Option.bind (find text opening pos) (fun start ->
          let after = start + String.length opening in
          if
            after < String.length text
            && List.mem text.[after] [ ' '; '\t'; '\n'; '\r'; ']' ]
          then
            Option.bind (find text "]" after) (fun attrs_end ->
                Option.map
                  (fun close -> (start, after, attrs_end, close))
                  (find text closing attrs_end))
          else None)
    in
    match tag with
    | None ->
        Buffer.add_string b (String.sub text pos (String.length text - pos))
    | Some (start, after, attrs_end, close) ->
        Buffer.add_string b (String.sub text pos (start - pos));
        let attrs = attributes (String.sub text after (attrs_end - after)) in
        let inner = String.sub text (attrs_end + 1) (close - attrs_end - 1) in
        Buffer.add_string b ("\n\n" ^ f attrs (String.trim inner) ^ "\n\n");
        go (close + String.length closing)
  in
  go 0;
  Buffer.contents b

(* Same markup as the former afj-theme-support plugin's ui-button partial. *)
let button attrs label =
  let get k default = Option.value ~default (List.assoc_opt k attrs) in
  Printf.sprintf
    "<div class=\"center\"><a href=\"%s\" target=\"%s\"><button class=\"btn \
     btn-lg inline-block btn-%s\">%s</button></a></div>"
    (Url.html_escape (get "link" "#"))
    (Url.html_escape (get "target" "_blank"))
    (Url.html_escape (get "color" "primary"))
    label

(* Images are given as Markdown image syntax. Destinations may contain
   balanced parentheses, e.g. ![x](CFJ%2007(2015).jpg). *)
let images inner =
  let n = String.length inner in
  let rec destination i depth =
    if i >= n then i
    else
      match inner.[i] with
      | '(' -> destination (i + 1) (depth + 1)
      | ')' when depth = 0 -> i
      | ')' -> destination (i + 1) (depth - 1)
      | _ -> destination (i + 1) depth
  in
  let rec go pos acc =
    match find inner "![" pos with
    | None -> List.rev acc
    | Some start -> (
        match find inner "](" start with
        | None -> List.rev acc
        | Some mid ->
            let caption = String.sub inner (start + 2) (mid - start - 2) in
            let stop = destination (mid + 2) 0 in
            let dest =
              String.trim (String.sub inner (mid + 2) (stop - mid - 2))
            in
            (* Drop an optional title: dest "title" *)
            let url =
              match String.index_opt dest ' ' with
              | Some i -> String.sub dest 0 i
              | None -> dest
            in
            go (stop + 1) ((caption, url) :: acc))
  in
  go 0 []

let thumbnail_url url =
  match String.rindex_opt url '/' with
  | Some i ->
      String.sub url 0 (i + 1)
      ^ "thumbs/"
      ^ String.sub url (i + 1) (String.length url - i - 1)
  | None -> "thumbs/" ^ url

let gallery_counter = ref 0

let gallery ~list_dir attrs inner =
  incr gallery_counter;
  let id = Printf.sprintf "gallery-%d" !gallery_counter in
  let images =
    match List.assoc_opt "dir" attrs with
    | Some dir ->
        list_dir dir
        |> List.map (fun file ->
            (Filename.remove_extension file, Url.encode (dir ^ "/" ^ file)))
    | None -> images inner
  in
  let item (caption, url) =
    let caption = Url.html_escape caption in
    Printf.sprintf
      "<a href=\"%s\" class=\"glightbox\" data-gallery=\"%s\" \
       data-title=\"%s\"><img src=\"%s\" alt=\"%s\" loading=\"lazy\"></a>"
      url id caption (thumbnail_url url) caption
  in
  "<div class=\"gallery\">" ^ String.concat "" (List.map item images) ^ "</div>"

let has_gallery markdown = Option.is_some (find markdown "[gallery" 0)

let expand ?(list_dir = fun _ -> []) markdown =
  gallery_counter := 0;
  markdown |> replace "button" button |> replace "gallery" (gallery ~list_dir)

(* Grav opens links ending with "?target=_blank" in a new tab. *)
let target_blank html =
  Str.global_replace
    (Str.regexp "href=\"\\([^\"]*\\)[?]target=_blank\"")
    "href=\"\\1\" target=\"_blank\" rel=\"noopener\"" html
