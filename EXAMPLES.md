# ocaml-re: Examples

- [Helpers](#helpers)
- [Basic regex constructors (from `test_re.ml`)](#basic-regex-constructors--from--test-re-ml--)
  - [`str`](#-str-)
  - [`char` / `alt`](#-char-----alt-)
  - [`seq`](#-seq-)
  - [`empty` and `epsilon`](#-empty--and--epsilon-)
  - [`rep`](#-rep-)
- [Anchors (from `test_re.ml`)](#anchors--from--test-re-ml--)
  - [Beginning of line / end of line](#beginning-of-line---end-of-line)
  - [Word boundaries](#word-boundaries)
  - [Beginning / end of string](#beginning---end-of-string)
  - [`leol` (last end of line)](#-leol---last-end-of-line-)
  - [`start` / `stop` (relative to `~pos` / `~len`)](#-start-----stop---relative-to---pos------len--)
  - [`word` and `not_boundary`](#-word--and--not-boundary-)
- [Match semantics (from `test_re.ml`)](#match-semantics--from--test-re-ml--)
  - [Default (first / leftmost-first on whole regex)](#default--first---leftmost-first-on-whole-regex-)
  - [`shortest`](#-shortest-)
  - [`longest`](#-longest-)
  - [`first`](#-first-)
  - [Combined semantics](#combined-semantics)
  - [`greedy` / `non_greedy`](#-greedy-----non-greedy-)
- [Character sets (from `test_re.ml`)](#character-sets--from--test-re-ml--)
  - [`set`](#-set-)
  - [`rg`](#-rg-)
  - [`inter`](#-inter-)
  - [`diff`](#-diff-)
  - [`compl`](#-compl-)
  - [Case sensitivity](#case-sensitivity)
- [`witness` (from `test_re.ml`)](#-witness---from--test-re-ml--)
- [Groups (from `test_group.ml`)](#groups--from--test-group-ml--)
  - [Empty group](#empty-group)
  - [Zero-length group](#zero-length-group)
  - [No group](#no-group)
  - [Two adjacent groups](#two-adjacent-groups)
  - [Nested groups](#nested-groups)
  - [Group offsets when an optional group does not match](#group-offsets-when-an-optional-group-does-not-match)
  - [`no_group`](#-no-group-)
  - [`nest`](#-nest-)
- [Repetition counts (from `test_repn.ml`)](#repetition-counts--from--test-repn-ml--)
  - [Fixed repetition `{3,3}`](#fixed-repetition---3-3--)
  - [`repn`](#-repn-)
  - [Invalid `repn` arguments](#invalid--repn--arguments)
  - [`rep1`](#-rep1-)
  - [`opt`](#-opt-)
- [Iteration (from `test_iter.ml`)](#iteration--from--test-iter-ml--)
- [Splitting (from `test_split.ml`)](#splitting--from--test-split-ml--)
  - [`split`](#-split-)
  - [`split_delim`](#-split-delim-)
  - [`split_full`](#-split-full-)
- [Replacement (from `test_replace.ml`)](#replacement--from--test-replace-ml--)
  - [`replace_string`](#-replace-string-)
  - [Regression: bug 55](#regression--bug-55)
- [Marks (from `test_mark.ml`)](#marks--from--test-mark-ml--)
- [Partial matches (from `test_partial.ml`)](#partial-matches--from--test-partial-ml--)
  - [`exec_partial_detailed`](#-exec-partial-detailed-)
- [Backward ranges (from `test_186.ml`)](#backward-ranges--from--test-186-ml--)
- [Glob patterns (from `test_glob.ml`)](#glob-patterns--from--test-glob-ml--)
  - [Basic globs](#basic-globs)
  - [Brace expansion](#brace-expansion)
  - [Double asterisk](#double-asterisk)
  - [Backslash handling](#backslash-handling)
- [Perl dialect (from `test_perl.ml`)](#perl-dialect--from--test-perl-ml--)
  - [Escaping meta characters](#escaping-meta-characters)
  - [Basic metacharacters](#basic-metacharacters)
  - [Greedy quantifiers](#greedy-quantifiers)
  - [Non-greedy quantifiers](#non-greedy-quantifiers)
  - [Character classes](#character-classes)
  - [Zero-width assertions](#zero-width-assertions)
  - [Options](#options)
  - [Clustering, comments, backrefs](#clustering--comments--backrefs)
- [Emacs dialect (from `test_emacs.ml`)](#emacs-dialect--from--test-emacs-ml--)
  - [Not supported](#not-supported)
  - [Special characters](#special-characters)
  - [Alternatives and grouping](#alternatives-and-grouping)
  - [Contexts](#contexts)
- [PCRE split (from `test_pcre_split.ml`)](#pcre-split--from--test-pcre-split-ml--)
  - [`full_split`](#-full-split-)
- [POSIX (from `test_posix.ml`)](#posix--from--test-posix-ml--)
- [Color (from `test_color.ml`)](#color--from--test-color-ml--)
- [View (from `test_view.ml`)](#view--from--test-view-ml--)
- [Validation (from `test_validation.ml`)](#validation--from--test-validation-ml--)
- [Tests omitted from this script](#tests-omitted-from-this-script)


This literate test document demonstrates the public API of the
[`re`](https://github.com/ocaml/ocaml-re) library — pure OCaml regular
expressions supporting Perl, PCRE, POSIX, Emacs and Glob dialects.

Each executable snippet is run by `UCramRunner` and its output diffed against
the expected block that follows it. The snippets here mirror the `let%expect_test`
suites in `lib_test/expect/`, restricted to those that use only the public
`Re` API.

## Helpers

A small set of formatting helpers used throughout this document. All print to
`Format.std_formatter` so their output is captured by `UCramRunner`.


```ocaml
(* >>> *) let or_not_found f fmt v =
  match v () with
  | exception Not_found -> Format.fprintf fmt "Not_found"
  | s -> f fmt s
;;
```


```text
val or_not_found :
  (Format.formatter -> 'a -> unit) ->
  Format.formatter -> (unit -> 'a) -> unit = <fun>
```



```ocaml
(* >>> *) let array f fmt v =
  Format.fprintf fmt "[| ";
  Array.iteri (fun i x ->
    if i > 0 then Format.fprintf fmt "; ";
    f fmt x) v;
  Format.fprintf fmt " |]"
;;
```


```text
val array :
  (Format.formatter -> 'a -> unit) -> Format.formatter -> 'a array -> unit =
  <fun>
```



```ocaml
(* >>> *) let offset fmt (x, y) = Format.fprintf fmt "(%d, %d)" x y ;;
```


```text
val offset : Format.formatter -> int * int -> unit = <fun>
```



```ocaml
(* >>> *) let test_re ?pos ?len r s =
  let offsets () = Re.Group.all_offset (Re.exec ?pos ?len (Re.compile r) s) in
  Format.printf "%a@." (or_not_found (array offset)) offsets
;;
```


```text
val test_re : ?pos:int -> ?len:int -> Re.t -> string -> unit = <fun>
```



```ocaml
(* >>> *) let pp_group fmt g =
  let n = Re.Group.nb_groups g in
  Format.fprintf fmt "(Group";
  for i = 0 to n - 1 do
    match Re.Group.get_opt g i with
    | None -> Format.fprintf fmt "( (-1 -1))"
    | Some s ->
      let a, b = Re.Group.offset g i in
      Format.fprintf fmt "(%s (%d %d))" s a b
  done;
  Format.fprintf fmt ")"
;;
```


```text
val pp_group : Format.formatter -> Re.Group.t -> unit = <fun>
```



```ocaml
(* >>> *) let t re s =
  match Re.exec_opt (Re.compile re) s with
  | None -> Format.printf "<None>@."
  | Some g -> Format.printf "%a@." pp_group g
;;
```


```text
val t : Re.t -> string -> unit = <fun>
```



```ocaml
(* >>> *) let strings lst =
  Format.printf "[";
  List.iteri (fun i s ->
    if i > 0 then Format.printf "; ";
    Format.printf "%S" s) lst;
  Format.printf "]@."
;;
```


```text
val strings : string list -> unit = <fun>
```



```ocaml
(* >>> *) let invalid_argument f =
  match f () with
  | s -> ignore s
  | exception Invalid_argument s ->
    Format.printf "Invalid_argument %S@." s
;;
```


```text
val invalid_argument : (unit -> 'a) -> unit = <fun>
```



```ocaml
(* >>> *) let re_empty = Re.Posix.compile_pat "" ;;
```


```text
val re_empty : Re__.Core.re = <abstr>
```



```ocaml
(* >>> *) let re_whitespace = Re.Pcre.regexp "[\t ]+" ;;
```


```text
val re_whitespace : Re.Pcre.regexp = <abstr>
```



```ocaml
(* >>> *) let re_eol = Re.compile Re.eol ;;
```


```text
val re_eol : Re.re = <abstr>
```



```ocaml
(* >>> *) let re_bow = Re.compile Re.bow ;;
```


```text
val re_bow : Re.re = <abstr>
```



```ocaml
(* >>> *) let re_eow = Re.compile Re.eow ;;
```


```text
val re_eow : Re.re = <abstr>
```


---

## Basic regex constructors (from `test_re.ml`)

### `str`

Match a literal string.


```ocaml
(* >>> *) test_re (Re.str "a") "a"
```


```text
[| (0, 1) |]
```



```ocaml
(* >>> *) test_re (Re.str "a") "b"
```


```text
Not_found
```


### `char` / `alt`

Single-character alternation.


```ocaml
(* >>> *) test_re (Re.alt [ Re.char 'a'; Re.char 'b' ]) "a"
```


```text
[| (0, 1) |]
```



```ocaml
(* >>> *) test_re (Re.alt [ Re.char 'a'; Re.char 'b' ]) "b"
```


```text
[| (0, 1) |]
```



```ocaml
(* >>> *) test_re (Re.alt [ Re.char 'a'; Re.char 'b' ]) "c"
```


```text
Not_found
```


### `seq`

Concatenation of two characters.


```ocaml
(* >>> *) test_re (Re.seq [ Re.char 'a'; Re.char 'b' ]) "ab"
```


```text
[| (0, 2) |]
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.char 'a'; Re.char 'b' ]) "ac"
```


```text
Not_found
```


### `empty` and `epsilon`

`empty` never matches; `epsilon` matches at every position.


```ocaml
(* >>> *) test_re Re.empty ""
```


```text
Not_found
```



```ocaml
(* >>> *) test_re Re.empty "a"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re Re.epsilon ""
```


```text
[| (0, 0) |]
```



```ocaml
(* >>> *) test_re Re.epsilon "a"
```


```text
[| (0, 0) |]
```


### `rep`

Zero-or-more repetition.


```ocaml
(* >>> *) test_re (Re.rep (Re.char 'a')) ""
```


```text
[| (0, 0) |]
```



```ocaml
(* >>> *) test_re (Re.rep (Re.char 'a')) "a"
```


```text
[| (0, 1) |]
```



```ocaml
(* >>> *) test_re (Re.rep (Re.char 'a')) "aa"
```


```text
[| (0, 2) |]
```



```ocaml
(* >>> *) test_re (Re.rep (Re.char 'a')) "b"
```


```text
[| (0, 0) |]
```


---

## Anchors (from `test_re.ml`)

### Beginning of line / end of line


```ocaml
(* >>> *) test_re (Re.seq [ Re.bol; Re.char 'a' ]) "ab"
```


```text
[| (0, 1) |]
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.bol; Re.char 'a' ]) "b\na"
```


```text
[| (2, 3) |]
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.bol; Re.char 'a' ]) "ba"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.char 'a'; Re.eol ]) "ba"
```


```text
[| (1, 2) |]
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.char 'a'; Re.eol ]) "a\nb"
```


```text
[| (0, 1) |]
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.char 'a'; Re.eol ]) "ba\n"
```


```text
[| (1, 2) |]
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.char 'a'; Re.eol ]) "ab"
```


```text
Not_found
```


### Word boundaries


```ocaml
(* >>> *) test_re (Re.seq [ Re.bow; Re.char 'a' ]) "a"
```


```text
[| (0, 1) |]
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.bow; Re.char 'a' ]) "bb aa"
```


```text
[| (3, 4) |]
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.bow; Re.char 'a' ]) "ba ba"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re Re.bow ";"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re Re.bow ""
```


```text
Not_found
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.char 'a'; Re.eow ]) "a"
```


```text
[| (0, 1) |]
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.char 'a'; Re.eow ]) "bb aa"
```


```text
[| (4, 5) |]
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.char 'a'; Re.eow ]) "ab ab"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re Re.eow ";"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re Re.eow ""
```


```text
Not_found
```


### Beginning / end of string


```ocaml
(* >>> *) test_re (Re.seq [ Re.bos; Re.char 'a' ]) "ab"
```


```text
[| (0, 1) |]
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.bos; Re.char 'a' ]) "b\na"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.bos; Re.char 'a' ]) "ba"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.char 'a'; Re.eos ]) "ba"
```


```text
[| (1, 2) |]
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.char 'a'; Re.eos ]) "a\nb"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.char 'a'; Re.eos ]) "ba\n"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.char 'a'; Re.eos ]) "ab"
```


```text
Not_found
```


### `leol` (last end of line)


```ocaml
(* >>> *) test_re (Re.seq [ Re.char 'a'; Re.leol ]) "ba"
```


```text
[| (1, 2) |]
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.char 'a'; Re.leol ]) "a\nb"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.char 'a'; Re.leol ]) "ba\n"
```


```text
[| (1, 2) |]
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.char 'a'; Re.leol ]) "ab"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re (Re.alt [ Re.str "b\n"; Re.seq [ Re.char 'a'; Re.leol ] ]) "ab\n"
```


```text
[| (1, 3) |]
```


### `start` / `stop` (relative to `~pos` / `~len`)


```ocaml
(* >>> *) test_re ~pos:1 (Re.seq [ Re.start; Re.char 'a' ]) "xab"
```


```text
[| (1, 2) |]
```



```ocaml
(* >>> *) test_re ~pos:1 (Re.seq [ Re.start; Re.char 'a' ]) "xb\na"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re ~pos:1 (Re.seq [ Re.start; Re.char 'a' ]) "xba"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re ~len:2 (Re.seq [ Re.char 'a'; Re.stop ]) "bax"
```


```text
[| (1, 2) |]
```



```ocaml
(* >>> *) test_re ~len:3 (Re.seq [ Re.char 'a'; Re.stop ]) "a\nbx"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re ~len:3 (Re.seq [ Re.char 'a'; Re.stop ]) "ba\nx"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re ~len:2 (Re.seq [ Re.char 'a'; Re.stop ]) "abx"
```


```text
Not_found
```


### `word` and `not_boundary`


```ocaml
(* >>> *) test_re (Re.word (Re.str "aa")) "aa"
```


```text
[| (0, 2) |]
```



```ocaml
(* >>> *) test_re (Re.word (Re.str "aa")) "bb aa"
```


```text
[| (3, 5) |]
```



```ocaml
(* >>> *) test_re (Re.word (Re.str "aa")) "aaa"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re (Re.word (Re.str "")) ""
```


```text
Not_found
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.not_boundary; Re.char 'b'; Re.not_boundary ]) "abc"
```


```text
[| (1, 2) |]
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.char ';'; Re.not_boundary; Re.char ';' ]) ";;"
```


```text
[| (0, 2) |]
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.not_boundary; Re.char ';'; Re.not_boundary ]) ";"
```


```text
[| (0, 1) |]
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.not_boundary; Re.char 'a' ]) "abc"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re (Re.seq [ Re.char 'c'; Re.not_boundary ]) "abc"
```


```text
Not_found
```


---

## Match semantics (from `test_re.ml`)

### Default (first / leftmost-first on whole regex)


```ocaml
(* >>> *) test_re (Re.seq [ Re.rep (Re.alt [ Re.char 'a'; Re.char 'b' ]); Re.char 'b' ]) "aabaab"
```


```text
[| (0, 6) |]
```



```ocaml
(* >>> *) test_re (Re.alt [ Re.str "aa"; Re.str "aaa" ]) "aaaa"
```


```text
[| (0, 2) |]
```



```ocaml
(* >>> *) test_re (Re.alt [ Re.str "aaa"; Re.str "aa" ]) "aaaa"
```


```text
[| (0, 3) |]
```


### `shortest`


```ocaml
(* >>> *) test_re (Re.shortest (Re.seq [ Re.rep (Re.alt [ Re.char 'a'; Re.char 'b' ]); Re.char 'b' ])) "aabaab"
```


```text
[| (0, 3) |]
```



```ocaml
(* >>> *) test_re (Re.shortest (Re.alt [ Re.str "aa"; Re.str "aaa" ])) "aaaa"
```


```text
[| (0, 2) |]
```



```ocaml
(* >>> *) test_re (Re.shortest (Re.alt [ Re.str "aaa"; Re.str "aa" ])) "aaaa"
```


```text
[| (0, 2) |]
```


### `longest`


```ocaml
(* >>> *) test_re (Re.longest (Re.seq [ Re.rep (Re.alt [ Re.char 'a'; Re.char 'b' ]); Re.char 'b' ])) "aabaab"
```


```text
[| (0, 6) |]
```



```ocaml
(* >>> *) test_re (Re.longest (Re.alt [ Re.str "aa"; Re.str "aaa" ])) "aaaa"
```


```text
[| (0, 3) |]
```



```ocaml
(* >>> *) test_re (Re.longest (Re.alt [ Re.str "aaa"; Re.str "aa" ])) "aaaa"
```


```text
[| (0, 3) |]
```


### `first`


```ocaml
(* >>> *) test_re (Re.first (Re.seq [ Re.rep (Re.alt [ Re.char 'a'; Re.char 'b' ]); Re.char 'b' ])) "aabaab"
```


```text
[| (0, 6) |]
```



```ocaml
(* >>> *) test_re (Re.first (Re.alt [ Re.str "aa"; Re.str "aaa" ])) "aaaa"
```


```text
[| (0, 2) |]
```



```ocaml
(* >>> *) test_re (Re.first (Re.alt [ Re.str "aaa"; Re.str "aa" ])) "aaaa"
```


```text
[| (0, 3) |]
```


### Combined semantics


```ocaml
(* >>> *) let r = Re.rep (Re.group (Re.alt [ Re.str "aaa"; Re.str "aa" ])) in
test_re (Re.longest r) "aaaaaaa"
```


```text
[| (0, 7); (5, 7) |]
```



```ocaml
(* >>> *) let r = Re.rep (Re.group (Re.alt [ Re.str "aaa"; Re.str "aa" ])) in
test_re (Re.first r) "aaaaaaa"
```


```text
[| (0, 6); (3, 6) |]
```



```ocaml
(* >>> *) let r = Re.rep (Re.group (Re.alt [ Re.str "aaa"; Re.str "aa" ])) in
test_re (Re.first (Re.non_greedy r)) "aaaaaaa"
```


```text
[| (0, 0); (-1, -1) |]
```



```ocaml
(* >>> *) let r = Re.rep (Re.group (Re.alt [ Re.str "aaa"; Re.str "aa" ])) in
test_re (Re.shortest r) "aaaaaaa"
```


```text
[| (0, 0); (-1, -1) |]
```



```ocaml
(* >>> *) let r' = Re.rep (Re.group (Re.shortest (Re.alt [ Re.str "aaa"; Re.str "aa" ]))) in
test_re (Re.longest r') "aaaaaaa"
```


```text
[| (0, 7); (4, 7) |]
```



```ocaml
(* >>> *) let r' = Re.rep (Re.group (Re.shortest (Re.alt [ Re.str "aaa"; Re.str "aa" ]))) in
test_re (Re.first r') "aaaaaaa"
```


```text
[| (0, 6); (4, 6) |]
```


### `greedy` / `non_greedy`


```ocaml
(* >>> *) test_re (Re.greedy (Re.seq [ Re.rep (Re.alt [ Re.char 'a'; Re.char 'b' ]); Re.char 'b' ])) "aabaab"
```


```text
[| (0, 6) |]
```



```ocaml
(* >>> *) test_re (Re.greedy (Re.rep (Re.group (Re.opt (Re.char 'a'))))) "aa"
```


```text
[| (0, 2); (2, 2) |]
```



```ocaml
(* >>> *) test_re (Re.non_greedy (Re.longest (Re.seq [ Re.rep (Re.alt [ Re.char 'a'; Re.char 'b' ]); Re.char 'b' ]))) "aabaab"
```


```text
[| (0, 6) |]
```



```ocaml
(* >>> *) test_re (Re.non_greedy (Re.first (Re.seq [ Re.rep (Re.alt [ Re.char 'a'; Re.char 'b' ]); Re.char 'b' ]))) "aabaab"
```


```text
[| (0, 3) |]
```



```ocaml
(* >>> *) test_re (Re.non_greedy (Re.longest (Re.rep (Re.group (Re.opt (Re.char 'a')))))) "aa"
```


```text
[| (0, 2); (1, 2) |]
```


---

## Character sets (from `test_re.ml`)

### `set`


```ocaml
(* >>> *) test_re (Re.rep1 (Re.set "abcd")) "bcbadbabcdba"
```


```text
[| (0, 12) |]
```



```ocaml
(* >>> *) test_re (Re.set "abcd") "e"
```


```text
Not_found
```


### `rg`


```ocaml
(* >>> *) test_re (Re.rep1 (Re.rg '0' '9')) "0123456789"
```


```text
[| (0, 10) |]
```



```ocaml
(* >>> *) test_re (Re.rep1 (Re.rg '0' '9')) "a"
```


```text
Not_found
```


### `inter`


```ocaml
(* >>> *) test_re (Re.rep1 (Re.inter [ Re.rg '0' '9'; Re.rg '4' '6' ])) "456"
```


```text
[| (0, 3) |]
```



```ocaml
(* >>> *) test_re (Re.rep1 (Re.inter [ Re.rg '0' '9'; Re.rg '4' '6' ])) "7"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re (Re.inter [ Re.alt [ Re.char 'a'; Re.char 'b' ]; Re.char 'b' ]) "b"
```


```text
[| (0, 1) |]
```


### `diff`


```ocaml
(* >>> *) test_re (Re.rep1 (Re.diff (Re.rg '0' '9') (Re.rg '4' '6'))) "0123789"
```


```text
[| (0, 7) |]
```



```ocaml
(* >>> *) test_re (Re.rep1 (Re.diff (Re.rg '0' '9') (Re.rg '4' '6'))) "4"
```


```text
Not_found
```


### `compl`


```ocaml
(* >>> *) test_re (Re.rep1 (Re.compl [ Re.rg '0' '9'; Re.rg 'a' 'z' ])) "A:Z+"
```


```text
[| (0, 4) |]
```



```ocaml
(* >>> *) test_re (Re.rep1 (Re.compl [ Re.rg '0' '9'; Re.rg 'a' 'z' ])) "0"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re (Re.rep1 (Re.compl [ Re.rg '0' '9'; Re.rg 'a' 'z' ])) "a"
```


```text
Not_found
```


### Case sensitivity


```ocaml
(* >>> *) test_re (Re.case (Re.str "abc")) "abc"
```


```text
[| (0, 3) |]
```



```ocaml
(* >>> *) test_re (Re.no_case (Re.case (Re.str "abc"))) "abc"
```


```text
[| (0, 3) |]
```



```ocaml
(* >>> *) test_re (Re.case (Re.str "abc")) "ABC"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re (Re.no_case (Re.case (Re.str "abc"))) "ABC"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re (Re.no_case (Re.str "abc")) "abc"
```


```text
[| (0, 3) |]
```



```ocaml
(* >>> *) test_re (Re.no_case (Re.str "abc")) "ABC"
```


```text
[| (0, 3) |]
```


---

## `witness` (from `test_re.ml`)

`witness` produces a string that matches the given regex.


```ocaml
(* >>> *) Format.printf "%s@." (Re.witness (Re.set "ac"))
```


```text
a
```



```ocaml
(* >>> *) Format.printf "%s@." (Re.witness (Re.repn (Re.str "foo") 3 None))
```


```text
foofoofoo
```



```ocaml
(* >>> *) Format.printf "%s@." (Re.witness (Re.alt [ Re.char 'c'; Re.char 'd' ]))
```


```text
c
```



```ocaml
(* >>> *) Format.printf "%s@." (Re.witness (Re.no_case (Re.str "test")))
```


```text
TEST
```



```ocaml
(* >>> *) Format.printf "%s@." (Re.witness Re.eol)
```


---

## Groups (from `test_group.ml`)

### Empty group


```ocaml
(* >>> *) let empty = Re.group Re.empty in t empty ""
```


```text
<None>
```



```ocaml
(* >>> *) let empty = Re.group Re.empty in t empty "x"
```


```text
<None>
```


### Zero-length group


```ocaml
(* >>> *) let r = Re.group Re.bos in t r ""
```


```text
(Group( (0 0))( (0 0)))
```



```ocaml
(* >>> *) let r = Re.group Re.bos in t r "x"
```


```text
(Group( (0 0))( (0 0)))
```


### No group


```ocaml
(* >>> *) t Re.any ""
```


```text
<None>
```



```ocaml
(* >>> *) t Re.any "."
```


```text
(Group(. (0 1)))
```


### Two adjacent groups


```ocaml
(* >>> *) let r = Re.seq [ Re.group Re.any; Re.group Re.any ] in t r "a"
```


```text
<None>
```



```ocaml
(* >>> *) let r = Re.seq [ Re.group Re.any; Re.group Re.any ] in t r "ab"
```


```text
(Group(ab (0 2))(a (0 1))(b (1 2)))
```



```ocaml
(* >>> *) let r = Re.seq [ Re.group Re.any; Re.group Re.any ] in t r "abc"
```


```text
(Group(ab (0 2))(a (0 1))(b (1 2)))
```


### Nested groups


```ocaml
(* >>> *) let r = Re.group (Re.seq [ Re.group (Re.char 'a'); Re.char 'b' ]) in t r "ab"
```


```text
(Group(ab (0 2))(ab (0 2))(a (0 1)))
```


### Group offsets when an optional group does not match


```ocaml
(* >>> *) let r = Re.seq [ Re.group (Re.char 'a');
                 Re.opt (Re.group (Re.char 'a'));
                 Re.group (Re.char 'b') ] in
let m = Re.exec (Re.compile r) "ab" in
Format.printf "%a@." (array offset) (Re.Group.all_offset m)
```


```text
[| (0, 2); (0, 1); (-1, -1); (1, 2) |]
```


### `no_group`


```ocaml
(* >>> *) let r = Re.seq [ Re.group (Re.char 'a');
                 Re.opt (Re.group (Re.char 'a'));
                 Re.group (Re.char 'b') ] in
test_re (Re.no_group r) "ab"
```


```text
[| (0, 2) |]
```


### `nest`


```ocaml
(* >>> *) let r = Re.rep (Re.nest (Re.alt [ Re.group (Re.char 'a'); Re.char 'b' ])) in
test_re r "ab"
```


```text
[| (0, 2); (-1, -1) |]
```



```ocaml
(* >>> *) let r = Re.rep (Re.nest (Re.alt [ Re.group (Re.char 'a'); Re.char 'b' ])) in
test_re r "ba"
```


```text
[| (0, 2); (1, 2) |]
```


---

## Repetition counts (from `test_repn.ml`)

### Fixed repetition `{3,3}`


```ocaml
(* >>> *) let re = Re.compile (Re.repn (Re.char 'a') 3 (Some 3)) in
Format.printf "%b@." (Re.execp re "")
```


```text
false
```



```ocaml
(* >>> *) let re = Re.compile (Re.repn (Re.char 'a') 3 (Some 3)) in
Format.printf "%b@." (Re.execp re "aa")
```


```text
false
```



```ocaml
(* >>> *) let re = Re.compile (Re.repn (Re.char 'a') 3 (Some 3)) in
Format.printf "%b@." (Re.execp re "aaa")
```


```text
true
```



```ocaml
(* >>> *) let re = Re.compile (Re.repn (Re.char 'a') 3 (Some 3)) in
Format.printf "%b@." (Re.execp re "aaaa")
```


```text
true
```


### `repn`


```ocaml
(* >>> *) test_re (Re.repn (Re.char 'a') 0 None) ""
```


```text
[| (0, 0) |]
```



```ocaml
(* >>> *) test_re (Re.repn (Re.char 'a') 2 None) "a"
```


```text
Not_found
```



```ocaml
(* >>> *) test_re (Re.repn (Re.char 'a') 2 None) "aa"
```


```text
[| (0, 2) |]
```



```ocaml
(* >>> *) test_re (Re.repn (Re.char 'a') 0 (Some 0)) ""
```


```text
[| (0, 0) |]
```



```ocaml
(* >>> *) test_re (Re.repn (Re.char 'a') 1 (Some 2)) "a"
```


```text
[| (0, 1) |]
```



```ocaml
(* >>> *) test_re (Re.repn (Re.char 'a') 1 (Some 2)) "aa"
```


```text
[| (0, 2) |]
```



```ocaml
(* >>> *) test_re (Re.repn (Re.char 'a') 1 (Some 2)) ""
```


```text
Not_found
```



```ocaml
(* >>> *) test_re (Re.repn (Re.char 'a') 1 (Some 2)) "aaa"
```


```text
[| (0, 2) |]
```


### Invalid `repn` arguments


```ocaml
(* >>> *) invalid_argument (fun () -> Re.repn Re.empty (-1) None)
```


```text
Invalid_argument "Re.repn"
```



```ocaml
(* >>> *) invalid_argument (fun () -> Re.repn Re.empty 1 (Some 0))
```


```text
Invalid_argument "Re.repn"
```



```ocaml
(* >>> *) invalid_argument (fun () -> Re.repn Re.empty 4 (Some 3))
```


```text
Invalid_argument "Re.repn"
```


### `rep1`


```ocaml
(* >>> *) test_re (Re.rep1 (Re.char 'a')) "a"
```


```text
[| (0, 1) |]
```



```ocaml
(* >>> *) test_re (Re.rep1 (Re.char 'a')) "aa"
```


```text
[| (0, 2) |]
```



```ocaml
(* >>> *) test_re (Re.rep1 (Re.char 'a')) ""
```


```text
Not_found
```



```ocaml
(* >>> *) test_re (Re.rep1 (Re.char 'a')) "b"
```


```text
Not_found
```


### `opt`


```ocaml
(* >>> *) test_re (Re.opt (Re.char 'a')) ""
```


```text
[| (0, 0) |]
```



```ocaml
(* >>> *) test_re (Re.opt (Re.char 'a')) "a"
```


```text
[| (0, 1) |]
```


---

## Iteration (from `test_iter.ml`)


```ocaml
(* >>> *) let re = Re.Posix.compile_pat "(ab)+" in
strings (Re.matches re "aabab aaabba  dab ")
```


```text
["abab"; "ab"; "ab"]
```



```ocaml
(* >>> *) let re = Re.Posix.compile_pat "(ab)+" in
strings (Re.matches ~pos:2 ~len:7 re "abab ababab")
```


```text
["ab"; "abab"]
```



```ocaml
(* >>> *) strings (Re.matches re_empty "ab")
```


```text
[""; ""; ""]
```



```ocaml
(* >>> *) strings (Re.matches (Re.compile (Re.rep (Re.char 'a'))) "cat")
```


```text
[""; "a"; ""]
```


---

## Splitting (from `test_split.ml`)

### `split`


```ocaml
(* >>> *) let re_ws = Re.Posix.compile_pat "[\t ]+" in
strings (Re.split re_ws "aa bb c d ")
```


```text
["aa"; "bb"; "c"; "d"]
```



```ocaml
(* >>> *) let re_ws = Re.Posix.compile_pat "[\t ]+" in
strings (Re.split ~pos:1 ~len:4 re_ws "aa b c d")
```


```text
["a"; "b"]
```



```ocaml
(* >>> *) let re_ws = Re.Posix.compile_pat "[\t ]+" in
strings (Re.split re_ws " a full_word bc   ")
```


```text
["a"; "full_word"; "bc"]
```



```ocaml
(* >>> *) strings (Re.split re_empty "abcd")
```


```text
["a"; "b"; "c"; "d"]
```



```ocaml
(* >>> *) strings (Re.split re_eol "a\nb")
```


```text
["a"; "\nb"]
```



```ocaml
(* >>> *) strings (Re.split re_bow "a b")
```


```text
["a "; "b"]
```



```ocaml
(* >>> *) strings (Re.split re_eow "a b")
```


```text
["a"; " b"]
```



```ocaml
(* >>> *) let re_ws = Re.Posix.compile_pat "[\t ]+" in
strings (Re.split re_ws "")
```


```text
[]
```



```ocaml
(* >>> *) strings (Re.split re_empty "")
```


```text
[]
```


### `split_delim`


```ocaml
(* >>> *) let re_ws = Re.Posix.compile_pat "[\t ]+" in
strings (Re.split_delim re_ws "aa bb c d ")
```


```text
["aa"; "bb"; "c"; "d"; ""]
```



```ocaml
(* >>> *) let re_ws = Re.Posix.compile_pat "[\t ]+" in
strings (Re.split_delim ~pos:1 ~len:4 re_ws "aa b c d")
```


```text
["a"; "b"; ""]
```



```ocaml
(* >>> *) strings (Re.split_delim re_empty "abcd")
```


```text
[""; "a"; "b"; "c"; "d"; ""]
```



```ocaml
(* >>> *) strings (Re.split_delim re_eol "a\nb")
```


```text
["a"; "\nb"; ""]
```



```ocaml
(* >>> *) strings (Re.split_delim re_empty "")
```


```text
[""; ""]
```


### `split_full`


```ocaml
(* >>> *) let split_full ?pos ?len re s =
  let res = Re.split_full ?pos ?len re s in
  Format.printf "[";
  List.iteri (fun i what ->
    if i > 0 then Format.printf "; ";
    match what with
    | `Text s -> Format.printf "`T %S" s
    | `Delim g -> Format.printf "`D %S" (Re.Group.get g 0)) res;
  Format.printf "]@."
;;
```


```text
val split_full : ?pos:int -> ?len:int -> Re.re -> string -> unit = <fun>
```



```ocaml
(* >>> *) let re_ws = Re.Posix.compile_pat "[\t ]+" in
split_full re_ws "aa bb c d "
```


```text
[`T "aa"; `D " "; `T "bb"; `D " "; `T "c"; `D " "; `T "d"; `D " "]
```



```ocaml
(* >>> *) let re_ws = Re.Posix.compile_pat "[\t ]+" in
split_full ~pos:1 ~len:5 re_ws "aa \tb c d"
```


```text
[`T "a"; `D " \t"; `T "b"; `D " "]
```



```ocaml
(* >>> *) split_full re_empty "ab"
```


```text
[`D ""; `T "a"; `D ""; `T "b"; `D ""]
```



```ocaml
(* >>> *) split_full (Re.compile (Re.rep (Re.char 'a'))) "cat"
```


```text
[`D ""; `T "c"; `D "a"; `T "t"; `D ""]
```


---

## Replacement (from `test_replace.ml`)


```ocaml
(* >>> *) let re = Re.Posix.compile_pat "[a-zA-Z]+" in
let f sub = String.capitalize_ascii (Re.Group.get sub 0) in
Format.printf "%s@." (Re.replace re ~f " hello world; I love chips!")
```


```text
 Hello World; I Love Chips!
```


Replace only the first occurrence.


```ocaml
(* >>> *) let re = Re.Posix.compile_pat "[a-zA-Z]+" in
let f sub = String.capitalize_ascii (Re.Group.get sub 0) in
Format.printf "%s@." (Re.replace ~all:false re ~f " allo maman, bobo")
```


```text
 Allo maman, bobo
```


Empty pattern.


```ocaml
(* >>> *) Format.printf "%s@." (Re.replace re_empty ~f:(fun _ -> "a") "")
```


```text
a
```


`a*` against `cat`.


```ocaml
(* >>> *) Format.printf "%s@."
  (Re.replace (Re.compile (Re.rep (Re.char 'a'))) ~f:(fun _ -> "*") "cat")
```


```text
*c*t*
```


### `replace_string`


```ocaml
(* >>> *) let re = Re.Posix.compile_pat "_[a-zA-Z]+_" in
Format.printf "%s@." (Re.replace_string re ~by:"goodbye" "_hello_ world")
```


```text
goodbye world
```



```ocaml
(* >>> *) let re = Re.Posix.compile_pat "_[a-zA-Z]+_" in
Format.printf "%s@." (Re.replace_string ~all:false re ~by:"brown" "The quick _XXX_ fox")
```


```text
The quick brown fox
```


### Regression: bug 55


```ocaml
(* >>> *) let re = Re.compile Re.bol in
Format.printf "%s@." (Re.replace_string re ~by:"z" "abc")
```


```text
zabc
```



```ocaml
(* >>> *) let re = Re.compile Re.eow in
Format.printf "%s@." (Re.replace_string re ~by:"X" "one two three")
```


```text
oneX twoX threeX
```


---

## Marks (from `test_mark.ml`)


```ocaml
(* >>> *) let test_mark ?pos ?len r s il1 il2 =
  let subs = Re.exec ?pos ?len (Re.compile r) s in
  Format.printf "%b@."
    (List.for_all (Re.Mark.test subs) il1
     && List.for_all (fun x -> not (Re.Mark.test subs x)) il2)
;;
```


```text
val test_mark :
  ?pos:int ->
  ?len:int -> Re.t -> string -> Re.Mark.t list -> Re.Mark.t list -> unit =
  <fun>
```


A simple mark fires when its sub-expression matches.


```ocaml
(* >>> *) let i, r = Re.mark Re.digit in test_mark r "0" [ i ] []
```


```text
true
```


Mark inside a sequence.


```ocaml
(* >>> *) let i, r = Re.mark Re.digit in
let r = Re.seq [ r; r ] in
test_mark r "02" [ i ] []
```


```text
true
```


Mark inside a repetition.


```ocaml
(* >>> *) let i, r = Re.mark Re.digit in
let r = Re.rep r in
test_mark r "02" [ i ] []
```


```text
true
```


Marks inside alternation track which branch fired.


```ocaml
(* >>> *) let ia, ra = Re.mark (Re.char 'a') in
let ib, rb = Re.mark (Re.char 'b') in
let r = Re.alt [ ra; rb ] in
test_mark r "a" [ ia ] [ ib ];
test_mark r "b" [ ib ] [ ia ]
```


```text
true
true
```


Mark prefers leftmost branch.


```ocaml
(* >>> *) let two_chars = Re.seq [ Re.any; Re.any ] in
let lhs, x = Re.mark two_chars in
let rhs, x' = Re.mark two_chars in
let r = Re.alt [ x; x' ] in
test_mark r "aa" [ lhs ] [ rhs ]
```


```text
true
```


---

## Partial matches (from `test_partial.ml`)


```ocaml
(* >>> *) let exec_partial re s =
  let re = Re.compile re in
  let res = Re.exec_partial re s in
  Format.printf "`%s@."
    (match res with
     | `Partial -> "Partial"
     | `Full -> "Full"
     | `Mismatch -> "Mismatch")
;;
```


```text
val exec_partial : Re.t -> string -> unit = <fun>
```



```ocaml
(* >>> *) exec_partial (Re.str "hello") "he"
```


```text
`Partial
```



```ocaml
(* >>> *) exec_partial (Re.str "hello") "goodbye"
```


```text
`Partial
```



```ocaml
(* >>> *) exec_partial (Re.str "hello") "hello"
```


```text
`Partial
```



```ocaml
(* >>> *) exec_partial (Re.whole_string (Re.str "hello")) "hello"
```


```text
`Partial
```



```ocaml
(* >>> *) exec_partial (Re.whole_string (Re.str "hello")) "goodbye"
```


```text
`Mismatch
```



```ocaml
(* >>> *) exec_partial (Re.str "hello") ""
```


```text
`Partial
```



```ocaml
(* >>> *) exec_partial (Re.str "") "hello"
```


```text
`Full
```



```ocaml
(* >>> *) exec_partial (Re.whole_string (Re.str "hello")) ""
```


```text
`Partial
```


### `exec_partial_detailed`


```ocaml
(* >>> *) let exec_partial_detailed ?pos re s =
  let re = Re.compile re in
  match Re.exec_partial_detailed ?pos re s with
  | `Mismatch -> Format.printf "`Mismatch@."
  | `Partial p -> Format.printf "`Partial %d@." p
  | `Full g ->
    Format.printf "`Full [|";
    let offs = Re.Group.all_offset g in
    Array.iteri (fun i (a, b) ->
      if i > 0 then Format.printf ";";
      let m =
        match String.sub s a (b - a) with
        | exception Invalid_argument _ -> "<No match>"
        | x -> Printf.sprintf "%S" x
      in
      Format.printf "%d,%d,%s" a b m) offs;
    Format.printf "|]@."
;;
```


```text
val exec_partial_detailed : ?pos:int -> Re.t -> string -> unit = <fun>
```



```ocaml
(* >>> *) exec_partial_detailed (Re.str "hello") "he"
```


```text
`Partial 0
```



```ocaml
(* >>> *) exec_partial_detailed (Re.str "hello") "goodbye"
```


```text
`Partial 6
```



```ocaml
(* >>> *) exec_partial_detailed (Re.str "hello") "hello"
```


```text
`Full [|0,5,"hello"|]
```



```ocaml
(* >>> *) exec_partial_detailed (Re.whole_string (Re.str "hello")) "hello"
```


```text
`Full [|0,5,"hello"|]
```



```ocaml
(* >>> *) exec_partial_detailed (Re.whole_string (Re.str "hello")) "goodbye"
```


```text
`Mismatch
```



```ocaml
(* >>> *) exec_partial_detailed (Re.str "hello") ""
```


```text
`Partial 0
```



```ocaml
(* >>> *) exec_partial_detailed (Re.str "") "hello"
```


```text
`Full [|0,0,""|]
```



```ocaml
(* >>> *) exec_partial_detailed (Re.whole_string (Re.str "hello")) ""
```


```text
`Partial 0
```



```ocaml
(* >>> *) exec_partial_detailed (Re.str "abc") ".ab.ab"
```


```text
`Partial 4
```



```ocaml
(* >>> *) exec_partial_detailed ~pos:1 (Re.seq [ Re.not_boundary; Re.str "b" ]) "ab"
```


```text
`Full [|1,2,"b"|]
```



```ocaml
(* >>> *) exec_partial_detailed (Re.seq [ Re.group (Re.str "a"); Re.rep Re.any; Re.group (Re.str "b") ]) ".acb."
```


```text
`Full [|1,4,"acb";1,2,"a";3,4,"b"|]
```


---

## Backward ranges (from `test_186.ml`)

The four dialects all parse a backward range `[1-0]` etc. without error.


```ocaml
(* >>> *) let print_result fmt r =
  Format.fprintf fmt "%s"
    (match r with
     | Ok _ -> "backward range parsed"
     | Error `Parse_error -> "parse error"
     | Error `Not_supported -> "not supported")
;;
```


```text
val print_result :
  Format.formatter -> ('a, [< `Not_supported | `Parse_error ]) result -> unit =
  <fun>
```



```ocaml
(* >>> *) let cases = [ "[1-0]"; "[5-1]"; "[6-6]"; "[z-a]"; "[b-b]" ] ;;
```


```text
val cases : string list = ["[1-0]"; "[5-1]"; "[6-6]"; "[z-a]"; "[b-b]"]
```



```ocaml
(* >>> *) List.iter (fun re -> Format.printf "%s: %a@." re print_result (Re.Perl.re_result re)) cases
```


```text
[1-0]: backward range parsed
[5-1]: backward range parsed
[6-6]: backward range parsed
[z-a]: backward range parsed
[b-b]: backward range parsed
```



```ocaml
(* >>> *) List.iter (fun re -> Format.printf "%s: %a@." re print_result (Re.Pcre.re_result re)) cases
```


```text
[1-0]: backward range parsed
[5-1]: backward range parsed
[6-6]: backward range parsed
[z-a]: backward range parsed
[b-b]: backward range parsed
```



```ocaml
(* >>> *) List.iter (fun re -> Format.printf "%s: %a@." re print_result (Re.Posix.re_result re)) cases
```


```text
[1-0]: backward range parsed
[5-1]: backward range parsed
[6-6]: backward range parsed
[z-a]: backward range parsed
[b-b]: backward range parsed
```



```ocaml
(* >>> *) List.iter (fun re -> Format.printf "%s: %a@." re print_result (Re.Emacs.re_result re)) cases
```


```text
[1-0]: backward range parsed
[5-1]: backward range parsed
[6-6]: backward range parsed
[z-a]: backward range parsed
[b-b]: backward range parsed
```


A backward range constructed directly via `Re.rg` is allowed.


```ocaml
(* >>> *) Format.printf "%a@." Re.pp (Re.rg '5' '0')
```


```text
(Set 48-53)
```



```ocaml
(* >>> *) Format.printf "%a@." Re.pp (Re.rg '0' '5')
```


```text
(Set 48-53)
```


---

## Glob patterns (from `test_glob.ml`)


```ocaml
(* >>> *) let glob ?match_backslashes ?expand_braces ?anchored ?pathname ?period re s =
  let re =
    Re.Glob.glob ?match_backslashes ?expand_braces ?anchored ?pathname ?period re
    |> Re.compile
  in
  Format.printf "%b@." (Re.execp re s)
;;
```


```text
val glob :
  ?match_backslashes:bool ->
  ?expand_braces:bool ->
  ?anchored:bool ->
  ?pathname:bool -> ?period:bool -> string -> string -> unit = <fun>
```


### Basic globs


```ocaml
(* >>> *) glob "foo*" "foobar"
```


```text
true
```



```ocaml
(* >>> *) glob "fo?bar" "fobar"
```


```text
false
```



```ocaml
(* >>> *) glob "fo?bar" "foobar"
```


```text
true
```



```ocaml
(* >>> *) glob "fo?bar" "foo0bar"
```


```text
false
```



```ocaml
(* >>> *) glob "?oobar" "foobar"
```


```text
true
```



```ocaml
(* >>> *) glob "*bar" "foobar"
```


```text
true
```



```ocaml
(* >>> *) glob "\\*bar" "foobar"
```


```text
false
```



```ocaml
(* >>> *) glob "\\*bar" "*bar"
```


```text
true
```



```ocaml
(* >>> *) glob "[ab]foo" "afoo"
```


```text
true
```



```ocaml
(* >>> *) glob "[ab]foo" "bfoo"
```


```text
true
```



```ocaml
(* >>> *) glob "[ab]foo" "cfoo"
```


```text
false
```



```ocaml
(* >>> *) glob "c[ab]foo" "cabfoo"
```


```text
false
```



```ocaml
(* >>> *) glob ".foo" ".foo"
```


```text
true
```



```ocaml
(* >>> *) glob ".foo" "afoo"
```


```text
false
```



```ocaml
(* >>> *) glob "*[.]foo" "a.foo"
```


```text
true
```



```ocaml
(* >>> *) glob "*[.]foo" "ba.foo"
```


```text
true
```



```ocaml
(* >>> *) glob "*.foo" ".foo"
```


```text
false
```



```ocaml
(* >>> *) glob "*[.]foo" ".foo"
```


```text
false
```



```ocaml
(* >>> *) glob ~anchored:true "*/foo" "/foo"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "foo/*" "foo/"
```


```text
true
```



```ocaml
(* >>> *) glob "/[^f]" "/foo"
```


```text
false
```



```ocaml
(* >>> *) glob "/[^f]" "/bar"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "/[^f]" "/bar"
```


```text
false
```



```ocaml
(* >>> *) glob ~anchored:true "*" ".bar"
```


```text
false
```



```ocaml
(* >>> *) glob "foo[.]bar" "foo.bar"
```


```text
true
```



```ocaml
(* >>> *) glob "[.]foo" ".foo"
```


```text
false
```



```ocaml
(* >>> *) glob "foo[/]bar" "foo/bar"
```


```text
false
```



```ocaml
(* >>> *) glob ~anchored:true "*bar" "foobar"
```


```text
true
```



```ocaml
(* >>> *) glob "foo" "foobar"
```


```text
true
```



```ocaml
(* >>> *) glob "bar" "foobar"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "foo" "foobar"
```


```text
false
```



```ocaml
(* >>> *) glob ~anchored:true "bar" "foobar"
```


```text
false
```



```ocaml
(* >>> *) glob "{foo,bar}bar" "foobar"
```


```text
false
```



```ocaml
(* >>> *) glob "{foo,bar}bar" "{foo,bar}bar"
```


```text
true
```



```ocaml
(* >>> *) glob "foo?bar" "foo/bar"
```


```text
false
```


### Brace expansion


```ocaml
(* >>> *) glob ~expand_braces:true "{foo,far}bar" "foobar"
```


```text
true
```



```ocaml
(* >>> *) glob ~expand_braces:true "{foo,far}bar" "farbar"
```


```text
true
```



```ocaml
(* >>> *) glob ~expand_braces:true "{foo,far}bar" "{foo,far}bar"
```


```text
false
```


### Double asterisk


```ocaml
(* >>> *) glob ~anchored:true "**" "foobar"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "**" "foo/bar"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "**/bar" "foo/bar"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "**/bar" "foo/far/bar"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "foo/**" "foo"
```


```text
false
```



```ocaml
(* >>> *) glob ~anchored:true "foo/**" "foo/bar"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "foo/**" "foo/far/bar"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "foo/**/bar" "foo/far/bar"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "foo/**/bar" "foo/far/oof/bar"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "foo/**bar" "foo/far/oofbar"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "foo/**bar" "foo/bar"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "foo/**bar" "foo/foobar"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "/**" "//foo"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "/**" "/"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "/**" "/x"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "**" "foo//bar"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "foo/bar/**/*.ml" "foo/bar/baz/foobar.ml"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "foo/bar/**/*.ml" "foo/bar/foobar.ml"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "foo/**/bar/**/baz" "foo/bar/baz"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "foo/**/bar/**/baz" "foo/bar/x/y/z/baz"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "foo/**/bar/**/baz" "foo/x/y/z/bar/baz"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "foo/**/bar/**/baz" "foo/bar/x/bar/x/baz"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true "foo/**/bar/**/baz" "foo/bar/../x/baz"
```


```text
false
```



```ocaml
(* >>> *) glob ~anchored:true "foo/**/bar/**/baz" "foo/bar/./x/baz"
```


```text
false
```


### Backslash handling


```ocaml
(* >>> *) glob ~anchored:true ~match_backslashes:false "a/b/c" "a\\b/c"
```


```text
false
```



```ocaml
(* >>> *) glob ~anchored:true ~match_backslashes:false "a\\b" "ab"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true ~match_backslashes:false "a/*.ml" "a/b\\c.ml"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true ~match_backslashes:true "a/b/c" "a\\b/c"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true ~match_backslashes:true "a/b/*.ml" "a\\b\\c.ml"
```


```text
true
```



```ocaml
(* >>> *) glob ~anchored:true ~match_backslashes:true "/" "\\"
```


```text
true
```


---

## Perl dialect (from `test_perl.ml`)


```ocaml
(* >>> *) let re ?opts s = Format.printf "%a@." Re.pp (Re.Perl.re ?opts s) ;;
```


```text
val re : ?opts:Re.Perl.opt list -> string -> unit = <fun>
```



```ocaml
(* >>> *) let try_parse ?opts s =
  try ignore (Re.Perl.re ?opts s);
    Format.printf "Parsed successfully@."
  with
  | Re.Perl.Parse_error -> Format.printf "Parse error@."
  | Re.Perl.Not_supported -> Format.printf "Not supported@."
;;
```


```text
val try_parse : ?opts:Re.Perl.opt list -> string -> unit = <fun>
```


### Escaping meta characters


```ocaml
(* >>> *) re "\\^"
```


```text
(Set 94)
```



```ocaml
(* >>> *) re "\\."
```


```text
(Set 46)
```



```ocaml
(* >>> *) re "\\$"
```


```text
(Set 36)
```



```ocaml
(* >>> *) re "\\|"
```


```text
(Set 124)
```



```ocaml
(* >>> *) re "\\("
```


```text
(Set 40)
```



```ocaml
(* >>> *) re "\\)"
```


```text
(Set 41)
```



```ocaml
(* >>> *) re "\\["
```


```text
(Set 91)
```



```ocaml
(* >>> *) re "\\]"
```


```text
(Set 93)
```



```ocaml
(* >>> *) re "\\*"
```


```text
(Set 42)
```



```ocaml
(* >>> *) re "\\+"
```


```text
(Set 43)
```



```ocaml
(* >>> *) re "\\?"
```


```text
(Set 63)
```



```ocaml
(* >>> *) re "\\\\"
```


```text
(Set 92)
```


### Basic metacharacters


```ocaml
(* >>> *) re "^"
```


```text
Beg_of_str
```



```ocaml
(* >>> *) re "."
```


```text
(Set 0-9, 11-255)
```



```ocaml
(* >>> *) re "$"
```


```text
End_of_str
```



```ocaml
(* >>> *) re "a|b"
```


```text
(Alternative (Set 97)(Set 98))
```



```ocaml
(* >>> *) re "aa|bb"
```


```text
(Alternative (Sequence (Set 97)(Set 97))(Sequence (Set 98)(Set 98)))
```



```ocaml
(* >>> *) re "(a)"
```


```text
(Group (Set 97))
```



```ocaml
(* >>> *) re "(a|b)c"
```


```text
(Sequence (Group (Alternative (Set 97)(Set 98)))(Set 99))
```



```ocaml
(* >>> *) re "[ab]"
```


```text
(Alternative (Set 98)(Set 97))
```



```ocaml
(* >>> *) re "[a-z]"
```


```text
(Set 97-122)
```



```ocaml
(* >>> *) re "[^a-z]"
```


```text
(Complement (Set 97-122))
```


### Greedy quantifiers


```ocaml
(* >>> *) re "a*"
```


```text
(Sem_greedy Greedy (Repeat (Set 97) 0))
```



```ocaml
(* >>> *) re "a+"
```


```text
(Sem_greedy Greedy (Repeat (Set 97) 1))
```



```ocaml
(* >>> *) re "a?"
```


```text
(Sem_greedy Greedy (Repeat (Set 97) 0 1))
```



```ocaml
(* >>> *) re "a{10}"
```


```text
(Sem_greedy Greedy (Repeat (Set 97) 10 10))
```



```ocaml
(* >>> *) re "a{10,}"
```


```text
(Sem_greedy Greedy (Repeat (Set 97) 10))
```



```ocaml
(* >>> *) re "a{10,12}"
```


```text
(Sem_greedy Greedy (Repeat (Set 97) 10 12))
```


### Non-greedy quantifiers


```ocaml
(* >>> *) re "a*?"
```


```text
(Sem_greedy Non_greedy (Repeat (Set 97) 0))
```



```ocaml
(* >>> *) re "a+?"
```


```text
(Sem_greedy Non_greedy (Repeat (Set 97) 1))
```



```ocaml
(* >>> *) re "a??"
```


```text
(Sem_greedy Non_greedy (Repeat (Set 97) 0 1))
```


### Character classes


```ocaml
(* >>> *) re "\\s"
```


```text
(Set 9-13, 32)
```



```ocaml
(* >>> *) re "\\S"
```


```text
(Complement (Set 9-13, 32))
```



```ocaml
(* >>> *) re "\\d"
```


```text
(Set 48-57)
```



```ocaml
(* >>> *) re "\\D"
```


```text
(Complement (Set 48-57))
```


### Zero-width assertions


```ocaml
(* >>> *) re "\\b"
```


```text
(Alternative Beg_of_wordEnd_of_word)
```



```ocaml
(* >>> *) re "\\B"
```


```text
Not_bound
```



```ocaml
(* >>> *) re "\\A"
```


```text
Beg_of_str
```



```ocaml
(* >>> *) re "\\Z"
```


```text
Last_end_of_line
```



```ocaml
(* >>> *) re "\\z"
```


```text
End_of_str
```



```ocaml
(* >>> *) re "\\G"
```


```text
Start
```


### Options


```ocaml
(* >>> *) re ~opts:[ `Anchored ] "a"
```


```text
(Sequence Start(Set 97))
```



```ocaml
(* >>> *) re ~opts:[ `Caseless ] "b"
```


```text
(No_case (Set 98))
```



```ocaml
(* >>> *) re ~opts:[ `Dollar_endonly ] "$"
```


```text
Last_end_of_line
```



```ocaml
(* >>> *) re ~opts:[ `Dollar_endonly; `Multiline ] "$"
```


```text
End_of_line
```



```ocaml
(* >>> *) re ~opts:[ `Dotall ] "."
```


```text
(Set 0-255)
```



```ocaml
(* >>> *) re ~opts:[ `Multiline ] "^"
```


```text
Beg_of_line
```



```ocaml
(* >>> *) re ~opts:[ `Multiline ] "$"
```


```text
End_of_line
```



```ocaml
(* >>> *) re ~opts:[ `Ungreedy ] "a*"
```


```text
(Sem_greedy Non_greedy (Repeat (Set 97) 0))
```



```ocaml
(* >>> *) re ~opts:[ `Ungreedy ] "a*?"
```


```text
(Sem_greedy Greedy (Repeat (Set 97) 0))
```


### Clustering, comments, backrefs


```ocaml
(* >>> *) re "(?:a)"
```


```text
(Set 97)
```



```ocaml
(* >>> *) re "(?:a|b)c"
```


```text
(Sequence (Alternative (Set 97)(Set 98))(Set 99))
```



```ocaml
(* >>> *) re "a(?#comment)b"
```


```text
(Sequence (Set 97)(Sequence )(Set 98))
```



```ocaml
(* >>> *) try_parse "(?#"
```


```text
Parse error
```



```ocaml
(* >>> *) try_parse "\\0"
```


```text
Not supported
```


---

## Emacs dialect (from `test_emacs.ml`)


```ocaml
(* >>> *) let ere s = Format.printf "%a@." Re.pp (Re.Emacs.re s) ;;
```


```text
val ere : string -> unit = <fun>
```


### Not supported


```ocaml
(* >>> *) let try_parse s =
  try ignore (Re.Emacs.re s) with
  | Re.Emacs.Parse_error -> Format.printf "Parse error@."
  | Re.Emacs.Not_supported -> Format.printf "Not supported@."
;;
```


```text
val try_parse : string -> unit = <fun>
```



```ocaml
(* >>> *) try_parse "*ab"
```


```text
Parse error
```



```ocaml
(* >>> *) try_parse "+ab"
```


```text
Parse error
```



```ocaml
(* >>> *) try_parse "?ab"
```


```text
Parse error
```



```ocaml
(* >>> *) try_parse "\\0"
```


```text
Not supported
```


### Special characters


```ocaml
(* >>> *) ere "."
```


```text
(Set 0-9, 11-255)
```



```ocaml
(* >>> *) ere "a*"
```


```text
(Repeat (Set 97) 0)
```



```ocaml
(* >>> *) ere "a+"
```


```text
(Repeat (Set 97) 1)
```



```ocaml
(* >>> *) ere "a?"
```


```text
(Repeat (Set 97) 0 1)
```



```ocaml
(* >>> *) ere "[ab]"
```


```text
(Alternative (Set 98)(Set 97))
```



```ocaml
(* >>> *) ere "[a-z]"
```


```text
(Set 97-122)
```



```ocaml
(* >>> *) ere "^"
```


```text
Beg_of_line
```



```ocaml
(* >>> *) ere "$"
```


```text
End_of_line
```


### Alternatives and grouping


```ocaml
(* >>> *) ere "a\\|b"
```


```text
(Alternative (Set 97)(Set 98))
```



```ocaml
(* >>> *) ere "\\(a\\)"
```


```text
(Group (Set 97))
```



```ocaml
(* >>> *) ere "\\(a\\|b\\)c"
```


```text
(Sequence (Group (Alternative (Set 97)(Set 98)))(Set 99))
```


### Contexts


```ocaml
(* >>> *) ere "\\`"
```


```text
Beg_of_str
```



```ocaml
(* >>> *) ere "\\'"
```


```text
End_of_str
```



```ocaml
(* >>> *) ere "\\="
```


```text
Start
```



```ocaml
(* >>> *) ere "\\b"
```


```text
(Alternative Beg_of_wordEnd_of_word)
```



```ocaml
(* >>> *) ere "\\B"
```


```text
Not_bound
```



```ocaml
(* >>> *) ere "\\<"
```


```text
Beg_of_word
```



```ocaml
(* >>> *) ere "\\>"
```


```text
End_of_word
```


---

## PCRE split (from `test_pcre_split.ml`)


```ocaml
(* >>> *) let split ~rex s = Re.Pcre.split ~rex s |> strings ;;
```


```text
val split : rex:Re.Pcre.regexp -> string -> unit = <fun>
```



```ocaml
(* >>> *) split ~rex:re_whitespace "aa bb c d "
```


```text
["aa"; "bb"; "c"; "d"]
```



```ocaml
(* >>> *) split ~rex:re_whitespace " a full_word bc   "
```


```text
["a"; "full_word"; "bc"]
```



```ocaml
(* >>> *) split ~rex:re_empty "abcd"
```


```text
["a"; "b"; "c"; "d"]
```



```ocaml
(* >>> *) split ~rex:re_eol "a\nb"
```


```text
["a"; "\nb"]
```



```ocaml
(* >>> *) split ~rex:re_bow "a b"
```


```text
["a "; "b"]
```



```ocaml
(* >>> *) split ~rex:re_eow "a b"
```


```text
["a"; " b"]
```



```ocaml
(* >>> *) let rex = Re.Pcre.regexp "" in split ~rex "xx"
```


```text
["x"; "x"]
```


### `full_split`


```ocaml
(* >>> *) let full_split ?max ~rex s =
  let res = Re.Pcre.full_split ?max ~rex s in
  Format.printf "[";
  List.iteri (fun i what ->
    if i > 0 then Format.printf "; ";
    match (what : Re.Pcre.split_result) with
    | Text s -> Format.printf "Text %S" s
    | Delim s -> Format.printf "Delim %S" s
    | NoGroup -> Format.printf "NoGroup"
    | Group (x, s) -> Format.printf "Group (%d, %S)" x s) res;
  Format.printf "]@."
;;
```


```text
val full_split : ?max:int -> rex:Re.Pcre.regexp -> string -> unit = <fun>
```



```ocaml
(* >>> *) full_split ~rex:(Re.Pcre.regexp "x(x)?") "testxxyyy"
```


```text
[Text "test"; Delim "xx"; Group (1, "x"); Text "yyy"]
```



```ocaml
(* >>> *) full_split ~rex:(Re.Pcre.regexp "x(x)?") "testxyyy"
```


```text
[Text "test"; Delim "x"; NoGroup; Text "yyy"]
```



```ocaml
(* >>> *) full_split ~rex:(Re.Pcre.regexp "[:_]") ""
```


```text
[]
```



```ocaml
(* >>> *) full_split ~max:1 ~rex:(Re.Pcre.regexp "[:_]") "xxx:yyy"
```


```text
[Text "xxx:yyy"]
```


---

## POSIX (from `test_posix.ml`)


```ocaml
(* >>> *) let re = Re.Posix.compile_pat {|a[[:space:]]b|} in
let exec = Re.execp re in
Format.printf "%b %b %b@." (exec "a b") (exec "ab") (exec "a_b")
```


```text
true false false
```


---

## Color (from `test_color.ml`)

A regex matching every byte distinguishes every single character.


```ocaml
(* >>> *) let all_chars = String.init 256 Char.chr in
let re = Re.set all_chars |> Re.whole_string |> Re.compile in
let ok = ref true in
for i = 0 to String.length all_chars - 1 do
  if not (Re.execp re (String.make 1 all_chars.[i])) then ok := false
done;
Format.printf "%b@." !ok
```


```text
true
```


---

## View (from `test_view.ml`)

`Re.View.view` exposes the structure of a compiled-friendly regex.


```ocaml
(* >>> *) let _view = Re.View.view (Re.str "foo") in
Format.printf "ok@."
```


```text
ok
```


---

## Validation (from `test_validation.ml`)

Out-of-bounds positions raise `Invalid_argument`.


```ocaml
(* >>> *) let any_re = Re.compile (Re.rep Re.any) in
let _ = Re.execp any_re ~pos:4 "foo" in
Format.printf "ok@."
```


```text
ok
```



```ocaml
(* >>> *) let any_re = Re.compile (Re.rep Re.any) in
invalid_argument (fun () -> Re.execp any_re ~pos:1 ~len:3 "foo")
```


```text
Invalid_argument "Re.exec: out of bounds"
```


---

## Tests omitted from this script

The following expect-test files are intentionally **not** mirrored here because
they exercise internal modules (`Re_private.Cset`, `Re_private.Automata`,
`Re_private.Bit_vector`, `Re_private.Hash_set`, `Re_private.Pcre` private
helpers, `Re_private.Ast`, `Re_private.Category`) that are not exposed by the
public `re` library and therefore cannot be loaded from a top-level using only
`re.cma`:

- `test_csets.ml`
- `test_category.ml`
- `test_bit_vector.ml`
- `test_hashset.ml`
- `test_automata.ml`
- `test_alternation.ml`
- `test_pcre.ml` (uses `Re_private.Pcre` and `Re_private.Ast`)
- `test_pcre_288.ml` (uses `Re_private.Pcre`)
- `test_str.ml` (compares against the stdlib `Str` via internal helpers)
- `test_stream.ml` (uses public `Re.Stream` but is large; can be added in a
  follow-up by rewriting its `Printf.printf` helpers to `Format.printf`)

The original `let%expect_test`s for these files continue to run unchanged
under `dune runtest`.