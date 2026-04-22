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

Expect test files normally import a test-library module (`open Import`) with helpers that
use `Format.printf` for output. Because the test library typically depends on `ppx_expect`,
you cannot load it directly in the REPL. Instead, **redefine the helpers inline** in
`EXAMPLES.md.ml.u`.

Here is a minimal two-helper setup suitable for a library named `Re` (adapt to your actual
library namespace):

```
## Setup

  >>> let test_re ?pos ?len re s =
  ...   match Re.exec_opt ?pos ?len (Re.compile re) s with
  ...   | None -> Format.printf "Not_found@."
  ...   | Some g ->
  ...     let offsets = Re.Group.all_offset g in
  ...     let items =
  ...       Array.to_list offsets
  ...       |> List.map (fun (a, b) -> Printf.sprintf "(%d, %d)" a b)
  ...     in
  ...     Format.printf "[| %s |]@." (String.concat "; " items)
  val test_re : ?pos:int -> ?len:int -> Re.t -> string -> unit = <fun>

  >>> let t re s =
  ...   match Re.exec_opt (Re.compile re) s with
  ...   | None -> Format.printf "<None>@."
  ...   | Some g -> Format.printf "%a@." Re.Group.pp g
  val t : Re.t -> string -> unit = <fun>
```

**Note**: The `val ... = <fun>` lines come from the OCaml REPL printing the type of each
defined function. They must be included in `EXAMPLES.md.ml.u` as expected output. Run
`UCramRunner` once to discover the exact text (see Step 3).

### Content That Transfers Directly

Only tests whose output helpers use `Format.printf` (or write to `Format.std_formatter`)
can be converted without changes:
- ✅ Helpers like `test_re`, `t` that call `Format.printf`
- ❌ Helpers that call `Printf.printf` or `print_endline` directly

For tests using `Printf.printf`, either skip them or wrap the call:
```ocaml
let my_test arg = Format.printf "%s@." (compute_result arg)
```

---

## Step 3: Run UCramRunner to Fill in Responses

On the first run, create `EXAMPLES.md.ml.u` with **commands only** and no response text.
UCramRunner fills in the actual REPL output.

### Build the library first

```bash
opam exec -- dune build lib/
```

### Run UCramRunner manually

```bash
opam exec -- UCramRunner EXAMPLES.md.ml.u \
  --load-with-dune _build/default/lib/<LIBNAME>.cma \
  -o EXAMPLES.md.ml.u.actual
```

Replace `<LIBNAME>` with the library name (e.g. `re`). `--load-with-dune` loads the `.cma`
and also adds its Dune `.objs/byte` directory to the search path so all sub-modules resolve.

### Review and promote

Inspect the `.actual` file to verify the responses match your original `[%expect]` blocks:
```bash
# Compare a few spot-checks against original tests
diff EXAMPLES.md.ml.u EXAMPLES.md.ml.u.actual
```
Once satisfied, promote the actual output as the new expected baseline:
```bash
cp EXAMPLES.md.ml.u.actual EXAMPLES.md.ml.u
rm  EXAMPLES.md.ml.u.actual   # remove it; dune owns this path from now on
```

---

## Step 4: Create Dune Rules

Add the following stanzas to the `dune` file in the same directory as `EXAMPLES.md.ml.u`
(typically the project root). These are **additive**—they do not touch existing rules.

```lisp
; Execute the unified script and capture REPL output
(rule
 (target EXAMPLES.md.ml.u.actual)
 (deps
  EXAMPLES.md.ml.u
  (glob_files lib/*.ml)
  (glob_files lib/*.mli))
 (action
  (run
   %{bin:UCramRunner}
   EXAMPLES.md.ml.u
   -o %{target}
   --workspace %{workspace_root}
   --load-with-dune %{cma:lib/<LIBNAME>})))

; Fail the build if the committed expected output differs from actual
(rule
 (alias runtest)
 (action
  (diff EXAMPLES.md.ml.u EXAMPLES.md.ml.u.actual)))

; Render the unified script to pretty Markdown documentation
(rule
 (target EXAMPLES.md)
 (deps EXAMPLES.md.ml.u)
 (action
  (run %{bin:U2Markdown} EXAMPLES.md.ml.u -o %{target})))
```

