This directory holds the relevant configuration and supplemental files used to capture bash commands and create the environments for a new case. 
With the exception of the "hooks/" directory and its contents, all other directories and files within ".claude/" are derived from the Claude installation on the Workstation. 

Description of modifications: 

"new-case.sh"
This file creates the environment to start a new case. The user must first create a "CASE" variable with the following command: "export CASE=<case_name>"
After the CASE variable is set up, executing this script will:
    - Copy the template CLAUDE.md file included in the Claude installation to your case folder
    - Copy the generate_pdf_report.py file included in the Claude installation to your case folder
    - Copy the hooks/ directory with the "bash-post.sh" template file that allows a user to enter their artifact names and mounting names so that a separate log file would be created per arttifact being analyzed. By default, it will collect all of the commands that Claude runs, but this script can help separate the steps taken for each artifact. 
    - Removes the .swp file that is automatically copied with the bash-post.sh file. If not removed, the user faces issues with modifying the script. 

"settings.json"
The default settings from the installation were kept. However, this file includes a PostToolUse hook that captures only the commands that Claude ran. Each bash command run by Claude invokes the bash-post.sh script that is in the respective case folder, which will then be added to the log file it belongs to. 

"bash-post.sh"
This file is stored in each case folder to capture the bash commands for the specific case. It logs every command ran per evidence file for reproducibility purposes, but requires users to input the file names, with and without its extension, as well as the mounting points that the user lists in the CLAUDE.md file. Note: the CASE variable must be set to the name of the directory where the case files are being stored, so that the PostToolUse hook can direct the logs in the appropriate log file(s).
