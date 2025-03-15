#SingleInstance, force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir ; Ensures a consistent starting directory.

global client_txt_file := ""
;Check version is compatible before we do anything else.
CheckAHKVersionCompatibility()

;Get some necessary functions.
#Include, %A_ScriptDir%\lib\JSON.ahk
#Include, %A_ScriptDir%\lib\Gdip.ahk

;Read some global variables from ini.
#Include, %A_ScriptDir%\lib\config.ahk
#Include, %A_ScriptDir%\lib\settings.ahk
#Include, %A_ScriptDir%\lib\sizing.ahk

;These handle the UI basically - displaying and updating.
#Include, %A_ScriptDir%\lib\draw.ahk
#Include, %A_ScriptDir%\lib\set.ahk
#Include, %A_ScriptDir%\lib\search.ahk

;Includes the application loop that is run through continuously.
#Include, %A_ScriptDir%\lib\class\ApplicationEngine.ahk

;self explanatory :)
#Include, %A_ScriptDir%\lib\hotkeys.ahk

;Initialise Global State
;constructor for this class includes all necessary initialisation
;TODO: Add gems to this object
;TODO: Add global settings? at least feature flag/options, eg shouldUpdate or whatever
;TODO: Currently I am relying on OverlayFolder being loaded in
;Candidates for global settings:
; - shouldUpdate
#Include, %A_ScriptDir%\lib\class\GlobalStateSingleton.ahk
projectRootDirectory := A_ScriptDir
global GlobalState := new GlobalStateSingleton(projectRootDirectory)
GlobalState.InitialiseClasses()

;Need to put this on GlobalState when I deal with gem setups.
global gem_data := {}
Try {
	FileRead, JSONFile, %A_ScriptDir%\lib\gems.json
	gem_data := JSON.Load(JSONFile)
	If (not gem_data.Length()) {
		MsgBox, 16, , Error reading gem Data! `n`nExiting script.
		ExitApp
	}
} Catch e {
	MsgBox, 16, , % e "`n`nNo Gem Data in \lib\gems.json"
	ExitApp
}

;Menu - shows when the tray icon is right clicked.
Menu, Tray, NoStandard
Menu, Tray, Tip, PoE Leveling Guide
Menu, Tray, Add, Settings, LaunchSettings
Menu, Tray, Add, Edit Build, LaunchBuild
Menu, Tray, Add
Menu, Tray, Add, Reload, PLGReload
Menu, Tray, Add, Close, PLGClose

;Icons
Menu, Tray, Icon, %A_ScriptDir%\icons\lvlG.ico
Menu, Tray, Icon, Settings, %A_ScriptDir%\icons\gear.ico
Menu, Tray, Icon, Reload, %A_ScriptDir%\icons\refresh.ico
Menu, Tray, Icon, Close, %A_ScriptDir%\icons\x.ico

global PoEWindowGrp
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExile.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExile_KG.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExile_EGS.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExileEGS.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExileSteam.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExile_x64.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExile_x64_KG.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExile_x64EGS.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExilex64EGS.exe
GroupAdd, PoEWindowGrp, Path of Exile ahk_class POEWindowClass ahk_exe PathOfExile_x64Steam.exe

;Check for updates
CheckForUpdates(skipUpdates)

;Get gems ready - download if the images aren't there and user says yes
LoadInGems()

;Get the PoE2 Window Handle
global PoEWindowHwnd := ""
WinGet, PoEWindowHwnd, ID, ahk_group PoEWindowGrp

;TODO: What does this do? Should this be a prop on GlobalState?
global onStartup := 1

DrawZone()
DrawTree()
DrawExp()

SetGuide()
SetNotes()
SetGems()
GlobalState.GetLevelTracker().UpdateExpTracker()

HideAllWindows()
ToggleLevelingGuide()

;This is the engine that actually runs the app - ShowGuiTimer handles all of the minute-by-minute processing in
;the application so we basically just run it over and over again.
SetTimer, RunEngine, 200, -100 ;Run every 200ms, thread priority -100
Return