Replace `<LIBNAME>` with the Dune library name. The `%{cma:lib/<LIBNAME>}` variable
expands to the build-artifact `.cma` path for the workspace-local library.

**Rule summary:**

| Rule | Effect |
|------|--------|
| First | Runs UCramRunner, writes real REPL output to `.actual` |
| Second (runtest alias) | Diffs expected vs actual; fails if output changed |
| Third | Renders `.ml.u` to pretty `EXAMPLES.md` via U2Markdown |

---

## Step 5: Validate and Render

Build the `.actual` file through Dune and confirm the diff is clean:
```bash
opam exec -- dune build EXAMPLES.md.ml.u.actual
diff EXAMPLES.md.ml.u _build/default/EXAMPLES.md.ml.u.actual
```

Render to Markdown:
```bash
opam exec -- dune build EXAMPLES.md
cat _build/default/EXAMPLES.md
```

The Markdown output wraps each command in an `ocaml` fenced code block with syntax
highlighting, and each response in a `text` block.

### Coexistence with existing tests

Both PPX expect tests and unified script tests share the `runtest` alias.
To run only the unified script tests (without needing ppx_expect installed):
```bash
opam exec -- dune build EXAMPLES.md.ml.u.actual  # generation
diff EXAMPLES.md.ml.u _build/default/EXAMPLES.md.ml.u.actual  # validation
```

---

## Step 6: Continuous Integration

```yaml
# Example: GitHub Actions
- name: Build and validate unified examples
  run: |
    dune build EXAMPLES.md.ml.u.actual
    diff EXAMPLES.md.ml.u _build/default/EXAMPLES.md.ml.u.actual

- name: Render documentation
  run: dune build EXAMPLES.md
```

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `EXAMPLES.md.ml.u` | Source unified script (committed) |
| `EXAMPLES.md.ml.u.actual` | Built by dune; not committed |
| `EXAMPLES.md` | Rendered Markdown (committed or generated) |
| `dune` (root) | Location for the three new rules |

---

## Troubleshooting

### `UCramRunner` not found
```bash
opam pin add UnifiedScript_Std https://gitlab.com/dkml/build-tools/MlFront/-/releases/permalink/latest/downloads/MlFront.tar.gz
```

### `[cram test failed]` on first run
The `.ml.u` file has expected output that does not match. Either the code changed or the
expected section was written incorrectly. Run UCramRunner manually (Step 3) to see what
the actual output is, then promote it.

### `Multiple rules generated` error from dune
You left an `EXAMPLES.md.ml.u.actual` in the source tree. Dune wants to own that path:
```bash
rm EXAMPLES.md.ml.u.actual
```

### `val foo = <fun>` lines missing
When you define a helper with `>>>`, the REPL prints `val foo : ... = <fun>`. This must
appear in `EXAMPLES.md.ml.u`. Run UCramRunner once with no expected output to discover
the exact text.

### Output not captured (test helper uses `Printf.printf`)
`UCramRunner` only captures `Format.std_formatter` output. Redefine the helper to use
`Format.printf` instead, or use `Format.printf "%s@." (the_string ())`.

### `%{cma:lib/LIBNAME}` dune variable fails
Ensure the library has been built (`dune build lib/`) and that the name matches the
`(name ...)` field in `lib/dune`. For a library named `re` in `lib/`, use `%{cma:lib/re}`.

---

## Further Resources

- **Full reference**: https://github.com/diskuv/dk/blob/V2_5/docs/UNIFIED_SCRIPTS.md
- **Repository**: https://github.com/diskuv/dk

This skill guides you through converting OCaml expect tests into **unified scripts**—a format that combines executable code and expected output in a single, readable document that can be both run as tests and automatically rendered into beautiful documentation.

## What Are Unified Scripts?

Unified scripts are self-contained, executable documents. For OCaml projects, they use `.ml.u` files that:
- Execute OCaml REPL commands with the `#` prompt (ending with `;;`)
- Include expected output immediately after each command
- Can be rendered into pretty Markdown documentation
- Serve as both runnable tests and readable reference docs

