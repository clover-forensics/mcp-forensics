#!/usr/bin/env bash
# PostToolUse - logs every command ran per evidence file for reproducibility purposes

CASE_DIR="$HOME/cases/${CASE:-default}"
LOG_DIR="$CASE_DIR/logs"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

echo "$COMMAND" >> "$LOG_DIR/all_commands.sh"

EVIDENCE_FILES=(
    "nps-2009-canon2-gen6.E01"
    "nps-2009-canon2-gen6"
    "ewf_cg6"
    "mnt/cg6"
)

FOUND=false
for file in "${EVIDENCE_FILES[@]}"; do 
    if echo "$COMMAND" | grep -q "$file"; then
	case "$file" in 
	    "nps-2009-canon2-gen6.E01"|"nps-2009-canon2-gen6"|"ewf_cg6"|"mnt/cg6")
	    	IMAGE_NAME="Canon2-Gen6"
	    	;;
	esac
	echo "$COMMAND" >> "$LOG_DIR/${IMAGE_NAME}_commands.sh"
	FOUND=true
	break
    fi
done


if [ "$FOUND" = false ]; then
	echo "$COMMAND" >> "$LOG_DIR/unknownFile_commands.sh"
fi

exit 0
