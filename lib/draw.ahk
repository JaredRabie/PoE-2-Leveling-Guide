﻿DrawZone() {
  global

  gemFiles := []
  Loop %A_ScriptDir%\builds\%overlayFolder%\gems\*.ini
  {
    tempFileName = %A_LoopFileName%
    If (tempFileName != "meta.ini" and tempFileName != "class.ini") {
      W := MeasureTextWidth(tempFileName, "s" . points . "  w" . boldness, font)
      If ( W > gems_width ) {
        gems_width := W
      }
      StringTrimRight, tempFileName, tempFileName, 4
      gemFiles.Push(tempFileName)
    }
  }
  gems_width := gems_width + 10
  ;If (gemFiles.length() = 0){ ;If the file didnt exist it just got created, probably empty
  ;  gemFiles := ["02"]
  ;}

  Gui, Controls:+E0x20 +E0x80 -DPIScale -Caption +LastFound +ToolWindow +AlwaysOnTop +hwndControls
  Gui, Controls:Color, %backgroundColor%
  Gui, Controls:Font, s%points%, %font%
  Gui, Controls:Add, DropDownList, VCurrentZone GzoneSelectUI x0 y0 w%act_width% h300 , % GlobalState.ZoneData.GetZonesInCurrentAct()
  Gui, Controls:Add, DropDownList, VCurrentAct GactSelectUI x+%controlSpace% y0 w%nav_width% h200 , % GlobalState.ZoneData.GetActsInCurrentPart()
  Gui, Controls:Add, DropDownList, VCurrentPart GpartSelectUI x+%controlSpace% y0 w%part_width% h200 , % GlobalState.ZoneData.GetParts()
  ;xPos := xPosLayoutParent + (maxImages * (images_width+controlSpace))
  control_width := nav_width + part_width + act_width + (controlSpace*2)
  xPos := Round( (A_ScreenWidth * guideXoffset) - control_width )
  yPos := controlSpace + (A_ScreenHeight * guideYoffset)
  Gui, Controls:Show, h%control_height% w%control_width% x%xPos% y%yPos% NA, Controls

  Gui, Gems:+E0x20 +E0x80 -DPIScale -Caption +LastFound +ToolWindow +AlwaysOnTop +hwndGems
  Gui, Gems:Color, %backgroundColor%
  Gui, Gems:Font, s%points%, %font%
  Gui, Gems:Add, DropDownList, Sort VCurrentGem GgemSelectUI x0 y0 w%gems_width% h300 , % GlobalState.ZoneData.GetParts()
  Gui, Gems:Show, h%control_height% w%gems_width% x%xPosGems% y%yPosGems% NA, Gems

  Gui, Level:+E0x20 +E0x80 -DPIScale -Caption +LastFound +ToolWindow +AlwaysOnTop +hwndLevel
  Gui, Level:Color, %backgroundColor%
  Gui, Level:Font, s%points%, %font%
  Gui, Level:Add, Edit, x0 y0 h%control_height% w%level_width% r1 GlevelSelectUI, Level
  Gui, Level:Add, UpDown, x%controlSpace% vCurrentLevel GlevelSelectUI Range1-100, %CurrentLevel%
  Gui, Level:Show, h%control_height% w%level_width% x%xPosLevel% y%yPosLevel% NA, Level

  ;The names of the images have to be created now so that ShowAllWindows doesn't make empty ones that show up in the Alt Tab bar
  Loop, % maxImages {
    Gui, Image%A_index%:+E0x20 +E0x80 -DPIScale -resize -SysMenu -Caption +ToolWindow +AlwaysOnTop +hwndImage%newIndex%Window
  }
}

