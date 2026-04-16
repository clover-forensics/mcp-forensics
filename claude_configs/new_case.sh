#!/usr/bin/env bash
# Creates a new case after user creates "CASE" variable: "export CASE=xyz"
 
mkdir -p ~/cases/${CASE}/{analysis,exports,reports,logs,evidence}
cp ${HOME}/.claude/case-templates/CLAUDE.md ~/cases/${CASE}/
cp ${HOME}/.claude/analysis-scripts/generate_pdf_report.py ~/cases/${CASE}/analysis/
cp ${HOME}/.claude/hooks/ -r ~/cases/${CASE}/
rm ~/cases/${CASE}/hooks/.bash-post.sh.swp

