ls /home/sansforensics/cases/CORPUS/analysis/ 2>/dev/null && echo "---" && ls /home/sansforensics/cases/CORPUS/exports/ 2>/dev/null && echo "---" && ls /home/sansforensics/cases/CORPUS/reports/ 2>/dev/null && echo "---" && ls /home/sansforensics/cases/CORPUS/logs_backup/ 2>/dev/null && echo "---" && ls /home/sansforensics/cases/CORPUS/ground_truth/ 2>/dev/null
cat /home/sansforensics/cases/CORPUS/ground_truth/corpus-report.txt
cat /home/sansforensics/cases/CORPUS/reports/file_carving_report.md
cat /home/sansforensics/cases/CORPUS/logs_backup/Canon2-Gen6_commands.sh && echo "===" && cat /home/sansforensics/cases/CORPUS/logs_backup/all_commands.sh && echo "===" && cat /home/sansforensics/cases/CORPUS/logs_backup/unknownFile_commands.sh
ls /home/sansforensics/cases/CORPUS/exports/files/ 2>/dev/null && echo "---" && ls /home/sansforensics/cases/CORPUS/exports/carved/ 2>/dev/null && echo "---" && ls /home/sansforensics/cases/CORPUS/exports/photorec/ 2>/dev/null && echo "---" && ls /home/sansforensics/cases/CORPUS/exports/tsk_recover/ 2>/dev/null
mkdir -p /home/sansforensics/cases/CORPUS/trustworthiness && echo "Created"
