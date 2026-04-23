; regenerate with:
;   1. opam install UnifiedScript_Top
;   2. erase the contents of this file except these comments at the top
;   3. opam exec -- dune ocaml top lib/re | opam exec -- UDuneImport.exe --package re -o dune-examples.inc --disable-ocamlformat .

(rule
  (enabled_if (= %{profile} "dev"))
  (target EXAMPLES.md-actual.ml.u)
  (deps (:expected EXAMPLES.md.ml.u))
  (action
     (run %{bin:UCramRunner} %{expected} -o %{target}
          --workspace %{workspace_root} --load-with-dune %{cma:lib/re})))

(rule
  (package re)
  (alias test-unified)
  (enabled_if (= %{profile} "dev"))
  (action (diff EXAMPLES.md.ml.u EXAMPLES.md-actual.ml.u)))

(alias (name runtest) (deps (alias test-unified)))