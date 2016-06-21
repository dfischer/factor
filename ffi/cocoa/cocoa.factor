! Copyright (C) 2006, 2009 Slava Pestov
! See http://factorcode.org/license.txt for BSD license.
USING: cocoa.messages compiler.units core-foundation.bundles
hashtables init io kernel lexer namespaces sequences vocabs ;
IN: cocoa

SYMBOL: sent-messages

: (remember-send) ( selector variable -- )
    [ dupd ?set-at ] change-global ;

: remember-send ( selector -- )
    sent-messages (remember-send) ;

SYNTAX: -> scan-token dup remember-send suffix! \ send suffix! ;
SYNTAX: \ send\ scan-token dup remember-send suffix! \ send suffix! ;

SYNTAX: \ SEL:
    scan-token
    [ remember-send ]
    [ <selector> suffix! \ cocoa.messages:selector suffix! ] bi ;
SYNTAX: \ sel\
    scan-token
    [ remember-send ]
    [ <selector> suffix! \ cocoa.messages:selector suffix! ] bi ;

SYMBOL: super-sent-messages

: remember-super-send ( selector -- )
    super-sent-messages (remember-send) ;

SYNTAX: \ SUPER-> scan-token dup remember-super-send suffix! \ super-send suffix! ;
SYNTAX: \ super-send\ scan-token dup remember-super-send suffix! \ super-send suffix! ;

SYMBOL: frameworks

frameworks [ V{ } clone ] initialize

[ frameworks get [ load-framework ] each ] "cocoa" add-startup-hook

SYNTAX: \ framework: scan-token [ load-framework ] [ frameworks get push ] bi ;

SYNTAX: \ import: scan-token [ ] import-objc-class ;

"Importing Cocoa classes..." print

"cocoa.classes" create-vocab drop

[
    {
        "NSAlert"
        "NSAppleScript"
        "NSApplication"
        "NSArray"
        "NSAutoreleasePool"
        "NSBitmapImageRep"
        "NSBundle"
        "NSColorSpace"
        "NSData"
        "NSDictionary"
        "NSError"
        "NSEvent"
        "NSException"
        "NSMenu"
        "NSMenuItem"
        "NSMutableDictionary"
        "NSNib"
        "NSNotification"
        "NSNotificationCenter"
        "NSNumber"
        "NSObject"
        "NSOpenGLContext"
        "NSOpenGLPixelFormat"
        "NSOpenGLView"
        "NSOpenPanel"
        "NSPanel"
        "NSPasteboard"
        "NSPropertyListSerialization"
        "NSResponder"
        "NSSavePanel"
        "NSScreen"
        "NSString"
        "NSView"
        "NSWindow"
        "NSWorkspace"
    } [
        [ ] import-objc-class
    ] each
] with-compilation-unit