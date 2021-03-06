! Copyright (C) 2015 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: combinators.short-circuit editors
generalizations io.files io.pathnames io.standard-paths kernel
make math.parser memoize namespaces sequences system tools.which ;
IN: editors.visual-studio-code

! Command line arguments
! https://code.visualstudio.com/docs/editor/command-line

SINGLETON: visual-studio-code
visual-studio-code editor-class set-global

HOOK: find-visual-studio-code-invocation os ( -- array )

: visual-studio-code-invocation ( -- array )
    {
        [ \ visual-studio-code-invocation get ]
        [ find-visual-studio-code-invocation ]
        [ "code" ]
    } 0|| ;

M: macosx find-visual-studio-code-invocation
    { "com.microsoft.VSCodeInsiders" "com.microsoft.VSCode" }
    [ find-native-bundle ] map-find drop [
        "Contents/MacOS/Electron" append-path
    ] [
        f
    ] if* ;

ERROR: can't-find-visual-studio-code ;

M: linux find-visual-studio-code-invocation
    {
        [ "code-insiders" which ]
        [ "code" which ]
        [ "Code" which ]
        [ home "VSCode-linux-x64/Code" append-path ]
        [ "/usr/share/code/code" ]
    } [ dup exists? [ drop f ] unless ] map-compose 0|| ;

M: windows find-visual-studio-code-invocation
    {
        [ { "Microsoft VS Code Insiders" } "code-insiders.cmd" find-in-applications ]
        [ "code.cmd" ]
    } 0|| ;

M: visual-studio-code editor-command
    [
        visual-studio-code-invocation
        [ , ] [ can't-find-visual-studio-code ] if*
        "-g" , "-r" ,
        number>string ":" glue ,
    ] { } make ;
