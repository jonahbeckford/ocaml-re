---
name: make-literate-tests
description: Translates OCaml expect tests into unified scripts that can be incrementally adopted, tested and rendered into readable documentation.
---

# Make Literate Tests Skill

This skill guides you through converting OCaml `ppx_expect` tests into **unified scripts** that can be rendered into documentation. Unified scripts are a family of file formats that combines a) an existing documentation format like Markdown, Typst or Markdoc, and b) executable commands and their responses.

When a unified script is run, an update to the unified script is generated where the executable commands have been executed and new responses captured. To test, the updated script is diffed against the original ("expected") script.

For the full unified script reference, see https://github.com/diskuv/dk/blob/V2_5/docs/UNIFIED_SCRIPTS.md.

## What are `.md.ml.u` Unified Scripts?

A `.md.ml.u` unified script combines a) a Markdown document with b) OCaml REPL commands and their responses. `.md.ml.u` scripts are run with `UCramRunner`.

> [!IMPORTANT]
> Only output written to `Format.std_formatter` (ex. `Format.printf`) is captured as the response to the command. Direct `stdout` (ex. `print_endline`, `Printf.printf`) will be in the terminal but not captured.

## Incremental Adoption

This skill creates a `EXAMPLES.md.ml.u` script in the project root that coexists with and duplicates the existing expect tests.

Expect tests are `.ml` files containing  `let%expect_test` expressions.
No changes are made to the expect tests.

Both unified tests and expect tests run with `dune runtest`.

**Outputs:**
- `EXAMPLES.md.ml.u` — runnable, readable test script
- `EXAMPLES.md` — generated, rendered Markdown documentation

---

## Step 1: Install the Unified Script Tools

Two tools are required; install them with `opam pin add`:

```bash
# Check for a project-local opam wrapper (use it if present, else fall back)
OPAM_BIN="opam"
[ -x build/d/opam ] && OPAM_BIN="build/d/opam"
[ -x build/d/opam.sh ]  && OPAM_BIN="build/d/opam.sh"

MLFRONT=https://gitlab.com/dkml/build-tools/MlFront/-/releases/permalink/latest/downloads/MlFront.tar.gz
$OPAM_BIN pin add UnifiedScript_Std "$MLFRONT"
$OPAM_BIN pin add UnifiedScript_Top "$MLFRONT"
```

On Windows use PowerShell:
```powershell
$OPAM_BIN = if     (Test-Path "build\d\opam.exe") { "build\d\opam.exe" }
            elseif (Test-Path "build\d\opam.cmd") { "build\d\opam.cmd" }
            else   { "opam" }
$MLFRONT = "https://gitlab.com/dkml/build-tools/MlFront/-/releases/permalink/latest/downloads/MlFront.tar.gz"
& $OPAM_BIN pin add UnifiedScript_Std $MLFRONT
& $OPAM_BIN pin add UnifiedScript_Top $MLFRONT
```

These install:
- `UCramRunner` — Executes `.ml.u` scripts and captures REPL output
- `U2Markdown` — Renders a `.ml.u` script into idiomatic Markdown

Update them with (no `&` on Unix):

```
& $OPAM_BIN update UnifiedScript_Std UnifiedScript_Top
& $OPAM_BIN upgrade UnifiedScript_Std UnifiedScript_Top
```

---

## Step 2: Create EXAMPLES.md.ml.u

### File Structure and Syntax Rules

Every line in a `.md.ml.u` file is either:

- a line of a **markin region** line, which is part of a command or response block:
  - a line starting with two spaces, a `#` and a space (introduces a command that can span multiple lines, and ends when a line ends with `;;`)
  - a line starting with two spaces, `>>>` and a space (introduces the first line of a multi-line command; subsequent lines start with two spaces, `...` and a space)
  - a line starting with two spaces and no prompt (a response line)
- any other line is part of the **main document** Markdown document (plain prose, headings, etc.)

**Formatting cheat sheet:**

