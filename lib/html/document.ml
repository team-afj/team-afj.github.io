type 'a t = {
  configuration : Model.Configuration.t;
  site : Model.Site.t;
  node : Model.Site.node;
  book : Model.Site.node option;
  page : Model.Page.t;
  content : 'a;
}

let make ~configuration ~site ~node ~ancestors ~page content =
  let book = Model.Site.book_root (node, ancestors) in
  { configuration; site; node; book; page; content }

let normalize on_content { configuration; site; node; book; page; content } =
  let open Yocaml.Data in
  let current = node.slugs in
  let url = Model.Site.url node in
  let description =
    Option.value page.description ~default:configuration.description
  in
  let body_classes =
    configuration.body_classes @ Option.to_list page.body_classes
  in
  (* Pages of a book show the title of the book in their banner. *)
  let hero_title =
    Option.fold book ~none:page.title ~some:(fun b -> b.Model.Site.page.title)
  in
  [
    ( "document",
      record
        [
          ("title", string page.title);
          ("full_title", string (page.title ^ " | " ^ configuration.title));
          ("description", string description);
          ("url", string url);
          ("canonical", string (configuration.url ^ url));
          ("body_classes", string (String.concat " " body_classes));
          ("hero_title", string hero_title);
          ("nav", Model.Site.normalize_nav ~current site);
          ("book", option (Model.Site.normalize_book ~current) book);
        ] );
    on_content content;
    ("configuration", Model.Configuration.normalize configuration);
  ]
