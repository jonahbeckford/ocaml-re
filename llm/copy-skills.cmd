@echo off
REM Claude uses .claude/skills. Everybody else can use .agents/skills.
REM Do not bother with symlinking. It has poor support on Windows+git.

if not exist ".agents\skills\make-literate-tests" mkdir ".agents\skills\make-literate-tests"
copy /Y ".claude\skills\make-literate-tests\SKILL.md" ".agents\skills\make-literate-tests\SKILL.md"