```
  >>> multi-line-expression      ← command (>>> form)
  ... continuation-line          ← continuation
response text                    ← this is WRONG – needs two-space indent
  response text                  ← CORRECT response line

  # multi-line-expression
can be continued
until command ends;;             ← command (# form, ends with ;;)
  response text                  ← response line
```

> [!IMPORTANT]
> Prefer `>>>` over the `#` form since whitespace and a `#` duals as a Markdown Level 1 ATX heading.

### Mapping from Expect Tests

OCaml expect tests have this structure:

```ocaml
let%expect_test "label" =
  some_function arg1 arg2;
  [%expect {| expected output |}];
  another_function arg;
  [%expect {| other output |}]
;;
```

Each `function_call ; [%expect {| ... |}]` pair maps to one test (a description sentence + command + expected output) in the unified script:

```
## label

A single, small sentence describing the test.
  >>> some_function arg1 arg2
  expected output

A single, small sentence describing the test or how it differs from the last test.
  >>> another_function arg
  other output
```

### Inline Helper Definition

Helper functions that wrap a test should be defined inline in the unified script, not imported from external modules. Helper functions should output Markdown code blocks for rectangular data.

For example, the expect tests may test the `Re.exec_opt` regular expression function:

```ocaml
module Re : sig
  type t
  type re
  module Group : sig
    val all_offset : t -> (int * int) array
  end
  val exec_opt
    :  ?pos:int (** Default: 0 *)
    -> ?len:int (** Default: -1 (until end of string) *)
    -> re
    -> string
    -> Group.t option
end
```

Here is a minimal helper inlined into a unified script that prints the offsets of all matched groups in a Markdown code block, with a metadata preamble saying what follows is Markdown:

```
## Helpers

  >>> let test_re_exec_opt ?pos ?len re s =
  ...   Format.printf "%s" {|\markdown\;|};
  ...   match Re.exec_opt ?pos ?len (Re.compile re) s with
  ...   | None -> Format.printf "%s@." "*not found*"
  ...   | Some g ->
  ...     Format.printf "| Group | Offset |@."
  ...     Format.printf "| --- | --- |@."
  ...     let offsets = Re.Group.all_offset g in
  ...     Array.to_list offsets
  ...     |> List.iter (fun (a, b) -> Format.printf "| %d | %d |@." a b)
  val test_re_exec_opt : ?pos:int -> ?len:int -> Re.t -> string -> unit = <fun>
```

**Note**: The `val ... = <fun>` unified script lines come from the OCaml REPL printing the type of each defined function. They must be included in `EXAMPLES.md.ml.u` as expected output. Run `UCramRunner` once to discover the exact text (see Step 3).
  
### Content That Transfers Directly

Only tests whose output helpers use `Format.printf` (or write to `Format.std_formatter`) can be converted without changes:
- ✅ Helpers like `test_re_exec_opt` that call `Format.printf`
- ❌ Helpers that call `Printf.printf` or `print_endline` directly

For tests using `Printf.printf`, either skip them or wrap the call:
```ocaml
let my_test arg = Format.printf "%s@." (compute_result arg)
```

---

## Step 3: Run UCramRunner to Fill in Responses

On the first run, create `EXAMPLES.md.ml.u` without response text.
`UCramRunner` fills in the actual REPL output.

### Build the project first

```bash
opam exec -- dune build
```

### Autoconfigure UCramRunner

Create `dune-examples.inc` by running:

1. Run `opam exec -- dune ocaml top <srcdir> | opam exec -- UDuneImport --disable-ocamlformat [options] .`:
   - *REQUIRED*: The `<srcdir>` is the directory tree containing the `*.ml` modules to be tested.
   - *RECOMMENDED*: There are two important options:
     - `--package PACKAGE` is the name of the Dune `(package)` the `.ml.u` scripts will belong to. Pick using the main `(package (name ...))` stanza declared in the `dune-project` file.
     - `--require-project-library PACKAGE1 --require-project-library PACKAGE2 ...` are the names of public or private libraries in the project that the `.ml.u` scripts depend on (even transitively). These are identified from `dune` files in the project that contain `(library (name ...))` stanzas.
   - A full example is: `opam exec -- dune ocaml top src/MlFront_Cache/MlFront_Cache | opam exec -- UDuneImport.exe --package MlFront_Cache -o src/MlFront_Cache/dune-examples.inc --require-project-library MlFront_Core --disable-ocamlformat .`
