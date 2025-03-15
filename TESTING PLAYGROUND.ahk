power := 10 ** 2
MsgBox, power

#Include, %A_ScriptDir%\lib\config.ahk ;rely on this to load overlayFolder global var
#Include, %A_ScriptDir%\lib\class\GlobalStateSingleton.ahk
global GlobalState := new GlobalStateSingleton(%A_ScriptDir%)
global GlobalState.SetOverlayFolder("0.1.0 Lightning Arrow Deadeye")

INIMeta = Format("{1}\builds\{2}\meta.ini", GlobalState.GetProjectRootDirectory(), GlobalState.GetOverlayFolder())
IniRead, CurrentPartNumber, %INIMeta%, State, CurrentPartNumber, %CurrentPartNumber%

CurrentPartNumber := CurrentPartNumber