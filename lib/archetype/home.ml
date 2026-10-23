type t = {
  blocks : (Model.Home_block.t * string) list;
  calendar : Model.Calendar.year list;
}

let as_document ~configuration ~site ~node ~blocks ~calendar page =
  Html.Document.make ~configuration ~site ~node ~ancestors:[] ~page
    { blocks; calendar }

let normalize_content { blocks; calendar } =
  let open Yocaml.Data in
  let is_hero ((b : Model.Home_block.t), _) = b.kind = Hero in
  let hero, blocks = List.partition is_hero blocks in
  let in_column column =
    blocks
    |> List.filter (fun ((b : Model.Home_block.t), _) -> b.column = column)
    |> list_of Model.Home_block.normalize
  in
  ( "home",
    record
      [
        ("hero", option Model.Home_block.normalize (List.nth_opt hero 0));
        ("left", in_column Left);
        ("right", in_column Right);
        ("calendar", Model.Calendar.normalize calendar);
      ] )

module Html = struct
  type nonrec t = t Html.Document.t

  let normalize = Html.Document.normalize normalize_content
end
