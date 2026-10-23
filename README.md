# Site de l'Association Française de Jonglerie

Ceci est un portage automatisé du site Grav. L'avantage d'un site statique
hébergé sur Github pages c'est qu'on a pas besoin d'administration système.

Le site est construit avec yocaml, c'est beaucoup trop compliqué pour nos
besoins, mais c'est cool.

## Building

```sh
make deps            # install OCaml dependencies
make build           # generate the site into _www/
make preview         # build, then serve _www/ on http://localhost:8000
make serve           # serve with YOCaml, rebuilding on each request
make test
```

The generator itself is `dune exec bin/afj.exe -- build` (or `watch`); see
`--help` for its options.

Thumbnails are generated with ImageMagick (`magick` or `convert`), which must be installed.
