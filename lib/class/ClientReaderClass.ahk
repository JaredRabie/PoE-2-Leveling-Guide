class ClientReaderClass {

    __New() {
        This.client_txt_file := ""
        This.newLogLines := "" ;Todo this should start with the newLogLines from meta.ini? or should I just
        ;not care about the last log lines from last session?
    }

    SetClientTxtFilepath(filepath) {
        This.clientTxtFilepath := filepath
    }

    GetNewLogLines() {
        ;Get lines since we last set the pointer
        newLogLines := This.client_txt_file.Read()
        This.newLogLines := newLogLines

        ;Set the pointer to end of file
        This.client_txt_file := FileOpen(This.clientTxtFilepath,"r")
        This.client_txt_file.Seek(0,2) ;skip file pointer to end (Origin = 2 -> end of file, distance 0 => end)

        ;Send the lines we gathered
        return newLogLines
    }
}