;This needs to be a label so we can use SetTimer, but to have it in ApplicationEngine.ahk it has to be a function
;so that it doesn't run when we do the #Include. A label that calls the function is best solution I think
RunEngine:
	RunEngine()
Return

;========== Functions ==========

CheckAHKVersionCompatibility() {
	requiredVer := "1.1.30.03"
	unicodeOrAnsi := A_IsUnicode?"Unicode":"ANSI"
	32or64bits := A_PtrSize=4?"32bits":"64bits"
	If (!A_IsUnicode) {
		Run,% "https://www.autohotkey.com/"
		MsgBox,4096+48,"PoE Leveling Guide - Wrong AutoHotKey Version"
			, "/!\ PLEASE READ CAREFULLY /!\"
			. "`n"
			. "`n" "This application isn't compatible with ANSI versions of AutoHotKey."
			. "`n" "You are using v" A_AhkVersion " " unicodeOrAnsi " " 32or64bits
			. "`n" "Please download and install AutoHotKey Unicode 32/64"
			. "`n"
		ExitApp
	}
	If (A_AhkVersion < "1.1") ; Smaller than 1.1.00.00
		|| (A_AhkVersion < "1.1.00.00")
		|| (A_AhkVersion < requiredVer) { ; Smaller than required
		Run,% "https://www.autohotkey.com/"
		MsgBox,4096+48, "PoE Leveling Guide - AutoHotKey Version Too Low"
			, "/!\ PLEASE READ CAREFULLY /!\"
			. "`n"
			. "`n" "This application requires AutoHotKey v" requiredVer " or higher."
			. "`n" "You are using v" A_AhkVersion " " unicodeOrAnsi " " 32or64bits
			. "`n" "AutoHotKey website has been opened, please update to the latest version."
			. "`n"
		ExitApp
	}
	If (A_AhkVersion >= "2.0")
		|| (A_AhkVersion >= "2.0.00.00") { ; Higher or equal to 2.0.00.00
		Run,% "https://www.autohotkey.com/"
		MsgBox,4096+48, "PoE Leveling Guide - Wrong AutoHotKey Version"
			, "/!\ PLEASE READ CAREFULLY /!\"
			. "`n"
			. "`n" "This application isn't compatible with AutoHotKey v2."
			. "`n" "You are using v" A_AhkVersion " " unicodeOrAnsi " " 32or64bits
			. "`n" "AutoHotKey v" requiredVer " or higher is required."
			. "`n" "AutoHotKey website has been opened, please download the latest v1 version."
			. "`n"
		ExitApp
	}
}

