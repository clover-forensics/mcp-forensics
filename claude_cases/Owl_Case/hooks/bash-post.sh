#!/usr/bin/env bash
# PostToolUse - logs every command ran per evidence file for reproducibility purposes

CASE_DIR="$HOME/cases/${CASE:-default}"
LOG_DIR="$CASE_DIR/logs"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

echo "$COMMAND" >> "$LOG_DIR/all_commands.sh"

EVIDENCE_FILES=(
    "HD1.E01"
    "HD1"
    "ewf_hd1"
    "mnt/hd1"
    "LGE_Nexus_5_Full_Image.raw"
    "LGE_Nexus_5_Full_Image"
    "mnt/ln5"
)

FOUND=false
for file in "${EVIDENCE_FILES[@]}"; do 
    if echo "$COMMAND" | grep -q "$file"; then
	case "$file" in 
	    "HD1.E01"|"HD1"|"ewf_hd1"|"mnt/hd1")
	    	IMAGE_NAME="HD1"
	    	;;
	    "LGE_Nexus_5_Full_Image.raw"|"mnt/ln5")
	       	IMAGE_NAME="LGE_Nexus5"
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
