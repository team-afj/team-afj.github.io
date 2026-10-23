type t = { sidebar_files : Model.Page.section list; has_sidebar : bool }

let as_document ~configuration ~site ~node ~ancestors (page : Model.Page.t) =
  let in_book = Option.is_some (Model.Site.book_root (node, ancestors)) in
  Html.Document.make ~configuration ~site ~node ~ancestors ~page
    {
      sidebar_files = page.sidebar_files;
      has_sidebar = in_book || page.sidebar_files <> [];
    }

let normalize_content { sidebar_files; has_sidebar } =
  let open Yocaml.Data in
  ( "page",
    record
      [
        ("sidebar_files", list_of Model.Page.normalize_section sidebar_files);
        ("has_sidebar", bool has_sidebar);
      ] )

module Html = struct
  type nonrec t = t Html.Document.t

  let normalize = Html.Document.normalize normalize_content
end
