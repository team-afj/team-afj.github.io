open Yocaml

type node = {
  dir : Path.t;
  folder : string;
  slugs : string list;
  page : Page.t;
  has_gallery : bool;
  asset_dirs : (string * string list) list;
  children : node list;
}

type t = node list

let page_file = "default.md"
let numbered_prefix = Str.regexp "^[0-9]+\\."
let is_numbered folder = Str.string_match numbered_prefix folder 0
let slug folder = Str.replace_first numbered_prefix "" folder
let source node = Path.(node.dir / page_file)
let is_home node = node.slugs = []
let basename path = Option.value ~default:"" (Path.basename path)

let is_visible node =
  Option.value node.page.visible ~default:(is_numbered node.folder)

let url node =
  match node.slugs with [] -> "/" | s -> "/" ^ String.concat "/" s ^ "/"

let children ~only dir =
  let open Eff in
  let+ children = read_directory ~on:`Source ~only dir in
  Stdlib.List.sort Path.compare children

let is_page dir = Eff.file_exists ~on:`Source Path.(dir / page_file)

let rec scan_dir ~parent dir =
  let open Eff in
  let* subdirs = children ~only:`Directories dir in
  let+ nodes =
    List.traverse
      (fun sub ->
        let* is_page = is_page sub in
        if is_page then Option.some <$> node ~parent sub else return None)
      subdirs
  in
  Stdlib.List.filter_map
    (function Some n when n.page.published -> Some n | _ -> None)
    nodes

and node ~parent dir =
  let open Eff in
  let folder = basename dir in
  let slugs =
    match (parent, slug folder) with [], "home" -> [] | _, s -> parent @ [ s ]
  in
  let* page, content =
    Yocaml_yaml.Eff.read_file_with_metadata
      (module Page)
      ~on:`Source
      Path.(dir / page_file)
  in
  let* children = scan_dir ~parent:slugs dir in
  let+ asset_dirs = asset_dirs dir in
  {
    dir;
    folder;
    slugs;
    page;
    has_gallery = Util.Shortcodes.has_gallery content;
    asset_dirs;
    children;
  }

and asset_dirs dir =
  let open Eff in
  let* subdirs = children ~only:`Directories dir in
  Stdlib.List.filter_map Fun.id
  <$> List.traverse
        (fun sub ->
          let* is_page = is_page sub in
          if is_page then return None
          else
            let+ files = children ~only:`Files sub in
            Some (basename sub, Stdlib.List.map basename files))
        subdirs

let scan = scan_dir ~parent:[]

let rec flatten_with ~ancestors nodes =
  List.concat_map
    (fun n ->
      (n, ancestors) :: flatten_with ~ancestors:(n :: ancestors) n.children)
    nodes

let flatten = flatten_with ~ancestors:[]

let book_root (node, ancestors) =
  List.find_opt (fun n -> n.page.book) (node :: ancestors)

let files_of node dir =
  List.assoc_opt dir node.asset_dirs |> Option.value ~default:[]

let rec is_prefix prefix l =
  match (prefix, l) with
  | [], _ -> true
  | x :: xs, y :: ys -> String.equal x y && is_prefix xs ys
  | _ -> false

let is_active ~current node =
  match node.slugs with [] -> current = [] | s -> is_prefix s current

(* [all] also includes hidden pages, as the book menu does. *)
let rec normalize_entry ~current ~all node =
  let open Data in
  record
    [
      ("title", string node.page.title);
      ("url", string (url node));
      ("clickable", bool node.page.clickable);
      ("active", bool (is_active ~current node));
      ( "children",
        list_of
          (normalize_entry ~current ~all)
          (List.filter (fun c -> all || is_visible c) node.children) );
    ]

let normalize_nav ~current tree =
  Data.list_of
    (normalize_entry ~current ~all:false)
    (List.filter is_visible tree)

let normalize_book ~current root = normalize_entry ~current ~all:true root
