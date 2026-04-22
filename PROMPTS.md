# Prompt Engineering

## Creating .claude/skills/make-literate-tests/SKILL.md

1. Hand-wrote the YAML metadata for `SKILL.md`
2. Hand-wrote `copy-skills.cmd`
3. Claude Sonnet 4.6 High prompt

    ```text
    Read the reference document  https://github.com/diskuv/dk/blob/V2_5/docs/UNIFIED_SCRIPTS.md and complete the writing of the project-based skill "make-literate-tests". The skill should be able to translate OCaml expect tests into unified scripts. The project has a large collection of expect scripts in lib_tests/expect. The skill should be able to convert all of those expect scripts into a single unified, runnable script "<projectroot>/EXAMPLES.md.ml.u". The skill should also have the dune "runtest" alias run the test commands in "<projectroot>/EXAMPLES.md.ml.u", and also have dune rules that render "<projectroot>/EXAMPLES.md.ml.u" into "<projectroot>/EXAMPLES.md".
    ```

4. Claude Sonnet 4.6 High prompt

    ```text
    Test the make-literate-tests skill by creating EXAMPLES.md.ml.u and running it. After running EXAMPLES.md.ml.u, the command responses should be compared to the original expect scripts in lib_test/expect.
    The goal is to have make-literate-tests be a skill that can be used on any project, not just this project.
    ```

   That created:

   - projectroot/dune
   - projectroot/re.opam (resulting from `dune build`)
   - projectroot/.vscode/settings.json (auto-approvals)
   - projectroot/EXAMPLES.md.ml.u (very incomplete though!)
   - ~~projectroot/EXAMPLES.md~~ (oddly did not create this!)
