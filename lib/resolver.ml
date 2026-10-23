module Path = Yocaml.Path

type t = { cache : Path.t; source : Path.t; target : Path.t }

let make ?(cache_folder = Path.rel [ "_cache" ]) ?(source_folder = Path.rel [])
    ?(target_folder = Path.rel [ "_www" ]) () =
  { cache = cache_folder; source = source_folder; target = target_folder }

let binary = Path.from_string Sys.argv.(0)

module Source = struct
  let source { source; _ } = source
  let configuration r = Path.(source r / "configuration.yml")
  let assets r = Path.(source r / "assets")
  let templates r = Path.(assets r / "templates")
  let template r p = Path.(templates r / p) |> Path.change_extension "html"
  let content r = Path.(source r / "content")
  let pages r = Path.(content r / "pages")
  let calendar r = Path.(source r / "data" / "conventions.ics")
end

module Target = struct
  let root { target; _ } = target
  let page_dir r slugs = Path.append (root r) slugs
  let page r slugs = Path.(page_dir r slugs / "index.html")

  let asset_dir r ~source =
    source
    |> Path.trim ~prefix:(Source.source r)
    |> Path.relocate ~into:(root r)
end

module Cache = struct
  let cache { cache; _ } = cache
  let global r = Path.(cache r / "yocaml")
  let today r = Path.(cache r / "today")
end