**Example snippet from `EXAMPLES.md.ml.u`:**
```
# let two_plus_two = 2 + 2 ;;
val two_plus_two : int = 4

# Printf.printf "Value: %d\n" two_plus_two ;;
Value: 4
- : unit = ()
```

When rendered to Markdown, this becomes syntax-highlighted code blocks with output.

## Incremental Adoption: Coexistence Model

This skill creates a **separate test artifact** (`EXAMPLES.md.ml.u`) that:
- ✅ **Coexists** with existing `lib_test/expect/*.ml` expect tests
- ✅ Runs independently via separate dune rules
- ✅ Requires **no changes** to existing test infrastructure
- ✅ Can be adopted incrementally—convert some or all expect tests
- ✅ Produces rendered documentation (`EXAMPLES.md`) as a bonus

Both test formats run in `dune runtest`. The old PPX-based expect tests continue unchanged; this workflow adds a new, complementary approach.

## Project-Specific Goals

Convert OCaml expect tests from `lib_test/expect/*.ml` into:
- **Source**: `./EXAMPLES.md.ml.u` — unified script (both runnable test and source doc)
- **Output**: `./EXAMPLES.md` — rendered Markdown (pretty documentation)

The dune build system is configured to:
1. Run `UCramRunner` to execute commands in `EXAMPLES.md.ml.u` and validate output
2. Run `U2Markdown` to render `EXAMPLES.md.ml.u` into pretty `EXAMPLES.md`
3. Include both as part of the existing `dune runtest` workflow

---

## Step 1: Install the Unified Script Tools

The unified script ecosystem requires two tools:
- **UCramRunner** — Executes `.ml.u` scripts and validates outputs
- **U2Markdown** — Renders unified scripts to pretty Markdown

### Finding the OPAM Executable

Determine which OPAM executable to use, in priority order:

1. `build/d/opam.exe` (Windows executable)
2. `build/d/opam.cmd` (Windows batch script)
3. `build/d/opam.sh` (POSIX shell script)
4. `opam` in the system PATH (fallback)

### Installation Command

Use `opam pin add` to install bleeding-edge versions from the latest MlFront release:

```bash
# Resolve OPAM executable
OPAM_BIN="opam"
[ -x build/d/opam.exe ] && OPAM_BIN="build/d/opam.exe"
[ -x build/d/opam.cmd ] && OPAM_BIN="build/d/opam.cmd"
[ -x build/d/opam.sh ] && OPAM_BIN="build/d/opam.sh"

# Install tools
$OPAM_BIN pin add UnifiedScript_Std https://gitlab.com/dkml/build-tools/MlFront/-/releases/permalink/latest/downloads/MlFront.tar.gz
$OPAM_BIN pin add UnifiedScript_Top https://gitlab.com/dkml/build-tools/MlFront/-/releases/permalink/latest/downloads/MlFront.tar.gz
```

This installs `UCramRunner` and `U2Markdown` globally in your OPAM switch.

**Verification:**
```bash
which UCramRunner    # Should show path to executable
which U2Markdown     # Should show path to executable
```

---

## Step 2: Extract and Convert Expect Tests

### Understanding Expect Test Format

The project uses OCaml's ppx-based expect tests in `lib_test/expect/test_*.ml`:

```ocaml
let%expect_test "label" =
  test_re (str "a") "a";
  [%expect {| [| (0, 1) |] |}];
  test_re (str "a") "b";
  [%expect {| Not_found |}]
;;
```

Each test is:
1. A labeled test case (`let%expect_test "label"`)
2. One or more function calls (e.g., `test_re`)
3. `[%expect {| ... |}]` blocks capturing expected console output

### Conversion Strategy

Convert each expect test into OCaml REPL commands:

1. **Load required modules**: `# open Import ;;` and `# open Re ;;`
2. **Extract test code**: Copy the code before each `[%expect]` block
3. **Convert output**: Transform `[%expect {| OUTPUT |}]` into REPL output lines

**Conversion example:**

