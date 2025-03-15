RunEngine() {
    poe_active := WinActive("ahk_id" PoEWindowHwnd)
    controls_active := WinActive("ahk_id" . Controls) ; Wow that dot is important!
    level_active := WinActive("ahk_id" . Level)
    gems_active := WinActive("ahk_id" . Gems)

    If (activeCount <= displayTimeout) {
        If (activeCount = 0) {
            activeTime := A_Now
        }
        active_toggle := 1
        If (!controls_active) {
            activeCount := A_Now - activeTime
            If (activeCount = 0) {
                activeCount := 1
            }
        }
    } Else if (activeCount > displayTimeout and active_toggle) {
        HideAllWindows()
        active_toggle := 0
    }

    If (controls_active or displayTimeout=0) {
        activeCount := 0
        active_toggle := 1
    }

    If (poe_active or controls_active or level_active or gems_active) {
        ; show all gui windows
        ShowAllWindows()
        Sleep 500
    } Else {
        HideAllWindows()
        ;Reset activity upon return
        activeCount := 0
        active_toggle := 1
    }

    ;Loop breaks if there is a running POE window and after client.txt is dumped if it is excessive in size.
    While true
    {
        ;TODO: Wanted to make this a region but it should probably just be a function. :(
        ;region - Look for a running Path Of Exile window
        ;The PoEWindow doesn't stay active through a restart, so must wait for it to be open
        closed := 0

        Process, Exist, PathOfExile.exe
        If(!errorlevel) {
            closed++
        } Else {
            client := GetProcessPath( "PathOfExile.exe" )
            StringTrimRight, client, client, 15
            client .= "logs\Client.txt"
        }

        Process, Exist, PathOfExileSteam.exe
        If(!errorlevel) {
            closed++
        } Else {
            client := GetProcessPath( "PathOfExileSteam.exe" )
            StringTrimRight, client, client, 20
            client .= "logs\Client.txt"
        }

        Process, Exist, PathOfExile_KG.exe
        If(!errorlevel) {
            closed++
        } Else {
            client := GetProcessPath( "PathOfExile_KG.exe" )
            StringTrimRight, client, client, 18
            client .= "logs\KakaoClient.txt"
        }

        Process, Exist, PathOfExile_EGS.exe
        If(!errorlevel) {
            closed++
        } Else {
            client := GetProcessPath( "PathOfExile_EGS.exe" )
            StringTrimRight, client, client, 19
            client .= "logs\Client.txt"
        }

        Process, Exist, PathOfExileEGS.exe
        If(!errorlevel) {
            closed++
        } Else {
            client := GetProcessPath( "PathOfExileEGS.exe" )
            StringTrimRight, client, client, 18
            client .= "logs\Client.txt"
        }

        Process, Exist, PathOfExile_x64.exe
        If(!errorlevel) {
            closed++
        } Else {
            client := GetProcessPath( "PathOfExile_x64.exe" )
            StringTrimRight, client, client, 19
            client .= "logs\Client.txt"
        }

        Process, Exist, PathOfExile_x64Steam.exe
        If(!errorlevel) {
            closed++
        } Else {
            client := GetProcessPath( "PathOfExile_x64Steam.exe" )
            StringTrimRight, client, client, 24
            client .= "logs\Client.txt"
        }

        Process, Exist, PathOfExile_x64_KG.exe
        If(!errorlevel) {
            closed++
        } Else {
            client := GetProcessPath( "PathOfExile_x64_KG.exe" )
            StringTrimRight, client, client, 22
            client .= "logs\KakaoClient.txt"
        }

        Process, Exist, PathOfExile_x64EGS.exe
        If(!errorlevel) {
            closed++
        } Else {
            client := GetProcessPath( "PathOfExile_x64EGS.exe" )
            StringTrimRight, client, client, 22
            client .= "logs\Client.txt"
        }

        Process, Exist, PathOfExilex64EGS.exe
        If(!errorlevel) {
            closed++
        } Else {
            client := GetProcessPath( "PathOfExilex64EGS.exe" )
            StringTrimRight, client, client, 21
            client .= "logs\Client.txt"
        }
        ;endregion

        ;if closed = 10 there are no running poe windows
        If (closed = 10){
            HideAllWindows()
            ;Sleep 10 seconds, no need to keep checking this
            Sleep 10000
            ;Reset activity upon return
            activeCount := 0
            active_toggle := 1
        } Else {
            If (onStartup) {
                ;save client variable to compare in the future if the client.exe changed and thus the client.txt needs to be reread
                old_client_txt_path := client
                ;TODO I just commented this and hoped for the best I should double check this is not necessary
                ;InitLogFile(client)
                ;I think this works?
                GlobalState.GetClientReader().SetClientTxtFilepath(client)

                ;Delete Client.txt on startup so we don't have to read a HUGE file!
                FileGetSize, clientSize, %client%, K  ; Retrieve the size in Kbytes.
                If(clientSize > 100000){
                    MsgBox, 1,, Your %client% is over 100Mb and will be deleted to speed up this script. Feel free to Cancel and rename the file if you want to keep it, but deletion will not affect the game at all.
                    IfMsgBox Ok
                    {
                        file := FileOpen(client, "w")
                        If IsObject(file) {
                            file.Close()
                        }
                    }
                }
                onStartup := 0
            }
            ;after startup check if new client_txt_path is different from old_client_txt_path (changed launcher)
            if ((old_client_txt_path != client) and (closed != 8)){
                old_client_txt_path := client
                ;TODO yeah also just commented this. this may actually be necessary since it basically globally
                ;set a new filepath and a new client file, I need to have some handling of this somewhere.
                ;InitLogFile(client)
                ;I think this works?
                GlobalState.GetClientReader().SetClientTxtFilepath(client)
            }
            WinGet, PoEWindowHwnd, ID, ahk_group PoEWindowGrp
            break
        }
    } ;End While

    ;Magic
    SearchLog()

    return
}

;Obsolete - replaced this with a method on GlobalState.
;The delay between set pointer to end, wait, read file somewhere else, wait, set pointer to end
;was basically missing lines.
InitLogFile(filepath) {
    ;Set the pointer to end of file
    client_txt_file := FileOpen(filepath,"r")
    client_txt_file.Seek(0,2) ;skip file pointer to end (Origin = 2 -> end of file, distance 0 => end)
    global log := client_txt_file.Read() ; should be empty now and redundant
}

;TODO why is this here? there should probably be a GUI controller class, then I don't have to have
;TODO all the gui update methods spread out all over the project. Would make hotkeys easier to deal with probably
ShowAllWindows() {
    If (LG_toggle and active_toggle) {
        Gui, Controls:Show, NoActivate
    }
    controls_active := WinActive("ahk_id" Controls)
    If (LG_toggle and !controls_active and (active_toggle or persistText = "True")) {
        Gui, Guide:Show, NoActivate
        If (numPart = 3) {
            Gui, Atlas:Show, NoActivate
        } Else {
            Gui, Atlas:Cancel
        }
        Gui, Notes:Show, NoActivate
    } Else If (!controls_active) {
        Gui, Notes:Cancel
        Gui, Atlas:Cancel
        Gui, Guide:Cancel
    }

    If (zone_toggle) {
        ;UpdateImages()
        Loop, % maxImages {
            Gui, Image%A_Index%:Show, NoActivate
        }
    } else {
        Loop, % maxImages {
            Gui, Image%A_Index%:Cancel
        }
    }

    If (tree_toggle or atlas_toggle) {
        Gui, Tree:Show, NoActivate
    } Else If (level_toggle) {
        Gui, Level:Show, NoActivate
        Gui, Exp:Show, NoActivate
        ;SetExp()
    }

    If (gems_toggle) {
        Gui, Gems:Show, NoActivate
        Gui, Links:Show, NoActivate

        For k, someControl in controlList {
            If (%someControl%image){
                Gui, Image%someControl%:Show, NoActivate
            }
        }
    }
    return
}

HideAllWindows() {
    Gui, Controls:Cancel
    Gui, Level:Cancel
    Gui, Exp:Cancel

    Loop, % maxImages {
        Gui, Image%A_Index%:Cancel
    }

    For k, someControl in controlList {
        Gui, Image%someControl%:Cancel
    }

    Gui, Notes:Cancel
    Gui, Atlas:Cancel
    Gui, Guide:Cancel

    Gui, Tree:Cancel
    Gui, Gems:Cancel
    Gui, Links:Cancel
    return
}

GetProcessPath(exe) {
    for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where name ='" exe "'")
        return process.ExecutablePath
}