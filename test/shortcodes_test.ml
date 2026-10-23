open Afj.Util

let%expect_test "button, with attributes on several lines" =
  print_endline
    (Shortcodes.expand
       "Adhérez :\n\n\
        [button\n\
       \    link=\"https://example.org/?a=1&b=2\"\n\
       \    color=\"success\"]\n\
        J'adhère !\n\
        [/button]\n");
  [%expect
    {|
    Adhérez :



    <div class="center"><a href="https://example.org/?a=1&amp;b=2" target="_blank"><button class="btn btn-lg inline-block btn-success">J'adhère !</button></a></div>
    |}]

let%expect_test "gallery of Markdown images, with parentheses in names" =
  print_endline
    (Shortcodes.expand
       "[gallery lastRow=\"justify\"]\n\
        ![2008 - Carvin](CFJ%2001%282008%29.jpg )\n\
        ![2015](CFJ%2007(2015).jpg \"title\")\n\
        [/gallery]");
  [%expect
    {| <div class="gallery"><a href="CFJ%2001%282008%29.jpg" class="glightbox" data-gallery="gallery-1" data-title="2008 - Carvin"><img src="thumbs/CFJ%2001%282008%29.jpg" alt="2008 - Carvin" loading="lazy"></a><a href="CFJ%2007(2015).jpg" class="glightbox" data-gallery="gallery-1" data-title="2015"><img src="thumbs/CFJ%2007(2015).jpg" alt="2015" loading="lazy"></a></div> |}]

let%expect_test "gallery of a sub-folder" =
  let list_dir = function
    | "affiches" -> [ "1991 Reze 6.jpg"; "2007 Porspoder.png" ]
    | _ -> []
  in
  print_endline
    (Shortcodes.expand ~list_dir "[gallery dir=\"affiches\"][/gallery]");
  [%expect
    {| <div class="gallery"><a href="affiches/1991%20Reze%206.jpg" class="glightbox" data-gallery="gallery-1" data-title="1991 Reze 6"><img src="affiches/thumbs/1991%20Reze%206.jpg" alt="1991 Reze 6" loading="lazy"></a><a href="affiches/2007%20Porspoder.png" class="glightbox" data-gallery="gallery-1" data-title="2007 Porspoder"><img src="affiches/thumbs/2007%20Porspoder.png" alt="2007 Porspoder" loading="lazy"></a></div> |}]

let%expect_test "links opening in a new tab" =
  print_endline
    (Shortcodes.target_blank
       {|<a href="https://www.facebook.com/asso.afj?target=_blank">AFJ</a> <a href="/liens/">Liens</a>|});
  [%expect
    {| <a href="https://www.facebook.com/asso.afj" target="_blank" rel="noopener">AFJ</a> <a href="/liens/">Liens</a> |}]