DrawAtlas() {
  global

  image_file := "" A_ScriptDir "\images\atlas.png" ""

  If (FileExist(image_file))
  {
    GDIPToken := Gdip_Startup()

    pBM := Gdip_CreateBitmapFromFile( image_file )
    original_treeW:= Gdip_GetImageWidth( pBM )
    original_treeH:= Gdip_GetImageHeight( pBM )

    Gdip_DisposeImage( pBM )
    Gdip_Shutdown( GDIPToken )

    ;Only build the tree if the file is a valid size picture
    If (original_treeW and original_treeH)
    {
      If (original_treeW > original_treeH) {
        treeW := Round( A_ScreenWidth / 2 )
        treeRatio := treeW / original_treeW
        treeH := original_treeH * treeRatio
        If (treeH > Round( A_ScreenHeight * 4 / 5 )){
          treeH := Round( A_ScreenHeight * 4 / 5 )
          treeRatio := treeH / original_treeH
          treeW := original_treeW * treeRatio
        }
      } else {
        treeH := Round( A_ScreenHeight * 4 / 5 )
        treeRatio := treeH / original_treeH
        treeW := original_treeW * treeRatio
      }

      If (treeSide = "Right") {
        xTree := A_ScreenWidth - treeW
      } else {
        xTree := 0
      }
      yTree := A_ScreenHeight - treeH

      Gui, Tree:+E0x20 +E0x80 -Caption +ToolWindow +LastFound +AlwaysOnTop -Resize -DPIScale +hwndTreeWindow
      Gui, Tree:Add, Picture, x0 y0 w%treeW% h%treeH%, %image_file%

      Gui, Tree:Show, x%xTree% y%yTree% w%treeW% h%treeH% NA, Gui Tree
      WinSet, Transparent, 240, ahk_id %TreeWindow%
    }
  }
}

DrawTree() {
  global

  If (numPart != 3) {
    image_file := "" A_ScriptDir "\builds\" overlayFolder "\" CurrentAct "\" treeName ""
  } Else {
    image_file := "" A_ScriptDir "\builds\" overlayFolder "\Act 11\" treeName ""
  }

  If (FileExist(image_file))
  {
    GDIPToken := Gdip_Startup()

    pBM := Gdip_CreateBitmapFromFile( image_file )
    original_treeW:= Gdip_GetImageWidth( pBM )
    original_treeH:= Gdip_GetImageHeight( pBM )

    Gdip_DisposeImage( pBM )
    Gdip_Shutdown( GDIPToken )

    ;Only build the tree if the file is a valid size picture
    If (original_treeW and original_treeH)
    {
      If (original_treeW > original_treeH) {
        treeW := Round( A_ScreenWidth / 2 )
        treeRatio := treeW / original_treeW
        treeH := original_treeH * treeRatio
        If (treeH > Round( A_ScreenHeight * 4 / 5 )){
          treeH := Round( A_ScreenHeight * 4 / 5 )
          treeRatio := treeH / original_treeH
          treeW := original_treeW * treeRatio
        }
      } else {
        treeH := Round( A_ScreenHeight * 4 / 5 )
        treeRatio := treeH / original_treeH
        treeW := original_treeW * treeRatio
      }

      If (treeSide = "Right") {
        xTree := A_ScreenWidth - treeW
      } else {
        xTree := 0
      }
      yTree := A_ScreenHeight - treeH

      Gui, Tree:+E0x20 +E0x80 -Caption +ToolWindow +LastFound +AlwaysOnTop -Resize -DPIScale +hwndTreeWindow
      Gui, Tree:Add, Picture, x0 y0 w%treeW% h%treeH%, %image_file%

      Gui, Tree:Show, x%xTree% y%yTree% w%treeW% h%treeH% NA, Gui Tree
      WinSet, Transparent, 240, ahk_id %TreeWindow%
    }
  }
}

DrawExp(){
  global

  Gui, Exp:+E0x20 +E0x80 -DPIScale -Caption +LastFound +ToolWindow +AlwaysOnTop +hwndExp
  Gui, Exp:font, cFFFFFF s%points% w%boldness%, %font%
  Gui, Exp:Color, %backgroundColor%
  WinSet, Transparent, %opacity%

  calcExp := "Exp: 100.0%   Over: +10"

  CurrentExp = ""
  Gui, Exp:Add, Text, vCurrentExp x3 y3, % calcExp

  Gui, Exp:Show, x%xPosExp% y%yPosExp% w%exp_width% h%control_height% NA, Gui Exp
}