**Original (expect test):**
```ocaml
let%expect_test "str_matching" =
  test_re (str "a") "a";
  [%expect {| [| (0, 1) |] |}]
;;
```

**Converted (unified script):**
```
# open Import ;;
# open Re ;;

# test_re (str "a") "a" ;;
[| (0, 1) |]
```

### Tool-Based Conversion (Python Automation)

Use this Python script to automatically extract and convert expect tests:

```python
#!/usr/bin/env python3
# file: convert_expect.py
# Usage: python convert_expect.py

import re
import os
from pathlib import Path

def extract_expect_tests(file_content):
    """Extract expect tests from OCaml file."""
    tests = []
    
    # Match: let%expect_test "name" = ... [%expect {| output |}]
    pattern = r'let%expect_test\s+"([^"]+)"\s*=\s*(.*?)\[%expect\s*\{\|\s*([^}]+)\s*\|\}\s*\]'
    
    for match in re.finditer(pattern, file_content, re.DOTALL):
        name, body, expected = match.groups()
        tests.append((name, body.strip(), expected.strip()))
    
    return tests

def generate_unified_script(tests):
    """Generate unified script from extracted tests."""
    lines = []
    lines.append("# OCaml Re Examples and Tests")
    lines.append("")
    lines.append("This document shows verified examples of using the Re library.")
    lines.append("")
    lines.append("  # open Import ;;")
    lines.append("  # open Re ;;")
    lines.append("")
    
    for name, body, expected in tests:
        lines.append(f"## {name}")
        lines.append("")
        
        # Extract just the function calls (skip let statement)
        for line in body.split('\n'):
            line = line.strip()
            if line and not line.startswith('let%expect'):
                # Format as REPL command
                if not line.endswith(';;'):
                    line += ' ;;'
                lines.append(f"  # {line}")
        
        # Add expected output
        lines.append(f"  {expected}")
        lines.append("")
    
    return '\n'.join(lines)

def main():
    all_tests = []
    
    # Scan all test files
    for file in sorted(os.listdir('lib_test/expect')):
        if file.endswith('.ml') and file.startswith('test_'):
            path = os.path.join('lib_test/expect', file)
            with open(path, 'r') as f:
                content = f.read()
                tests = extract_expect_tests(content)
                all_tests.extend(tests)
    
    # Generate unified script
    script = generate_unified_script(all_tests)
    
    # Write output
    with open('EXAMPLES.md.ml.u', 'w') as f:
        f.write(script)
    
    print(f"Generated EXAMPLES.md.ml.u with {len(all_tests)} tests")

if __name__ == '__main__':
    main()
```

**To use the automation:**

```bash
python3 convert_expect.py
```

This produces `EXAMPLES.md.ml.u` automatically from the existing expect tests.

### Manual Conversion (If Preferred)

If you prefer manual conversion:

1. Open each `lib_test/expect/test_*.ml` file
2. For each `let%expect_test`:
   - Add a markdown heading with the test name: `## Test Name`
   - Extract the test body code
   - Format as REPL commands: `  # code ;;`
   - Add expected output prefixed with `  `
3. Combine all into `EXAMPLES.md.ml.u`

### Structure of EXAMPLES.md.ml.u

Your completed file should look like:

```
# OCaml Re Examples and Tests

This document contains verified examples of using the Re library.
Running this script validates that all examples work correctly.

  # open Import ;;
  # open Re ;;

## String Matching

  # test_re (str "a") "a" ;;
  [| (0, 1) |]

  # test_re (str "a") "b" ;;
  Not_found

## Pattern Alternation

  # test_re (alt [ char 'a'; char 'b' ]) "a" ;;
  [| (0, 1) |]

  # test_re (alt [ char 'a'; char 'b' ]) "c" ;;
  Not_found
```

---

## Step 3: Create Dune Rules

Add build rules to execute and render the unified script. Create a new `dune` file at the project root (or in the same directory as `EXAMPLES.md.ml.u`):

