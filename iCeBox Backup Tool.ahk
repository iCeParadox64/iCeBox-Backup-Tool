; Script written in AutoHotkey v1

#NoEnv
SetBatchLines -1
Menu, Tray, Icon, %A_ScriptDir%\iCeBox.ico
ConfigFile := A_ScriptDir . "\config.ini"

; Variables to store window position
global GuiX := ""
global GuiY := ""

; Create config.ini if it doesn't exist
if (!FileExist(ConfigFile)) {
    File := FileOpen(ConfigFile, "w")
    File.Write("[Settings]`n; Set the location your backups will be saved to, and skip the program asking you every time.`nBackupDirectory=`n`n; Set a name for your backups, and skip the program asking you every time. The folder name will still be preceded by the date.`nBackupName=`n`n; If true, skip folder selection and instead back up ALL folders in the list.`nBackupAllFolders=false`n`n; If true, skips all confirmation and completion popups. Meant to be used with all of the above settings to allow for backups to run completely silently in the background.`nSilentBackup=false`n`n[FoldersToBackup]`n; One folder path per line. A list of folders to back up.`n`n[ProgramsToKill]`n; One program.exe per line. A list of .exe programs to kill before starting the backup.`n")
    File.Close()
}

; Load existing folders list from config
FileRead, ConfigContent, %ConfigFile%
FolderList := []
InSection := false

Loop, Parse, ConfigContent, `n
{
    Line := A_LoopField
    ; Skip comment lines
    if (SubStr(Line, 1, 1) = ";") {
        continue
    }
    
    if (Line = "[FoldersToBackup]") {
        InSection := true
        continue
    }
    
    if (InSection && SubStr(Line, 1, 1) = "[") {
        break
    }
    
    if (InSection && Line != "") {
        FolderList.Push(Line)
    }
}

; Check if BackupAllFolders is enabled
IniRead, BackupAllFolders, %ConfigFile%, Settings, BackupAllFolders, false
if (BackupAllFolders = "true") {
    ; Select all folders and start backup
    SelectedFolders := FolderList
    Goto, PerformBackup
}

; Create main GUI window
BuildGUI:
; Save current window position before destroying (refreshing)
WinGetPos, GuiX, GuiY, , , iCeBox Backup Tool
Gui, Destroy
Gui, Add, Button, x420 y10 w80 h30 gAddFolder, Add Folder
Gui, Add, Button, x420 y50 w80 h30 gRemoveSelected, Remove Selected

; Create checkboxes for each folder, or show help text if no folders
if (FolderList.Length() = 0) {
    Gui, Add, Text, x10 y20 w400 h160, This is where your selected folders will appear as a checklist. You can add as many`nfolders as desired by either clicking the "Add Folder" button, or by manually editing`nthe config.ini file. Once added, you can select any number of them to back up.`n`nMake sure to have a look at the config.ini file for other settings you may find useful!`n`n`n`n`nNOTE: Program may hang after clicking "Start Backup" depending on backup size.
} else {
    y := 5
    Loop, % FolderList.Length() {
        FolderPath := FolderList[A_Index]
        DisplayPath := StrReplace(FolderPath, "&", "&&")
        Gui, Add, CheckBox, x10 y%y% w400 h26 vFolder%A_Index%, %DisplayPath%
        y += 26
    }
}

; Dynamically scale window height for more than six folders
FolderCount := FolderList.Length()
if (FolderCount > 6) {
    ExtraFolders := FolderCount - 6
    DynamicHeight := 165 + (ExtraFolders * 26)
} else {
    DynamicHeight := 165
}
StartBackupY := DynamicHeight - 40

Gui, Add, Button, x420 y%StartBackupY% w80 h30 gStartBackup, Start Backup

; Show GUI at saved position or default position
if (GuiX != "" && GuiY != "") {
    Gui, Show, w520 h%DynamicHeight% x%GuiX% y%GuiY%, iCeBox Backup Tool
} else {
    Gui, Show, w520 h%DynamicHeight%, iCeBox Backup Tool
}

return

