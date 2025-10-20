# iCeBox Backup Tool
A free, ultra simple, no-nonsense tool for backing up your files locally, with enough customization options for many different use cases.

## Features

![Screenshot of the iCeBox interface](https://i.imgur.com/8IMO5eq.png)

- Simple, easy to understand interface
- Back up multiple folders at once, and preview their combined size
- Set certain programs to close before starting your backup
- All backups are dated with a YYYY-MM-DD prefix for easy sorting
- Configure one-click backups that can even run silently in the background
- No built-in backup scheduling, but still perfect for setting up automatic backups with something like Task Scheduler
- Failed backups recorded in a log.txt file in the backup directory

[**Download the latest release here**](https://github.com/iCeParadox64/iCeBox-Backup-Tool/releases/latest)

If you make regular backups (which you should!) to the same drives, I recommend using a program like [AllDup](https://alldup.info/) to get rid of duplicates from older backups and save space.

## config.ini Guide

This config file will be automatically generated when you run the program for the first time, and can be edited in any simple text editor.

- `BackupDirectory=` - If this is set to a valid folder path, backups will be saved to that folder, rather than have you individually choose every time you create a backup.
- `BackupName=` - If you want all your backups to have the same name, you can set it here. Backup folders will still have the date prefix.
- `BackupAllFolders=false` - If this is set to `true`, ALL folders you've added will be backed up, skipping the checklist window entirely.
- `SilentBackup=false` - If this is set to `true`, the final "Are you sure?" and "Backup complete!" popups will not trigger. This is meant to be used alongside all the other settings to allow for one-click silent backups.

- `[FoldersToBackup]` - The list of folders to back up, one folder path per line. Can be added manually, or with the "Add Folder" button in the program window.
- `[ProgramsToKill]` - A list of programs that the script will automatically close before starting the backup, one program per line. Example list entries: `Discord.exe` / `OneDrive.exe` / `steam.exe`

____


*Program icon by Freepik on Flaticon.com*

