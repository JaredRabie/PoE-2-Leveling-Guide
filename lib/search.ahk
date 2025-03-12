RotateAct(direction, acts, current) {
  global
  newAct := ""
  indexShift := direction = "next" ? 1 : -1
  first := ""
  last := ""

  Loop, % acts.Length()
  {
    If (A_Index = 1) {
      first := acts[A_Index]
    }
    If (A_Index = acts.MaxIndex()) {
      last := acts[A_Index]
    }

    If (acts[A_Index] = current) {
      newAct := acts[A_Index + indexShift]
    }
  }

  If (not StrLen(newAct)) {
    newAct := direction = "next" ? first : last
  }

  Return newAct
}

RotateZone(direction, zones, act, current) {
  newZone := ""
  indexShift := direction = "next" ? 1 : -1
  first := ""
  last := ""

  For key, zone in zones {
    If (zone.act = act) {
      Loop, % zone["list"].Length()
      {
        If (A_Index = 1) {
          first := zone.list[A_Index]
        }
        If (A_Index = zone.list.MaxIndex()) {
          last := zone.list[A_Index]
        }

        If (zone.list[A_Index] = current) {
          newZone := zone.list[A_Index + indexShift]
        }
      }
      break
    }
  }

  If (not StrLen(newZone)) {
    newZone := direction = "next" ? first : last
  }

  Return newZone
}

