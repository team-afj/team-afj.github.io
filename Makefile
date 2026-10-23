CALENDAR_URL = https://calendar.google.com/calendar/ical/sj0qsvir6vssrevv062l3oah8k%40group.calendar.google.com/public/basic.ics
CALENDAR = data/conventions.ics
PORT ?= 8000
# Build the site as of another date, e.g. `make build TODAY=2026-09-01`.
TODAY ?=
TODAY_ARG = $(if $(TODAY),--today $(TODAY))

.PHONY: all deps build serve preview test fetch-calendar clean

all: build

deps:
	opam install . --deps-only --with-test --yes

# Keep the previous snapshot if the download fails.
fetch-calendar:
	curl -fsSL "$(CALENDAR_URL)" -o $(CALENDAR).tmp && mv $(CALENDAR).tmp $(CALENDAR) \
	  || (rm -f $(CALENDAR).tmp; echo "Could not fetch the calendar, keeping $(CALENDAR)")

build: fetch-calendar
	dune exec bin/afj.exe -- build $(TODAY_ARG)

# Rebuilds on each request. Note: the YOCaml server does not decode %20 in
# URLs, so files with spaces in their names (posters, PDFs) show as missing;
# use `make preview` to check those.
serve
	dune exec bin/afj.exe -- watch --port $(PORT) $(TODAY_ARG)

preview: build
	python3 -m http.server $(PORT) -d _www --bind 127.0.0.1

test:
	dune test
clean:
	dune clean
	rm -rf _www _cache