2. Create an empty `dune` file in the project root if it doesn't exist.
3. Include the generated rules and render them in the project `dune` file:

   ```scheme
   (include dune-examples.inc)

   (rule
    (target EXAMPLES.actual.md)
    (package <package-name>)
    (deps EXAMPLES.md.ml.u)
    (action
     (run %{bin:U2Markdown} --toc -o %{target} %{deps})))
   (rule
    (alias runtest)
    (package <package-name>)
    (action
    (diff EXAMPLES.md EXAMPLES.actual.md)))
   ```

**Rule summary:**

| File | Rule | Effect |
|------|------|--------|
| generated `dune-examples.inc` | Target `EXAMPLES.md.ml.u` | Runs `UCramRunner` on `EXAMPLES.md.ml.u`, writes real REPL output to `.actual` |
| generated `dune-examples.inc` | `runtest` alias | Diffs expected vs actual; fails if output changed |
| manually added to `dune` | Third rule | Renders `.ml.u` to `EXAMPLES.md` via `U2Markdown` |

### Review and promote

Rerun the tests; Dune will print diffs for each test.

```bash
opam exec -- dune build
```

Compare the diff to see if the new response lines match your original `[%expect]` blocks.

Once satisfied, promote the actual output as the new expected baseline:

```bash
opam exec -- dune promote
```

### Coexistence with existing tests

Both PPX expect tests and unified script tests share the `runtest` alias.
To run only the unified script tests (without needing ppx_expect installed):

```bash
opam exec -- dune build EXAMPLES.md.ml.u  # generation
```

---

## Step 5: Continuous Integration

```yaml
# Example: GitHub Actions
- name: Build and validate unified examples
  run: |
    dune build EXAMPLES.md.ml.u

- name: Render documentation
  run: dune build EXAMPLES.md
```

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `EXAMPLES.md.ml.u` | Source unified script (committed) |
| `EXAMPLES.md` | Rendered Markdown (committed or generated) |
| `dune` (root) | Location for the three new rules |

---

## Troubleshooting

### `UCramRunner` not found
```bash
opam pin add UnifiedScript_Std https://gitlab.com/dkml/build-tools/MlFront/-/releases/permalink/latest/downloads/MlFront.tar.gz
opam pin add UnifiedScript_Top https://gitlab.com/dkml/build-tools/MlFront/-/releases/permalink/latest/downloads/MlFront.tar.gz
```

### `[cram test failed]` on first run
The `.md.ml.u` file has expected output that does not match. Either the code changed or the
expected section was written incorrectly. Run UCramRunner manually (Step 3) to see what
the actual output is, then promote it.

### `val foo = <fun>` lines missing
When you define a helper with `>>>`, the REPL prints `val foo : ... = <fun>`. This must
appear in `EXAMPLES.md.ml.u`. Run `dune build EXAMPLES-actual.md.ml.u` once with no expected output
to discover the exact text.

### Output not captured (test helper uses `Printf.printf`)
`UCramRunner` only captures `Format.std_formatter` output. Redefine the helper to use
`Format.printf` instead, or use `Format.printf "%s@." (the_string ())`.

### `%{cma:the-lib-directory/LIBNAME}` dune variable fails
Ensure the library has been built (`dune build the-lib-directory/`) and that the name matches the
`(name ...)` field in `the-lib-directory/dune`. For a library named `re` in `lib/`, use `%{cma:lib/re}`.

---

## Further Resources

- **Full reference**: https://github.com/diskuv/dk/blob/V2_5/docs/UNIFIED_SCRIPTS.md
- **Issues**: https://github.com/diskuv/dk/issues
- **Source**: https://gitlab.com/dkml/build-tools/MlFront.git
