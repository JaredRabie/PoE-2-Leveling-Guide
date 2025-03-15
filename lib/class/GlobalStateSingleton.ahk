#Include, %A_ScriptDir%\lib\class\ZoneDataClass.ahk
#Include, %A_ScriptDir%\lib\class\ClientReaderClass.ahk

;Global state is here as a way to solve the problem of having a TON of global variables, since we're using AHK.
;This class basically just holds a few bits of data that are actively worked on/referenced while the app is running
;Not including everything that can go in the ini (i.e. there are still global variables in this app) since this class
;would be massive but this is at least a start. Makes the app way easier to work on since you don't have to remember
;the exact wording of all the global variables, autocomplete from this class makes it easy.

class GlobalStateSingleton {
    __New(projectRootDirectory) {
        This.ProjectRootDirectory := projectRootDirectory
        This.OverlayFolder := overlayFolder ;TODO stop using this global var

    }

    InitialiseClasses() {
        ;This should be called something better, basically we need GLobalState.stuff to be able to initialise
        ;these classes but that isn't available until GlobalState is intialised, so these can't just go in the
        ;__New above.
        This.ZoneData := new ZoneDataClass
        This.ClientReader := new ClientReaderClass
        This.LevelTracker := new LevelTrackerClass
    }

    SetProjectRootDirectory(projectRootDirectory) {
        This.ProjectRootDirectory := projectRootDirectory
    }

    SetOverlayFolderDirectory(overlayFolder) {
        This.OverlayFolder := overlayFolder
    }

    GetZoneData() {
        return This.ZoneData
    }

    GetLevelTracker() {
        return This.LevelTracker
    }

    GetClientReader() {
        return This.ClientReader
    }
}