USING: editors io.files io.launcher kernel math.parser
namespaces sequences windows.shell32 make io.pathnames ;
in: editors.notepad2

singleton: notepad2
notepad2 editor-class set-global

: notepad2-path ( -- path )
    \ notepad2-path get [
        windows-directory "system32\\notepad.exe" append-path
        [ "notepad.exe" ] unless*
    ] unless* ;

M: notepad2 editor-command ( file line -- command )
    [
        notepad2-path ,
        "/g" , number>string , ,
    ] { } make ;