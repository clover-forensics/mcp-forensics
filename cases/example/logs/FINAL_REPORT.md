# Forensic investigation report

## User query

Recover deleted text files from the ext image and extract the secret password

## Case folder

`/app/cases/example`

## Outcome

- **Finish reason:** `completed`

## Findings summary

The deleted file `strings.txt` was recovered from the ext4 image located at `/app/cases/example/disk.img` into the `/app/cases/example/recovered_files` directory. The secret password found within this file is '1234', on line 23: 'password is 1234'.

## Step overview

1. **tsk_mmls** — To recover deleted files, I first need to understand the disk's partition layout and file system type. `tsk_mmls` will provide this information, specifically the sector offset and file system type for any partitions.
2. **tsk_fsstat** — My previous attempt to use `tsk_mmls` failed, indicating that the disk image might not have a partition table or is a raw filesystem image. I will try `tsk_fsstat` directly on the image to identify the filesystem type, which is necessary before listing or recovering files.
3. **tsk_fls** — Now that I've identified the filesystem as Ext4, I will list all deleted files on the image using `tsk_fls` to identify potential targets for recovery. I will specify `deleted_only=true` to narrow down the results.
4. **tsk_icat** — I have identified a deleted file `strings.txt` with inode 15. Now I will use `tsk_icat` to recover its content to a temporary location to then search for the secret password.
5. **tsk_icat** — My previous attempt to use `tsk_icat` failed due to an incorrect type for the 'inode' argument. I will retry `tsk_icat` using the correct string type for inode '15' to recover the content of `strings.txt`.
6. **tsk_recover** — My previous attempt with `tsk_icat` retrieved the file content but didn't save it to a host-accessible file. To properly 'recover' the deleted text file for further analysis, I will use `tsk_recover` to extract all possible files (including deleted ones) into the designated `recovered_files` directory.
7. **ls_path** — I have successfully recovered files into the `recovered_files` directory. Now I need to list the contents of this directory to locate the `strings.txt` file (or any other relevant text file) that might contain the secret password.
8. **grep_path** — I have recovered `strings.txt` and confirmed its presence. Now I will search this file for the 'secret password' using `grep_path` to extract the requested information.

## Log files

- `investigation_steps.jsonl` — full step records and tool output
- `FINAL_REPORT.md` — this report