GetDelimitedPartListString(zoneReference, part) {
  dList := ""
  For key, partItem in zoneReference {
    dList .= partItem . "|"
    If ( InStr(partItem,part) ) {
      ;If (partItem = part) {
      dList .= "|"
    }
  }
  Return dList
}

GetDelimitedActListString(zoneReference, act, part) {
  dList := ""
  If (numPart != 3) {
    For key, zoneGroup in zoneReference {
      If (zoneGroup.part = part) {
        dList .= zoneGroup.act . "|"
      }
      If (zoneGroup.act = act) {
        dList .= "|"
      }
    }
  } Else {
    currentWatchstones := SubStr(act, 1, 2)
    Loop, 17 ; because there are 16 stones now, this used to be 33 when there were 32 stones
    {
      watchstoneNumber := A_Index - 1
      If (watchstoneNumber < 10) {
        watchstoneNumber := "0" . watchstoneNumber
      }
      dList .= watchstoneNumber . " Watchstones|"
      If (watchstoneNumber = currentWatchstones) {
        dList .= "|"
      }
    }
  }
  Return dList
}

GetDelimitedZoneListString(zoneReference, act) {
  dList := ""
  If (numPart != 3) {
    For key, zoneGroup in zoneReference {
      If (zoneGroup.act = act) {
        For k, zone in zoneGroup.list {
          ;zone looks like "C_G2_5_1 Mastodon Badlands", turn it into "Mastodon Badlands".
          StringTrimLeft, trimmedVal, zone, InStr(zone, " ")
          dList .= trimmedVal . "|"
          If (val = CurrentZone) {
            dList .= "|"
          }
        }
        break
      }
    }
  } Else {
    For key, value in Maps {
      dList .= key . "|"
      If (key = CurrentZone) {
        dList .= "|"
      }
    }
  }
  Return dList
}

;Executed whenever the part is changed in the zone tracker gui
;This happens before the GUI is updated, and does not include the GUI actually switching to the new part
;Basically just need to update the list of possible acts, to do that have to select one, if I selected an act I should
;populate the zones, to do that I have to select one.
partSelectUI() {
  ;don't rlly need this next line I'll just populate the act dropdown and leave it blank, whenever I update part
  ;I should be updating zone.
  ;newAct := GlobalState.GetZoneData().CurrentPart == "Part 1" ? GlobalState.GetZoneData().ZoneReference.p1acts[1] : GlobalState.GetZoneData().ZoneReference.p2acts[1]
  GuiControl,,CurrentAct, % "|" GlobalState.GetZoneData().GetActsInCurrentPart()
  ;global
  ; Gui, Controls:Submit, NoHide

  ; If (CurrentPart = "Part 1") {
  ;   CurrentAct := "Act 1"
  ;   numPart := 1
  ; } Else If (CurrentPart = "Part 2") {
  ;   CurrentAct := "Act 6"
  ;   numPart := 2
  ; } Else {
  ;   INIStones=%A_scriptdir%\watchstones.ini
  ;   IniRead, CurrentAct, %INIStones%, Watchstones, collected, "00 Watchstones"
  ;   CurrentZone := "Academy Map"
  ;   numPart := 3
  ;   ; Gui, Notes:Cancel
  ;   ; Gui, Guide:Cancel
  ; }

  ; GuiControl,,CurrentAct, % "|" test := GlobalState.GetZoneData().GetActsInCurrentPart()
  ; Sleep 100

  ; If (numPart != 3) {
  ;   CurrentZone := GetDefaultZone(GlobalState.ZoneData.ZoneReference.ZoneReference.zones, CurrentAct)
  ; }
  ; GuiControl,,CurrentZone, % "|" test := GetDelimitedZoneListString(GlobalState.ZoneData.ZoneReference.ZoneReference.zones, CurrentAct)
  ; Sleep 100
  ; If (numPart != 3) {
  ;   SetGuide()
  ;   SetNotes()
  ;   If (zone_toggle = 1) {
  ;     UpdateImages()
  ;   }
  ; } Else {
  ;   ;SetMapGuide()
  ;   ;SetMapNotes()
  ;   If (zone_toggle = 1) {
  ;     ;UpdateMapImages()
  ;   }
  ; }
  ; SetExp()

  ; trigger := 1
  ; WinActivate, ahk_id %PoEWindowHwnd%

  ; SaveState()
}

actSelectUI() {
  GuiControl,,CurrentZone, % "|" GlobalState.GetZoneData().GetZonesInCurrentAct()
  ; global
  ; Gui, Controls:Submit, NoHide

  ; If (numPart != 3){
  ;   CurrentZone := GetDefaultZone(GlobalState.GetZoneData().ZoneReference.zones, CurrentAct)
  ;   GuiControl,,CurrentZone, % "|" test := GetDelimitedZoneListString(GlobalState.GetZoneData().ZoneReference.zones, CurrentAct)
  ;   Sleep 100
  ;   SetGuide()
  ;   SetNotes()
  ;   If (zone_toggle = 1) {
  ;     UpdateImages()
  ;   }
  ; } Else { ;This shouldn't happen for this version until we re-enable maps
  ;   ;Save watchstone and conq info
  ;   INIStones=%A_scriptdir%\watchstones.ini
  ;   IniWrite, %CurrentAct%, %INIStones%, Watchstones, collected
  ;   For key, value in Conquerors {
  ;     output := value.Region
  ;     IniWrite, %output%, %INIStones%, %key%, region
  ;     output := value.Appearances
  ;     IniWrite, %output%, %INIStones%, %key%, appearances
  ;   }

  ;   ; INIAtlas=%A_scriptdir%\maps\atlas.ini
  ;   ; For key, value in Regions {
  ;   ;   IniRead, numStones, %INIAtlas%, %CurrentAct%, %key%, 0
  ;   ;   value.SocketedStones := numStones
  ;   ; }
  ;   ;SetMapGuide()
  ;   ;SetMapNotes()
  ;   If (zone_toggle = 1) {
  ;     ;UpdateMapImages()
  ;   }
  ; }
  ; SetExp()
  ; WinActivate, ahk_id %PoEWindowHwnd%
  ; SaveState()
}

zoneSelectUI() {
  global
  Sleep 10000
  Gui, Controls:Submit, NoHide
  Sleep 100
  If (numPart != 3) {
    SetNotes()
    If (zone_toggle = 1) {
      UpdateImages()
    }
  } Else {
    ;SetMapNotes()
    If (zone_toggle = 1) {
      ;UpdateMapImages()
    }
  }
  SetExp()
  WinActivate, ahk_id %PoEWindowHwnd%
  SaveState()
}

levelSelectUI() {
  global
  Gui, Level:Submit, NoHide
  SetExp()
  SaveState()
}

gemSelectUI() {
  global
  Gui, Gems:Submit, NoHide
  SetGems()
  WinActivate, ahk_id %PoEWindowHwnd%
  SaveState()
}

GetDefaultZone(zones, act) {
  For key, zoneGroup in zones {
    If (zoneGroup.act = act) {
      Return zoneGroup.default
    }
  }
}

UpdateImages()
{
  global
  emptySpaces := 0
  Loop, % maxImages {
    imageIndex := (maxImages - A_Index) + 1
    StringTrimLeft, ImageName, CurrentZone, 3
    ;MsgBox, % ImageName
    filepath := "" A_ScriptDir "\images\" CurrentAct "\" ImageName "_Seed_" imageIndex ".jpg" ""

    newIndex := A_index - emptySpaces
    ;This shouldn't happen anymore but if this method gets called twice quickly newIndex goes below 0
    If (newIndex < 1) {
      newIndex := 1
    }
    Gui, Image%newIndex%:Destroy ;I'm not sure this will work

    If (FileExist(filepath)) {
      ;xPos := xPosLayoutParent + ((maxImages - (newIndex + 0)) * (images_width+controlSpace))
      Gui, Image%newIndex%:+E0x20 +E0x80 -DPIScale -resize -SysMenu -Caption +ToolWindow +AlwaysOnTop +hwndImage%newIndex%Window
      Gui, Image%newIndex%:Add, Picture, x0 y0 w%images_width% h%images_height%, %filepath%
      If (xPosImages = 0) {
        If (hideNotes != "True") {
          xPos := xPosNotes - (newIndex * (images_width+controlSpace))
        } Else {
          If (hideGuide != "True"){
            xPos := xPosGuide - (newIndex * (images_width+controlSpace))
          } Else {
            xPos := Round( (A_ScreenWidth * guideXoffset)) - (newIndex * (images_width+controlSpace))
          }
        }
        yPosImages := yPosNotes
      } Else {
        xPos := xPosImages - (newIndex * (images_width+controlSpace))
      }
      Gui, Image%newIndex%:Show, w%images_width% h%images_height% x%xPos% y%yPosImages% NA, Image%newIndex%
      id := Image%newIndex%Window
      WinSet, Transparent, %opacity%, ahk_id %id%
      Gui, Image%newIndex%:Cancel
    }
    Else {
      emptySpaces++
      ;Have to show the image to make it invisible (in case zone_toggle is off)
      Gui, Image%imageIndex%:Show, NA
      hideId := Image%imageIndex%Window
      WinSet, Transparent, 0, ahk_id %hideId%
      Gui, Image%imageIndex%:Cancel
    }
  }
}