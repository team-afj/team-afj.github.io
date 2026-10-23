(lang dune 3.18)

(name afj)

(generate_opam_files true)

(license MIT)

(authors "Team AFJ <afj.jonglerie@gmail.com>")

(maintainers "Team AFJ <afj.jonglerie@gmail.com>")

(package
 (name afj)
 (synopsis "Static website of the Association Française de Jonglerie")
 (allow_empty)
 (depends
  (ocaml
   (>= 5.3.0))
  (yocaml
   (>= 3.0.1))
  yocaml_unix
  yocaml_yaml
  yocaml_markdown
  yocaml_jingoo
  cmdliner
  icalendar
  ptime
  uri
  (ppx_expect :with-test)))
