open Afj.Model

let ics =
  String.concat "\r\n"
    [
      "BEGIN:VCALENDAR";
      "BEGIN:VEVENT";
      "DTSTART;VALUE=DATE:20250716";
      "DTEND;VALUE=DATE:20250722";
      "UID:cfj@google.com";
      "DESCRIPTION:Infos<br><a \
       href=\"https://www.google.com/url?q=https%3A%2F%2F";
      " bigoudnjongle.wordpress.com%2F&amp\\;sa=D\" target=\"_blank\">site</a>";
      "SUMMARY:CFJ\\, Bigoud'N'Jongle";
      "END:VEVENT";
      "BEGIN:VEVENT";
      "DTSTART;VALUE=DATE:20250716";
      "DTEND;VALUE=DATE:20250722";
      "UID:other@google.com";
      "SUMMARY:Same dates";
      "END:VEVENT";
      "BEGIN:VEVENT";
      "DTSTART:20251231T190000Z";
      "DTEND:20260101T020000Z";
      "UID:new-year@google.com";
      "DESCRIPTION:<a href=\"http://example.org/?a=1&amp\\;b=2\">x</a>";
      "SUMMARY:New year";
      "END:VEVENT";
      "BEGIN:VEVENT";
      "DTSTART;VALUE=DATE:20250101";
      "DTEND;VALUE=DATE:20250103";
      "UID:past@google.com";
      "SUMMARY:Past";
      "END:VEVENT";
      "END:VCALENDAR";
    ]

let print years =
  List.iter
    (fun (y : Calendar.year) ->
      Printf.printf "%d\n" y.year_number;
      List.iter
        (fun (r : Calendar.range) ->
          Printf.printf "  %s -> %s\n"
            (Calendar.format_day r.first)
            (Calendar.format_day r.last);
          List.iter
            (fun (e : Calendar.event) ->
              Printf.printf "    %s (%s)\n" e.summary
                (Option.value ~default:"no link" (Calendar.first_link e)))
            r.range_events)
        y.ranges)
    years

let%expect_test "upcoming events grouped by year and date range" =
  print (Calendar.agenda ~today:(2025, 7, 21) ics);
  [%expect
    {|
    2025
      16 juillet -> 21 juillet
        CFJ, Bigoud'N'Jongle (https://bigoudnjongle.wordpress.com/)
        Same dates (no link)
      31 décembre -> 31 décembre
        New year (http://example.org/?a=1&b=2)
    |}]

let%expect_test "events ending before today are dropped" =
  print (Calendar.agenda ~today:(2025, 7, 22) ics);
  [%expect
    {|
    2025
      31 décembre -> 31 décembre
        New year (http://example.org/?a=1&b=2)
    |}]

let%expect_test "invalid calendars are rejected" =
  (match Calendar.parse "BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nEND:VCALENDAR" with
  | Ok _ -> print_endline "parsed"
  | Error _ -> print_endline "error");
  [%expect {| error |}]
