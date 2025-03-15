Class LevelTrackerClass {
    __New() {
        ;Read global config
        ;User can choose between seeing their xp multipler (eg 98%) or their penalty (2%).
        This.MultiplierOrPenalty := "Multiplier" ;TODO this replaces expOrPen so remove usages of that.

        ININame = %GlobalState.ProjectRootDirectory%\config.ini
        IniRead, MultiplierOrPenalty, %ININame%, Options, MultiplierOrPenalty, %MultiplierOrPenalty%

        This.MultiplierOrPenalty := MultiplierOrPenalty

        ;Read config for this build
        This.PlayerLevelInt := 1
        This.PlayerLevelString := "01" ;01 so that the GUI dropdown is ordered correctly.
        This.MonsterLevelInt := 1
        This.MonsterLevelString := "01"

        INIMeta = %GlobalState.ProjectRootDirectory%\builds\%GlobalState.OverlayFolder%\gems\meta.ini
        IniRead, PlayerLevelInt, %INIMeta%, State, PlayerLevelInt, %PlayerLevelInt%
        IniRead, MonsterLevelInt, %INIMeta%, State, MonsterLevelInt, %MonsterLevelInt%

        This.PlayerLevelInt := PlayerLevelInt
        This.MonsterLevelInt := MonsterLevelInt
    }

    SavePlayerLevel(PlayerLevelInt) {
        This.PlayerLevelInt := PlayerLevelInt
        IniWrite, %PlayerLevelInt%, %INIMeta%, State, PlayerLevelInt
    }

    SaveMonsterLevel(MonterLevelInt) {
        This.MonsterLevelInt := MonsterLevelInt
        IniWrite, %MonsterLevelInt%, %INIMeta%, State, MonsterLevelInt
    }

    ;Updates the GUI exp tracker
    UpdateExpTracker() {
        expMulti := CalculateExpMultiplier(This.PlayerLevelInt, This.MonsterLevelInt)

        If (expOrPen = "Exp"){
            calcExp := "Exp: "
            If (expMulti = 1){
                calcExp .= "100"
            } Else {
                calcExp .= Round((expMulti * 100), 1)
            }
        } Else {
            calcExp := "Pen: "
            calcExp .= Round((1-expMulti) * 100, 1)
        }
        calcExp .= "%  "

        calcExp .= "Over: "
        calcExp .= This.PlayerLevelInt - (Floor(monsterLevel) - safeZone)

        GuiControl,Exp:,CurrentExp, %calcExp%

        Gui, Exp:Show, x%xPosExp% y%yPosExp% w%exp_width% h%control_height% NA, Gui Exp
    }
}

CalculateExpMultiplier(playerLevel, monsterLevel) {
    safeZone := Floor(3 + (playerLevel/16) )

    ;region the xp calc for 71 - 84 uses a different monster level
    If (monsterLevel = 71) {
        monsterLevel = 70.94
    } Else If (monsterLevel = 72) {
        monsterLevel = 71.82
    } Else If (monsterLevel = 73) {
        monsterLevel = 72.64
    } Else If (monsterLevel = 74) {
        monsterLevel = 73.40
    } Else If (monsterLevel = 75) {
        monsterLevel = 74.10
    } Else If (monsterLevel = 76) {
        monsterLevel = 74.74
    } Else If (monsterLevel = 77) {
        monsterLevel = 75.32
    } Else If (monsterLevel = 78) {
        monsterLevel = 75.84
    } Else If (monsterLevel = 79) {
        monsterLevel = 76.30
    } Else If (monsterLevel = 80) {
        monsterLevel = 76.70
    } Else If (monsterLevel = 81) {
        monsterLevel = 77.04
    } Else If (monsterLevel = 82) {
        monsterLevel = 77.32
    } Else If (monsterLevel = 83) {
        monsterLevel = 77.54
    } Else If (monsterLevel = 84) {
        monsterLevel = 77.70
    }
    ;endregion

    effectiveDiff := Abs(playerLevel - monsterLevel) - safeZone
    If (effectiveDiff < 0) {
        return 1
    }
    expPenalty := (playerLevel+5)/(playerLevel+5+Sqrt(effectiveDiff**5))
    expMulti := Sqrt(expPenalty**3)
    If (playerLevel >= 95) {
        expMulti := expMulti * (1/(1+(0.1*(playerLevel-94))))
    }

    If (expMulti < 0.01) {
        expMulti := 0.01
    }

    return expMulti
}