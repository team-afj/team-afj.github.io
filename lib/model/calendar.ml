type date = Ptime.date

type event = {
  uid : string;
  start : date;
  stop : date;  (** Inclusive last day of the event. *)
  summary : string;
  description : string;
}

let date_of_string s =
  match Scanf.sscanf s "%4d-%2d-%2d%!" (fun y m d -> (y, m, d)) with
  | date when Option.is_some (Ptime.of_date date) -> Some date
  | _ | (exception _) -> None

let ptime_of = function
  | `Date d -> Ptime.of_date d
  | `Datetime (`Utc t | `Local t | `With_tzid (t, _)) -> Some t

(* Only the calendar day matters; date-times keep the day as written. *)
let day_of = function
  | `Date d -> d
  | `Datetime (`Utc t | `Local t | `With_tzid (t, _)) -> Ptime.to_date t

let previous_day d =
  Option.bind (Ptime.of_date d) (fun t ->
      Ptime.sub_span t (Ptime.Span.of_int_s 86400))
  |> Option.fold ~none:d ~some:Ptime.to_date

let event (e : Icalendar.event) =
  let start = day_of (snd e.dtstart) in
  (* The end is exclusive: all-day events end the day before DTEND. *)
  let stop =
    match e.dtend_or_duration with
    | Some (`Dtend (_, dtend)) -> Some (day_of dtend)
    | Some (`Duration (_, span)) ->
        Option.bind (ptime_of (snd e.dtstart)) (fun t -> Ptime.add_span t span)
        |> Option.map Ptime.to_date
    | None -> None
  in
  let stop =
    match stop with Some d when d > start -> previous_day d | _ -> start
  in
  let text f = Option.value ~default:"" (List.find_map f e.props) in
  {
    uid = snd e.uid;
    start;
    stop;
    summary = text (function `Summary (_, s) -> Some s | _ -> None);
    description = text (function `Description (_, s) -> Some s | _ -> None);
  }

let parse content =
  Icalendar.parse content
  |> Result.map (fun (_, components) ->
      (* A later definition of a UID replaces the former one. *)
      let events = Hashtbl.create 128 in
      let order =
        List.fold_left
          (fun order -> function
            | `Event e ->
                let e = event e in
                let known = Hashtbl.mem events e.uid in
                Hashtbl.replace events e.uid e;
                if known then order else e.uid :: order
            | _ -> order)
          [] components
      in
      List.rev_map (Hashtbl.find events) order)

let upcoming ~today events =
  events
  |> List.filter (fun e -> e.stop >= today)
  |> List.stable_sort (fun a b -> compare (a.start, a.stop) (b.start, b.stop))

let html_unescape_amp s = Str.global_replace (Str.regexp_string "&amp;") "&" s

(* The descriptions are HTML snippets; like the former plugin we link to the
   first URL found in an attribute. Google Calendar wraps links in a
   redirection, which we remove. *)
let first_link e =
  let re = Str.regexp "\"\\(https?[^\"]*\\)\"" in
  match Str.search_forward re e.description 0 with
  | exception Not_found -> None
  | _ -> (
      let url = html_unescape_amp (Str.matched_group 1 e.description) in
      let uri = Uri.of_string url in
      match (Uri.host uri, Uri.path uri) with
      | Some "www.google.com", "/url" ->
          Some (Option.value ~default:url (Uri.get_query_param uri "q"))
      | _ -> Some url)

let months =
  [|
    "janvier";
    "février";
    "mars";
    "avril";
    "mai";
    "juin";
    "juillet";
    "août";
    "septembre";
    "octobre";
    "novembre";
    "décembre";
  |]

let format_day (_, month, day) = Printf.sprintf "%d %s" day months.(month - 1)

type range = { first : date; last : date; range_events : event list }
type year = { year_number : int; ranges : range list }

(* Group consecutive (sorted) events by start year, then by identical date
   range. *)
let group events =
  let push_range r =
    let year, _, _ = r.first in
    function
    | y :: ys when y.year_number = year ->
        { y with ranges = r :: y.ranges } :: ys
    | ys -> { year_number = year; ranges = [ r ] } :: ys
  in
  let ranges =
    List.fold_left
      (fun acc e ->
        match acc with
        | r :: rs when r.first = e.start && r.last = e.stop ->
            { r with range_events = e :: r.range_events } :: rs
        | rs -> { first = e.start; last = e.stop; range_events = [ e ] } :: rs)
      [] events
    |> List.rev_map (fun r -> { r with range_events = List.rev r.range_events })
  in
  List.fold_left (fun acc r -> push_range r acc) [] ranges
  |> List.rev_map (fun y -> { y with ranges = List.rev y.ranges })

let normalize years =
  let open Yocaml.Data in
  list_of
    (fun y ->
      record
        [
          ("year", int y.year_number);
          ( "ranges",
            list_of
              (fun r ->
                record
                  [
                    ("start", string (format_day r.first));
                    ("end", string (format_day r.last));
                    ( "events",
                      list_of
                        (fun e ->
                          record
                            [
                              ("summary", string e.summary);
                              ("link", option string (first_link e));
                            ])
                        r.range_events );
                  ])
              y.ranges );
        ])
    years

let agenda ~today ics =
  match parse ics with
  | Ok events -> events |> upcoming ~today |> group
  | Error msg -> failwith ("Invalid calendar: " ^ msg)
