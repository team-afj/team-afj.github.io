(** The agenda of the conventions, read from their public Google Calendar with
    the [icalendar] library. It reproduces the former Grav "event-list" plugin:
    keep upcoming events, sort them, and group them by year and by date range.
*)

type date = Ptime.date
(** [(year, month, day)]. *)

type event = {
  uid : string;
  start : date;
  stop : date;  (** Inclusive last day of the event. *)
  summary : string;
  description : string;
}

type range = { first : date; last : date; range_events : event list }
type year = { year_number : int; ranges : range list }

val date_of_string : string -> date option
(** Parses a valid [YYYY-MM-DD] date. *)

val parse : string -> (event list, string) result
(** Events of an ICS file. *)

val agenda : today:date -> string -> year list
(** [agenda ~today ics] is [parse ics |> upcoming ~today |> group].

    @raise Failure if [ics] is not a valid iCalendar file. *)

val first_link : event -> string option
(** The first URL of the event description, without Google's redirection. *)

val format_day : date -> string
(** French formatting: ["16 juillet"]. *)

val normalize : year list -> Yocaml.Data.t