```lisp
; file: ./dune
; Executes and validates the unified script

(rule
 (target EXAMPLES.md.ml.u.actual)
 (deps EXAMPLES.md.ml.u
       (package re)
       (package base)
       (package fmt))
 (action
  (run UCramRunner EXAMPLES.md.ml.u
       -o %{target}
       --workspace %{workspace_root})))

(rule
 (alias runtest)
 (name validate_examples)
 (action (diff EXAMPLES.md.ml.u EXAMPLES.md.ml.u.actual)))

(rule
 (target EXAMPLES.md)
 (deps EXAMPLES.md.ml.u)
 (action
  (run U2Markdown EXAMPLES.md.ml.u -o %{target})))
```

**Rule explanations:**

1. **First rule** — Runs `UCramRunner` on `EXAMPLES.md.ml.u`, executes all commands, outputs results to `.actual`
2. **Second rule** — Diffs original `.ml.u` against `.actual` to validate outputs match. Part of `runtest` alias
3. **Third rule** — Renders the unified script to `EXAMPLES.md` using `U2Markdown`

---

## Step 4: Run and Validate

### Execute the Test Suite

```bash
dune runtest
```

**Expected output** if all tests pass:
```
Running 42 tests...
All tests passed.
```

**If tests fail** (output changed):
```
Error: diff command returned non-zero exit code:
  EXAMPLES.md.ml.u.actual:10: Expected `[| (0, 1) |]` but got `[| (0, 2) |]`
```

To update the expected output, run `UCramRunner` manually, review changes, and update the `.ml.u` file.

### Generate Documentation

```bash
dune build EXAMPLES.md
cat _build/default/EXAMPLES.md
```

The rendered file contains syntax-highlighted OCaml code blocks with output.

### Coexistence with Existing Tests

Both test formats run independently:

```bash
dune runtest
```

This now runs:
- ✅ Existing `lib_test/expect/test_*.ml` expect tests (unchanged)
- ✅ New `EXAMPLES.md.ml.u` unified script tests (new)

---

## Step 5: Continuous Integration

Add to your CI pipeline:

```yaml
- name: Run Unified Script Tests
  run: dune runtest

- name: Generate Documentation
  run: dune build EXAMPLES.md
```

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `EXAMPLES.md.ml.u` | Source unified script (runnable test + source) |
| `EXAMPLES.md` | Rendered documentation (generated) |
| `./dune` | Build rules (new, additive) |
| `lib_test/expect/test_*.ml` | Original expect tests (unchanged) |

---

## Troubleshooting

### UCramRunner Not Found
```bash
opam pin add UnifiedScript_Std https://gitlab.com/dkml/build-tools/MlFront/-/releases/permalink/latest/downloads/MlFront.tar.gz
which UCramRunner
```

### Diff Mismatch After Code Changes
```bash
# Review new output
opam exec -- UCramRunner EXAMPLES.md.ml.u -o EXAMPLES.md.ml.u.tmp --workspace .
diff EXAMPLES.md.ml.u EXAMPLES.md.ml.u.tmp

# Accept new output
cp EXAMPLES.md.ml.u.tmp EXAMPLES.md.ml.u
dune runtest
```

### Formatting Issues
Whitespace-sensitive rules:
- ✅ Commands: `  # code ;;` (2 spaces + hash + space)
- ✅ Output: `  line` (2 spaces, no prompt)
- ❌ Wrong: ` # code ;;` (1 space)
- ❌ Wrong: `  #code;;` (missing space after hash)

---

## Further Resources

- **Full Documentation**: https://github.com/diskuv/dk/blob/V2_5/docs/UNIFIED_SCRIPTS.md
- **Repository**: https://github.com/diskuv/dk

---

## Summary

This skill enables you to:

1. ✅ Convert OCaml expect tests into readable, runnable unified scripts
2. ✅ Run tests and validate output with `dune runtest`
3. ✅ Render beautiful Markdown documentation with `dune build EXAMPLES.md`
4. ✅ Maintain alongside existing expect tests (no replacement)
5. ✅ Automate conversion with provided Python tools
6. ✅ Integrate into CI/CD for persistent documentation

Unified scripts combine tests and documentation in a single, maintainable source—the best of both worlds for verified examples.