SearchLog() {
  global
  ;Only bother checking if the newLogLines has changed or someone manually changed Part
  newLogLines := client_txt_file.Read()
  If (trigger) {
    trigger := 0
    newLogLines := LastLogLines
  }
  If (newLogLines) {
    levelUp := charName ;check character name is present first
    IfInString, newLogLines, %levelUp%
    {
      levelUp := "is now level"

      IfInString, newLogLines, %levelUp%
      {
        levelPos := InStr(newLogLines, levelUp, false)
        newLevel := Trim(SubStr(newLogLines, levelPos+13, 2))
        newLevel += 0 ; force the string to be an int, clearing any space
        nextLevel := newLevel + 1
        ;So levels stay in order
        If (newLevel < 10)
        {
          newLevel := "0" . newLevel
        }
        If (nextLevel < 10)
        {
          nextLevel := "0" . nextLevel
        }
        GuiControl,Level:,CurrentLevel, %newLevel%
        Sleep, 100
        gemFiles := []
        Loop %A_ScriptDir%\builds\%overlayFolder%\gems\*.ini
        {
          tempFileName = %A_LoopFileName%
          StringTrimRight, tempFileName, tempFileName, 4
          If (tempFileName != "meta" and tempFileName != "class")
          {
            gemFiles.Push(tempFileName)
          }
        }
        For index, someLevel in gemFiles
        {
          If ( InStr(someLevel,newLevel) || InStr(someLevel,nextLevel) )
          {
            GuiControl,Gems:,CurrentGem, % "|" test := GetDelimitedPartListString(gemFiles, someLevel)
            Sleep, 100
            Gui, Gems:Submit, NoHide
            If (gems_toggle)
            {
              SetGems()
            }
            break
          }
        }
        SaveState()
      }
      beenSlain := "has been slain"
      IfInString, newLogLines, %beenSlain%
      {
        Sleep, 5000
        Send, %KeyOnDeath%
      }
    } ;end level up logic

    ;Whenever you enter a new level, the client.txt adds a line like
    ;'Generating level 1 area "G1_1" with seed 1066861483'
    ;Here we extract the monster level, area, and part if a line like that exists.
    generated := "Generating level"
    seed := "with seed"
    If ( InStr(newLogLines,generated) )
    {
      If ( autoToggleZoneImages = "True" )
      {
        zone_toggle := 1
        places_disabled_zones :=  ["Hideout","Rogue Harbour", "Oriath", "Lioneye's Watch", "The Forest Encampment", "The Sarn Encampment", "Highgate", "Overseer's Tower", "The Bridge Encampment", "Oriath Docks"]
        For _, zone in places_disabled_zones
          IfInString, newLogLines, %zone%
          {
            zone_toggle := 0
            break
          }
      }
      activeCount := 0
      active_toggle := 1

      ;levelPos is the index just after 'Generating Level'
      levelPos := InStr(newLogLines, generated, false) + 17
      ;seedPos is the index just before 'with seed'
      seedPos := InStr(newLogLines, seed, false)
      ;levelString should look like '1 area "G1_1"'
      levelString := Trim(SubStr(newLogLines, levelPos, seedPos-levelPos))

      monsterLevel := StrSplit(levelString, " ")[1] ;AHK indexing starts at 1

      areaCode := StrSplit(levelString, " ")[3]
      areaCode := SubStr(areaCode, 2, StrLen(areaCode)-2) ;remove the "" from area code

      ;Turn areaCode into a zone name - areacode is formatted like [C_]GX_Y_Z where
      ;if there is C_ it's cruel difficulty, X is act, Y_Z is zone.
      areaCodeData := StrSplit(areaCode, "_")

      ;Grab the act object that is loaded from data.json
      actId := 0
      isCruel := areaCodeData.Length() > 2 ;This is used here and to select the correct part later
      If (isCruel)
      {
        areaCodeData.RemoveAt(1)
        actId := actId + 3 ;cruel difficulty so only check last 3 acts
      }
      actId := SubStr(areaCodeData[1], 2) + actId ;Get rid of the G and +0 converts to int.
      act := data.zones[actId]

      ;Find the exact zone, and switch to it in the controls.
      For index, newZone in act.list
      {
        IfInString, newZone, %areaCode%
        {
          LastLogLines := StrReplace(newLogLines, "`r`n")

          ;Choose the part
          newPart := isCruel ? "Part 2" : "Part 1"
          if (newPart <> CurrentPart)
          {
            numPart := isCruel ? 2 : 1
            CurrentPart := newPart
            GuiControl, Controls:Choose, CurrentPart, % "|" newPart
          }

          ;Choose the act
          newAct := act.act
          If (newAct <> CurrentAct)
          {
            CurrentAct := newAct
            GuiControl, Controls:Choose, CurrentAct, % "|" newAct
          }

          ;Choose the zone
          If (newZone <> CurrentZone)
          {
            CurrentZone := newZone
            GuiControl, Controls:Choose, CurrentZone, % "|" newZone
            UpdateImages()
          }

          Sleep 100
          break
        }
      }
      If (numPart = 1)
      {
        actData := data.p1acts
      } Else If (numPart = 2)
      {
        actData := data.p2acts
      }
      newAct := RotateAct("next", actData, newAct)

      ; newAct := CurrentAct
      ; If (numPart != 3)
      ; {
      ;   ;loop through all of the acts in the current part
      ;   Loop, 6
      ;   {
      ;     For key, zoneGroup in data.zones
      ;     {
      ;       If (zoneGroup.act = newAct)
      ;       {
      ;         For k, newZone in zoneGroup.list
      ;         {
      ;           ;newZone Looks Like "G1_1 The Riverbank"
      ;           ;We picked up the area code above so check that the zone we're iterating over contains that code
      ;           IfInString, newZone, %areaCode%
      ;           {
      ;             If (newAct != CurrentAct)
      ;             {
      ;               GuiControl, Controls:Choose, CurrentAct, % "|" newAct
      ;               CurrentAct := newAct
      ;               Sleep 100
      ;             }
      ;             LastLogLines := StrReplace(newLogLines, "`r`n")
      ;             GuiControl, Controls:Choose, CurrentZone, % "|" newZone
      ;             CurrentZone := newZone
      ;             Sleep 100
      ;             UpdateImages()
      ;             break 3
      ;           }
      ;         }
      ;         If (numPart = 1)
      ;         {
      ;           actData := data.p1acts
      ;         } Else If (numPart = 2)
      ;         {
      ;           actData := data.p2acts
      ;         }
      ;         newAct := RotateAct("next", actData, newAct)
      ;         break
      ;       }
      ;     }
      ;   }
    } ;end travel logic

    If (level_toggle)
    {
      SetExp()
    }
  }
}

; ClearConquerors(currentConqueror) {
;   For key, value in Conquerors {
;     ;If we get a new Conqueror and an old one finished, clear it
;     If ( key!=currentConqueror and value.Appearances>=4){
;       value.Appearances := 0
;       value.Region := ""
;       GuiControl, Controls:Choose, CurrentAct, % "|" CurrentAct
;     }
;   }
; }
