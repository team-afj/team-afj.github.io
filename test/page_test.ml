open Afj.Model
open Test_util

let summary (p : Page.t) =
  let open Yocaml.Data in
  record
    [
      ("title", string p.title);
      ("description", option string p.description);
      ("visible", option bool p.visible);
      ("clickable", bool p.clickable);
      ("book", bool p.book);
      ("published", bool p.published);
      ("sidebar_files", list_of Page.normalize_section p.sidebar_files);
    ]

let%expect_test "Grav defaults" =
  let open Yocaml.Data in
  validation
    (let+ page = Page.validate (record [ ("title", string "Liens") ]) in
     summary page);
  [%expect
    {|
    [VALID] {"title": "Liens", "description": null, "visible": null, "clickable":
             true, "book": false, "published": true, "sidebar_files": []}
    |}]

let%expect_test "metadata and downloads" =
  let open Yocaml.Data in
  let input =
    record
      [
        ("title", string "L'Association");
        ("clickable", bool false);
        ("metadata", record [ ("description", string "Qui sommes-nous ?") ]);
        ( "sidebar_files",
          list
            [
              record
                [
                  ("section_name", string "Immatriculation");
                  ( "files",
                    list
                      [
                        record
                          [
                            ("name", string "Statuts");
                            ("file", string "Statuts AFJ 2019.pdf");
                          ];
                      ] );
                ];
              record [ ("files", list []) ];
            ] );
      ]
  in
  validation
    (let+ page = Page.validate input in
     summary page);
  [%expect
    {|
    [VALID] {"title": "L'Association", "description": "Qui sommes-nous ?",
            "visible": null, "clickable": false, "book": false, "published":
             true, "sidebar_files":
             [{"section_name": "Immatriculation", "files":
               [{"name": "Statuts", "url": "Statuts%20AFJ%202019.pdf", "icon":
                 "la-file-pdf"}]},
             {"section_name": null, "files": []}]}
    |}]

let%expect_test "home blocks: kinds and columns are checked" =
  let open Yocaml.Data in
  let block fields =
    validation
      (let+ b = Home_block.validate (record fields) in
       Home_block.normalize (b, "<p>x</p>"))
  in
  block
    [
      ("title", string "Agenda");
      ("kind", string "calendar");
      ("column", string "right");
    ];
  block [ ("kind", string "carousel") ];
  [%expect
    {|
    [VALID] {"kind": "calendar", "title": "Agenda", "content": "<p>x</p>",
            "image": null, "hero_image": null, "hero_visual": null,
            "hero_classes": null, "link": null, "target": "_blank", "color":
             "primary"}
    [INVALID] --- Oh dear, an error has occurred ---
    Validation error:
    Entity: `test`


    Invalid record:
      Errors (1):
      1) Invalid field `kind`:
           Message:
             Message: hero, text, button or calendar
             Given: `carousel`

      Given record:
        kind = `"carousel"`---
    The backtrace is not available because the function is called (according to the [in_exception_handler] parameter) outside an exception handler. This makes the trace unspecified.
    |}]