CheckForUpdates(skipUpdates) {
	;User opted out of updates.
	If (skipUpdates = "True") {
		Return
	}

	;Check version stored in this project matches github repo.
	versionFile = %A_ScriptDir%\filelist.txt
	If (!FileExist(versionFile)) {
		updatePLG := "True"
		oldVersion := "0.0.0"
		UrlDownloadToFile, https://raw.githubusercontent.com/JusKillmeQik/PoE-Leveling-Guide/main/filelist.txt, %A_ScriptDir%\filelist.txt
	} Else {
		FileReadLine, oldVersion, %A_ScriptDir%\filelist.txt, 1
		UrlDownloadToFile, https://raw.githubusercontent.com/JusKillmeQik/PoE-Leveling-Guide/main/filelist.txt, %A_ScriptDir%\filelist.txt
		FileReadLine, newVersion, %A_ScriptDir%\filelist.txt, 1
		If (oldVersion != newVersion) {
			updatePLG := "True"
		} Else {
			updatePLG := "False"
		}
		If (newVersion = "404: Not Found") {
			updatePLG := "False"
		}
	}

	;No update available.
	If (updatePLG = "False" || updatePLG = "") {
		Return
	}

	;An update is available - prompt user to install. 4 => Yes/No options are given.
	MsgBox, 4,, % "You are running version " oldVersion " of the PoE Leveling Guide,`nversion " newVersion " is available, would you like to download it?`n`nTHIS COULD TAKE A FEW MINUTES!"

	;User declined to update. Do nothing.
	IfMsgBox No
		Return

	IfMsgBox, Yes
	{
		progressWidth := 200
		ignoreBuilds := "builds/"
		ignoreSeeds := "Seed_"
		Loop, read, %A_ScriptDir%\filelist.txt
		{
			If (A_Index = 1){
				;Do nothing
			} Else If (A_Index = 2){
				progressWidth := A_LoopReadLine
				If progressWidth is not integer
					Break
				Progress, b w200, Please don't stop the download until complete, Updating Script
			} Else {
				flippedSlashes := StrReplace(A_LoopReadLine, "/", "\")
				updateFile = %A_ScriptDir%\%flippedSlashes%
				lastSlashPos := InStr(updateFile,"\",0,0)
				downloadDirName := SubStr(updateFile,1,lastSlashPos-1)
				If ( InStr(A_LoopReadLine,ignoreBuilds) || InStr(A_LoopReadLine,ignoreSeeds) ){
					If (!FileExist(updateFile)) { ; Only download builds and seed images if they don't already exist
						FileCreateDir, %downloadDirName%
						UrlDownloadToFile, https://raw.githubusercontent.com/JusKillmeQik/PoE-Leveling-Guide/main/%A_LoopReadLine%, %updateFile%
					}
				} Else {
					If (!FileExist(updateFile)) { ; If the file doesn't exist make sure to create the directory
						FileCreateDir, %downloadDirName%
					}
					UrlDownloadToFile, https://raw.githubusercontent.com/JusKillmeQik/PoE-Leveling-Guide/main/%A_LoopReadLine%, %updateFile%
				}
				progressPercent := 100 * (A_Index/progressWidth)
				Progress, %progressPercent%
			}
		}
		Progress, Off
		Return
	}

	;If we made it this far something went wrong - potentially a timeout?
	MsgBox, 16, , Error checking for updates! `n`nExiting script.
	ExitApp
}

LoadInGems() {
	global gemList := Object()
	global filterList := [" None"]
	If (skipGemImages = "False") {
		downloadApproved := "None"
	} Else {
		downloadApproved := "False"
	}
	progressWidth := gem_data.length()

	For key, someGem in gem_data {
		gemList[gemList.length()+1] := Object()
		gemList[gemList.length()].name := someGem.name
		tempColor := someGem.color
		gemList[gemList.length()].color := %tempColor%Color ;Use the settings color
		gemList[gemList.length()].cost := someGem.cost
		gemList[gemList.length()].vendor := someGem.vendor
		gemList[gemList.length()].lvl := someGem.required_lvl
		gemList[gemList.length()].url := "" "\images\gems\" someGem.name ".png"  ""

		image_file := "" A_ScriptDir "\images\gems\" someGem.name ".png"  ""
		icon_url := someGem.iconPath
		If (!FileExist(image_file) and icon_url!="") {
			If (downloadApproved = "True") {
				UrlDownloadToFile, %icon_url%, %image_file%
				progressPercent := 100 * (A_Index/progressWidth)
				Progress, %progressPercent%
			} Else If (downloadApproved = "False") {
				;do nothing
			} ;Else { ;commenting this for now because no I do not want to download POE1 gems in my POE2 overlay
			;MsgBox, 3,, You are missing some gem image files,`nwould you like to download them?`n`nTHIS COULD TAKE A FEW MINUTES!
			;IfMsgBox Yes
			;{
			;  downloadApproved := "True"
			;  UrlDownloadToFile, %icon_url%, %image_file%
			;  Progress, b w%progressWidth%, Please don't stop the download until complete, Downloading Gem Images
			;  progressPercent := 100 * (A_Index/progressWidth)
			;  Progress, %progressPercent%
			;} Else IfMsgBox No
			;{
			;  downloadApproved := "False"
			;} Else {
			;  ExitApp
			;}
			;}
		}
	}
	Progress, Off
}

PLGReload:
	Reload

PLGClose:
ExitApp