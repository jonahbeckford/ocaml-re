#!/bin/sh
set -euf
# Claude uses .claude/skills. Everybody else can use .agents/skills.
# Do not bother with symlinking. It has poor support on Windows+git.
cp .claude/skills/make-literate-tests/SKILL.md .agents/skills/make-literate-tests/SKILL.md