AddFolder:
    FileSelectFolder, SelectedFolder, , 1, Select a folder to backup:
    if (SelectedFolder) {
        ; Read the config file and add the folder directly under [FoldersToBackup]
        FileRead, ConfigContent, %ConfigFile%
        
        ; Check if folder already exists
        if (InStr(ConfigContent, SelectedFolder)) {
            MsgBox, This folder is already in the backup list.
            return
        }
        
        ; Add folder path to the bottom of [FoldersToBackup] section
        FoldersToBackupPos := InStr(ConfigContent, "[FoldersToBackup]")
        if (FoldersToBackupPos) {
            NextSectionPos := InStr(ConfigContent, "`n[", false, FoldersToBackupPos + 1)
            if (NextSectionPos) {
                ; Insert before the next section
                ConfigContent := SubStr(ConfigContent, 1, NextSectionPos - 1) . SelectedFolder . "`n" . SubStr(ConfigContent, NextSectionPos)
            } else {
                ; Add to the end of file
                ConfigContent .= SelectedFolder . "`n"
            }
        }
        
        ; Write back to config
        File := FileOpen(ConfigFile, "w")
        File.Write(ConfigContent)
        File.Close()
        
        ; Reload folders and refresh checklist window
        FileRead, ConfigContent, %ConfigFile%
        FolderList := []
        InSection := false
        
        Loop, Parse, ConfigContent, `n
        {
            Line := A_LoopField
            if (SubStr(Line, 1, 1) = ";") {
                continue
            }
            
            if (Line = "[FoldersToBackup]") {
                InSection := true
                continue
            }
            
            if (InSection && SubStr(Line, 1, 1) = "[") {
                break
            }
            
            if (InSection && Line != "") {
                FolderList.Push(Line)
            }
        }
        
        Goto, BuildGUI
    }
return

RemoveSelected:
    MsgBox, 4, Confirm Removal, Are you sure you want to remove the selected folder(s) from the list?
    IfMsgBox, No
        return
    
    ; User clicked Yes, proceed with removal
    FileRead, ConfigContent, %ConfigFile%
    
    ; Load folders from config
    FolderList := []
    InSection := false
    
    Loop, Parse, ConfigContent, `n
    {
        Line := A_LoopField
        ; Skip comment lines
        if (SubStr(Line, 1, 1) = ";") {
            continue
        }
        
        if (Line = "[FoldersToBackup]") {
            InSection := true
            continue
        }
        
        if (InSection && SubStr(Line, 1, 1) = "[") {
            break
        }
        
        if (InSection && Line != "") {
            FolderList.Push(Line)
        }
    }
    
    ; Check which folders are selected and remove them
    FoldersToRemove := []
    Loop, % FolderList.Length() {
        GuiControlGet, isChecked, , Folder%A_Index%
        if (isChecked) {
            FoldersToRemove.Push(FolderList[A_Index])
        }
    }
    
    ; Remove selected folders from config
    Loop, % FoldersToRemove.Length() {
        FolderToRemove := FoldersToRemove[A_Index]
        ConfigContent := StrReplace(ConfigContent, FolderToRemove . "`n", "")
    }
    
    ; Write back to config
    File := FileOpen(ConfigFile, "w")
    File.Write(ConfigContent)
    File.Close()
    
    ; Reload folders and refresh GUI to show changes
    FileRead, ConfigContent, %ConfigFile%
    FolderList := []
    InSection := false
    
    Loop, Parse, ConfigContent, `n
    {
        Line := A_LoopField
        if (SubStr(Line, 1, 1) = ";") {
            continue
        }
        
        if (Line = "[FoldersToBackup]") {
            InSection := true
            continue
        }
        
        if (InSection && SubStr(Line, 1, 1) = "[") {
            break
        }
        
        if (InSection && Line != "") {
            FolderList.Push(Line)
        }
    }
    
    Goto, BuildGUI
return

StartBackup:
    ; Get selected folders
    SelectedFolders := []
    Loop, % FolderList.Length() {
        GuiControlGet, isChecked, , Folder%A_Index%
        if (isChecked) {
            SelectedFolders.Push(FolderList[A_Index])
        }
    }
    
    if (SelectedFolders.Length() = 0) {
        MsgBox, Please select at least one folder to back up.
        return
    }

PerformBackup:
    ; Calculate total size
    TotalSize := 0
    Loop, % SelectedFolders.Length() {
        FolderPath := SelectedFolders[A_Index]
        TotalSize += GetFolderSize(FolderPath)
    }
    
    ; Convert size to GB
    TotalSizeGB := TotalSize / (1024 * 1024 * 1024)
    TotalSizeGB := Format("{:.2f}", TotalSizeGB)
    
    ; Check BackupDirectory setting
    IniRead, BackupDir, %ConfigFile%, Settings, BackupDirectory, 
    
    if (BackupDir = "" || !FileExist(BackupDir)) {
        ; BackupDirectory is empty or invalid, ask user to select
        FileSelectFolder, BackupDir, , 1, Select backup destination directory:
        if (!BackupDir) {
            MsgBox, No backup directory selected. Backup cancelled.
            return
        }
    }
    
    ; Get backup name from config, or ask user to input one
    IniRead, BackupName, %ConfigFile%, Settings, BackupName
    if (BackupName = "" || BackupName = "ERROR") {
        InputBox, BackupName, , Enter a name for this backup:, Backup Name, 400, 130
        if (ErrorLevel) {
            MsgBox, Backup cancelled.
            return
        }
        
        if (BackupName = "") {
            MsgBox, Backup name cannot be empty. Backup cancelled.
            return
        }
    }
    
    ; Create folder name with date prefix (folder itself isn't created yet tho)
    FormatTime, CurrentDate, , yyyy-MM-dd
    BackupFolderName := CurrentDate . " " . BackupName
    BackupFolderPath := BackupDir . "\" . BackupFolderName
    
    ; Build folder list for display
    FolderListText := ""
    Loop, % SelectedFolders.Length() {
        FolderListText .= SelectedFolders[A_Index] . "`n"
    }
    
    ; Show confirmation popup unless SilentBackup is true
    IniRead, SilentBackup, %ConfigFile%, Settings, SilentBackup, false
    if (SilentBackup != "true") {
        ConfirmMessage := "Backup will be created in: " . BackupFolderPath . "`nTotal size: " . TotalSizeGB . "GB`nFolders to back up:`n" . FolderListText
        MsgBox, 1, Confirm Backup, %ConfirmMessage%
        IfMsgBox, Cancel
            return
    }
    
    ; NOW create the backup folder
    FileCreateDir, %BackupFolderPath%
    if (ErrorLevel) {
        MsgBox, Failed to create backup folder. Backup cancelled.
        return
    }
    
    ; Show final confirmation popup unless SilentBackup is true
    if (SilentBackup != "true") {
        MsgBox, Press OK to begin backup. This may take some time.
    }
    
    ; Kill all processes in ProgramsToKill
    FileRead, ConfigContent, %ConfigFile%
    ProgramsList := []
    InSection := false
    
    Loop, Parse, ConfigContent, `n
    {
        Line := A_LoopField
        ; Skip comment lines
        if (SubStr(Line, 1, 1) = ";") {
            continue
        }
        
        if (Line = "[ProgramsToKill]") {
            InSection := true
            continue
        }
        
        if (InSection && SubStr(Line, 1, 1) = "[") {
            break
        }
        
        if (InSection && Line != "") {
            ProgramsList.Push(Line)
        }
    }
    
    Loop, % ProgramsList.Length() {
        ProgramName := ProgramsList[A_Index]
        
        ; KILL THEM ALL
        Loop {
            Process, Exist, %ProgramName%
            if (!ErrorLevel)
                break
            Process, Close, %ProgramName%
            Sleep, 100
        }
    }
    
    ; Copy all selected folders to backup location
    Loop, % SelectedFolders.Length() {
        SourceFolder := SelectedFolders[A_Index]
        FolderName := SubStr(SourceFolder, InStr(SourceFolder, "\", false, 0) + 1)
        DestFolder := BackupFolderPath . "\" . FolderName
        
        ErrorCount := CopyFilesAndFolders(SourceFolder . "\*.*", DestFolder)
        if (ErrorCount != 0)
            MsgBox %ErrorCount% files/folders could not be copied from %SourceFolder%.
    }
    
    ; Check if SilentBackup is enabled
    if (SilentBackup != "true") {
        MsgBox, Backup completed successfully!
    } else {
        ExitApp
    }
return

GuiMove:
    WinGetPos, GuiX, GuiY
return

GuiClose:
    ExitApp
return

GetFolderSize(FolderPath) {
    Size := 0
    Loop, Files, %FolderPath%\*, R
    {
        FileGetSize, FileSize, %A_LoopFileFullPath%
        Size += FileSize
    }
    return Size
}

CopyFilesAndFolders(SourcePattern, DestinationFolder, DoOverwrite = false)
{
    FileCreateDir, %DestinationFolder%
    FileCopy, %SourcePattern%, %DestinationFolder%, %DoOverwrite%
    ErrorCount := ErrorLevel
    Loop, %SourcePattern%, 2
    {
        DestPath := DestinationFolder . "\" . A_LoopFileName
        FileCopyDir, %A_LoopFileFullPath%, %DestPath%, %DoOverwrite%
        ErrorCount += ErrorLevel
        if ErrorLevel
            MsgBox Could not copy %A_LoopFileFullPath% into %DestinationFolder%.
    }
    return ErrorCount
}