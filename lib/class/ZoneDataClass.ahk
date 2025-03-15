;Stores zone data
Class ZoneDataClass {

    __New(){
        ;ZoneReference is loaded from ZoneReference.json, it is basically an object that contains all the parts,
        ;acts, zones, and most importantly zone codes in the game.
        This.ZoneReference := ReadReferenceDataFromJSON()

        ;default state
        This.CurrentPartNumber := 1
        This.CurrentPart := "Part 1"
        This.CurrentAct := "Act 1"
        This.CurrentZone := "The Riverbank"
        This.LastLogLines := "Generating level 1 area ""G1_1"""

        INIMeta = Format("{1}\builds\{2}\meta.ini", GlobalState.GetProjectRootDirectory(), GlobalState.GetOverlayFolder())
        IniRead, CurrentPartNumber, %INIMeta%, State, CurrentPartNumber, %CurrentPartNumber%
        IniRead, CurrentPart, %INIMeta%, State, CurrentPart, %CurrentPart%
        IniRead, CurrentAct, %INIMeta%, State, CurrentAct, %CurrentAct%
        IniRead, CurrentZone, %INIMeta%, State, CurrentZone, %CurrentZone%
        IniRead, LastLogLines, %INIMeta%, State, LastLogLines, %LastLogLines%

        ;Save the state read from ini. If the ini just has blank values (not a blank ini, it has keys but no values)
        ;then we will just stick to the defaults. This may end up giving invalid part/act/zone combo but uh we'll
        ;figure that out later.
        This.CurrentPartNumber := CurrentPartNumber = "" ? This.CurrentPartNumber : CurrentPartNumber
        This.CurrentPart := CurrentPart = "" ? This.CurrentPart : CurrentPart
        This.CurrentAct := CurrentAct = "" ? This.CurrentAct : CurrentAct
        This.CurrentZone := CurrentZone = "" ? This.CurrentZone : CurrentZone
        This.LastLogLines := LastLogLines = "" ? This.LastLogLines : LastLogLines
    }

    ;Decodes area code to select part, act, and zone from dropdown. Also sets monster level. Also writes to ini.
    SaveZoneFromAreaCode(monsterLevel, areaCode) {
        ;Turn areaCode into a zone name - areacode is formatted like [C_]GX_Y_Z where
        ;if there is C_ it's cruel difficulty, X is act, Y_Z is zone.
        ;areaCodeData maps C_G1_1 -> ["C", "G1", "1"], G1_1_2 -> ["G", "1", "2"]
        areaCodeData := StrSplit(areaCode, "_")

        actNumber := 0
        isCruel := areaCodeData[1] = "C" ;Cruel difficulty zones start with C
        If (isCruel)
        {
            areaCodeData.RemoveAt(1)
            actNumber := actNumber + 3 ;cruel difficulty so only check last 3 acts
        }
        actNumber := SubStr(areaCodeData[1], 2) + actNumber ;Get rid of the G
        act := This.ZoneReference.zones[actNumber]

        ;Find the exact zone, and switch to it in the controls.
        For index, newZone in act.list
        {
            IfInString, newZone, %areaCode%
            {
                ;Choose the part
                newPart := isCruel ? "Part 2" : "Part 1"
                if (newPart <> This.CurrentPart)
                {
                    numPart := isCruel ? 2 : 1
                    CurrentPart := newPart ;TODO stop needing this global var
                    This.CurrentPart := newPart
                    GuiControl, Controls:Choose, CurrentPart, % "|" newPart
                }

                ;Choose the act
                newAct := act.act
                If (newAct <> This.CurrentAct)
                {
                    CurrentAct := newAct
                    This.CurrentAct := newAct ;TODO stop needing this global var
                    GuiControl, Controls:Choose, CurrentAct, % "|" newAct
                }

                ;Choose the zone
                If (newZone <> This.CurrentZone)
                {
                    CurrentZone := newZone ;TODO stop needing this global var
                    This.CurrentZone := newZone
                    ;We have to match the zones in the dropdown which have the area code trimmed so that it's pretty
                    StringTrimLeft, trimmedNewZone, newZone, InStr(newZone, " ")
                    GuiControl, Controls:Choose, CurrentZone, % "|" trimmedNewZone
                    UpdateImages()
                }

                Sleep 100
                break
            }
        }

        WriteZoneData(This.CurrentPartNumber, This.CurrentPart, This.CurrentAct, This.CurrentZone)
    }

    ;Return a delimited list like "zone1|zone2|zone3|" to populate the dropdown
    ;Also needs || after the current zone.
    GetZonesInCurrentAct() {
        zonesDelimitedString := ""
        For key, zoneGroup in This.ZoneReference.zones {
            If (zoneGroup.act = This.CurrentAct) {
                For k, zone in zoneGroup.list {
                    ;zone looks like "C_G2_5_1 Mastodon Badlands", turn it into "Mastodon Badlands".
                    StringTrimLeft, trimmedVal, zone, InStr(zone, " ")
                    zonesDelimitedString .= trimmedVal . "|"
                    If (trimmedVal = This.CurrentZone) {
                        zonesDelimitedString .= "|"
                    }
                }
                break
            }
        }
        Return zonesDelimitedString
    }

    ;Return a delimited list like "Act 1|Act 2|Act 3|" to populate the dropdown
    ;Also needs || after the current act.
    GetActsInCurrentPart() {
        actsDelimitedString := ""
        For key, zoneGroup in This.ZoneReference.zones {
            If (zoneGroup.part = This.CurrentPart) {
                actsDelimitedString .= zoneGroup.act . "|"
            }
            If (zoneGroup.act = This.CurrentAct) {
                actsDelimitedString .= "|"
            }
        }
        Return actsDelimitedString
    }

    ;Return a delimited list like "Part 1|Part 2|" to populate the dropdown
    ;Also needs || after the current part.
    GetParts() {
        partsDelimitedString := ""
        For key, partItem in This.ZoneReference.parts {
            partsDelimitedString .= partItem . "|"
            If ( partItem = This.CurrentPart ) {
                partsDelimitedString .= "|"
            }
        }
        Return partsDelimitedString
    }
}

;Have to put these methods here to avoid error: Call to nonexistent function.
;Would put them in the class :( Could do GlobalState.ZoneData.ThisMethodHere() in methods above but that would require
;intialisation first, and this is an initialisation step. Would get messy.
ReadReferenceDataFromJSON() {
    ;Read This.ZoneReference.json - contains part, act, zone level, zone code, and zone name.
    ZoneReference := {}
    Try {
        FileRead, JSONFile, % GlobalState.ProjectRootDirectory . "\lib\ZoneReference.json"
        ZoneReference := JSON.Load(JSONFile)
        If (not ZoneReference.zones.Length()) { ;Just check that one of the lists has a length to prove JSON.Load worked.
            MsgBox, 16, , Error reading zone ZoneData file! `n`nExiting script.
            ExitApp
        }
    } Catch e {
        MsgBox, Error: %ErrorLevel% - %A_LastError%
        MsgBox, 16, , % e "`n`nCould not read ZoneData file: Exiting script."
        ExitApp
    }

    return ZoneReference
}

WriteZoneData(CurrentPartNumber, CurrentPart, CurrentAct, CurrentZone) {
    IniWrite, %CurrentPartNumber%, %INIMeta%, State, CurrentPartNumber
    IniWrite, %CurrentPart%, %INIMeta%, State, CurrentPart
    IniWrite, %CurrentAct%, %INIMeta%, State, CurrentAct
    IniWrite, %CurrentZone%, %INIMeta%, State, CurrentZone
}