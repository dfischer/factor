! Copyright (C) 2004, 2006 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
IN: html
USING: generic hashtables help http io kernel lists math
namespaces sequences strings styles words xml ;

: hex-color, ( triplet -- )
    3 swap head
    [ 255 * >fixnum >hex 2 CHAR: 0 pad-left % ] each ;

: fg-css, ( color -- )
    "color: #" % hex-color, "; " % ;

: bg-css, ( color -- )
    "background-color: #" % hex-color, "; " % ;

: style-css, ( flag -- )
    dup
    { italic bold-italic } member?
    [ "font-style: italic; " % ] when
    { bold bold-italic } member?
    [ "font-weight: bold; " % ] when ;

: size-css, ( size -- )
    "font-size: " % # "pt; " % ;

: font-css, ( font -- )
    "font-family: " % % "; " % ;

: hash-apply ( value-hash quot-hash -- )
    #! Looks up the key of each pair in the first list in the
    #! second list to produce a quotation. The quotation is
    #! applied to the value of the pair. If there is no
    #! corresponding quotation, the value is popped off the
    #! stack.
    swap [
        swap rot hash dup [ call ] [ 2drop ] if
    ] hash-each-with ;

: span-css-style ( style -- str )
    [
        H{
            { foreground  [ fg-css,        ] }
            { background  [ bg-css,        ] }
            { font        [ font-css,      ] }
            { font-style  [ style-css,     ] }
            { font-size   [ size-css,      ] }
        } hash-apply
    ] "" make ;

: span-tag ( style quot -- )
    over span-css-style dup empty? [
        drop call
    ] [
        <span =style span> call </span>
    ] if ;

: div-css-style ( style -- str )
    [
        H{
            { page-color   [ bg-css,        ] }
            ! { border-color [ font-css,      ] }
        } hash-apply
    ] "" make ;

: div-tag ( style quot -- )
    over div-css-style dup empty? [
        drop call
    ] [
        <div =style div> call </div>
    ] if ;

: resolve-file-link ( path -- link )
    #! The file responder needs relative links not absolute
    #! links.
    "doc-root" get [
        ?head [ "/" ?head drop ] when
    ] when* "/" ?tail drop ;

: file-link-href ( path -- href )
    [ "/" % resolve-file-link url-encode % ] "" make ;

: file-link-tag ( style quot -- )
    over file swap hash [
        <a file-link-href =href a> call </a>
    ] [
        call
    ] if* ;

: do-escaping ( string style -- string )
    html swap hash [ chars>entities ] unless ;

GENERIC: browser-link-href ( presented -- href )

M: word browser-link-href
    dup word-name swap word-vocabulary [
        "/responder/browser/?vocab=" %
        url-encode %
        "&word=" %
        url-encode %
    ] "" make ;

M: link browser-link-href
    link-name [ \ f ] unless* dup word? [
        browser-link-href
    ] [
        [ "/responder/help/" % url-encode % ] "" make
    ] if ;

M: object browser-link-href
    drop f ;

: browser-link-tag ( style quot -- style )
    presented pick hash browser-link-href
    [ <a =href a> call </a> ] [ call ] if* ;

TUPLE: nested-stream ;

C: nested-stream [ set-delegate ] keep ;

M: nested-stream stream-close drop ;

TUPLE: html-stream ;

C: html-stream ( stream -- stream ) [ set-delegate ] keep ;

M: html-stream stream-write1 ( char stream -- )
    >r ch>string r> stream-write ;

: delegate-write delegate stream-write ;

M: html-stream stream-write ( str stream -- )
    >r chars>entities r> delegate-write ;

M: html-stream stream-format ( str style stream -- )
    [
        [
            [
                [
                    do-escaping stdio get delegate-write
                ] span-tag
            ] file-link-tag
        ] browser-link-tag
    ] with-stream* ;

: pre-tag ( style quot -- )
    wrap-margin rot hash [
        call
    ] [
        <pre> call </pre>
    ] if ;

M: html-stream with-nested-stream ( quot style stream -- )
    [
        [
            [
                stdio get <nested-stream> swap with-stream*
            ] pre-tag
        ] div-tag
    ] with-stream* ;

M: html-stream stream-terpri [ <br/> ] with-stream* ;

: with-html-stream ( quot -- )
    stdio get <html-stream> swap with-stream* ;

: default-css ( -- )
  <style>
    "A:link { text-decoration:none}" print
    "A:visited { text-decoration:none}" print
    "A:active { text-decoration:none}" print
    "A:hover, A.nav:hover { border: 1px solid black; text-decoration: none; margin: -1px }" print
  </style> ;

: html-document ( title quot -- )
    swap chars>entities dup
    <html>
        <head>
            <title> write </title>
            default-css
        </head>
        <body>
            <h1> write </h1>
            call
        </body>
    </html> ;

: simple-html-document ( title quot -- )
    swap [ <pre> with-html-stream </pre> ] html-document ;
