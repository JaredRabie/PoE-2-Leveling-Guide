SearchLog() {
  global
  ;Only bother checking if the newLogLines has changed or someone manually changed Part
  ;newLogLines := client_txt_file.Read()
  newLogLines := GlobalState.GetClientReader().GetNewLogLines()

  ;TODO: What does this do? only other usage is in draw.ahk so is it pretending no new lines if new zone was selected manually?
  If (trigger) {
    trigger := 0
    newLogLines := LastLogLines
  }

  If (!newLogLines) {
    Return
  }

  ;just testing here
  foundLevelUpLine := RegExMatch(newLogLines, "O)is now level (.*)", newLevelLineOutput)
  if (foundLevelUpLine) {
    newLevel := newLevelLineOutput[1]
    nextLevel := newLevel + 1

    ;So levels stay in order in the dropdown
    If (newLevel < 10)
    {
      newLevel := "0" . newLevel
    }
    If (nextLevel < 10)
    {
      nextLevel := "0" . nextLevel
    }

    ;Select level on gui
    GuiControl,Level:,CurrentLevel, %newLevel%

    ;Gem stuff

    ;Save state
    GlobalState.GetLevelTracker().SavePlayerLevel(newLevel)

    GlobalState.GetLevelTracker().UpdateExpTracker()
  }

  ;Whenever you enter a new level, the client.txt adds a line like
  ;'Generating level 1 area "G1_1" with seed 1066861483'
  ;Here we extract the monster level, area, and part if a line like that exists.
  foundNewZoneLine := RegExMatch(newLogLines, "O)Generating level (.*) area ""(.*)"" with seed", newZoneLineOutput)
  if (foundNewZoneLine){
    newMonsterLevel := newZoneLineOutput[1] + 0 ;+0 forces int
    newAreaCode := newZoneLineOutput[2]

    ;Saves the new zone & monster level to current state, writes to ini, AND selects in the GUI
    ;TODO: this is probably way too much huh
    GlobalState.GetZoneData().SaveZoneFromAreaCode(monsterLevel, newAreaCode)
  }

  ;TODO: What does this IF do? is it supposed to only update the monster level xp calc if the user has that window open?
  ;It was after level/gem/zone stuff previously.
  If (level_toggle)
  {
    SetExp()
  }

  ;TODO just commented this willy nilly
  ;levelUp := charName ;check character name is present first
  ; IfInString, newLogLines, %levelUp%
  ; {
  ;   levelUp := "is now level"

  ;   IfInString, newLogLines, %levelUp%
  ;   {
  ;     levelPos := InStr(newLogLines, levelUp, false)
  ;     newLevel := Trim(SubStr(newLogLines, levelPos+13, 2))
  ;     newLevel += 0 ; force the string to be an int, clearing any space
  ;     nextLevel := newLevel + 1
  ;     ;So levels stay in order
  ;     If (newLevel < 10)
  ;     {
  ;       newLevel := "0" . newLevel
  ;     }
  ;     If (nextLevel < 10)
  ;     {
  ;       nextLevel := "0" . nextLevel
  ;     }
  ;     GuiControl,Level:,CurrentLevel, %newLevel%

  ;     ;Gem stuff ----------------------------
  ;     Sleep, 100
  ;     gemFiles := []
  ;     Loop %A_ScriptDir%\builds\%overlayFolder%\gems\*.ini
  ;     {
  ;       tempFileName = %A_LoopFileName%
  ;       StringTrimRight, tempFileName, tempFileName, 4
  ;       If (tempFileName != "meta" and tempFileName != "class")
  ;       {
  ;         gemFiles.Push(tempFileName)
  ;       }
  ;     }
  ;     For index, someLevel in gemFiles
  ;     {
  ;       If ( InStr(someLevel,newLevel) || InStr(someLevel,nextLevel) )
  ;       {
  ;         GuiControl,Gems:,CurrentGem, % "|" test := GetDelimitedPartListString(gemFiles, someLevel)
  ;         Sleep, 100
  ;         Gui, Gems:Submit, NoHide
  ;         If (gems_toggle)
  ;         {
  ;           SetGems()
  ;         }
  ;         break
  ;       }
  ;     }
  ;     SaveState()
  ;   }
  ;   beenSlain := "has been slain"
  ;   IfInString, newLogLines, %beenSlain%
  ;   {
  ;     Sleep, 5000
  ;     Send, %KeyOnDeath%
  ;   }
  ; } ;end level up logic

  ; generated := "Generating level"
  ; seed := "with seed"
  ; If ( InStr(newLogLines,generated) )
  ; {
  ;   If ( autoToggleZoneImages = "True" )
  ;   {
  ;     zone_toggle := 1
  ;     places_disabled_zones :=  ["Hideout","Rogue Harbour", "Oriath", "Lioneye's Watch", "The Forest Encampment", "The Sarn Encampment", "Highgate", "Overseer's Tower", "The Bridge Encampment", "Oriath Docks"]
  ;     For _, zone in places_disabled_zones
  ;       IfInString, newLogLines, %zone%
  ;       {
  ;         zone_toggle := 0
  ;         break
  ;       }
  ;   }
  ;   activeCount := 0
  ;   active_toggle := 1

  ;   ;levelPos is the index just after 'Generating Level'
  ;   levelPos := InStr(newLogLines, generated, false) + 17
  ;   ;seedPos is the index just before 'with seed'
  ;   seedPos := InStr(newLogLines, seed, false)
  ;   ;levelString should look like '1 area "G1_1"'
  ;   levelString := Trim(SubStr(newLogLines, levelPos, seedPos-levelPos))

  ;   monsterLevel := StrSplit(levelString, " ")[1] ;AHK indexing starts at 1

  ;   areaCode := StrSplit(levelString, " ")[3]
  ;   areaCode := SubStr(areaCode, 2, StrLen(areaCode)-2) ;remove the "" from area code

  ;   GlobalState.GetZoneData().SaveZoneFromAreaCode(monsterLevel, areaCode)
  ; } ;end travel logic

}

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