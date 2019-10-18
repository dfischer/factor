! Copyright (C) 2005, 2006 Daniel Ehrenberg
! See http://factorcode.org/license.txt for BSD license.
IN: xml
USING: errors hashtables io kernel math namespaces prettyprint sequences
    arrays generic strings ;

TUPLE: opener name props ;
TUPLE: closer name ;
TUPLE: contained name props ;
TUPLE: comment text ;
TUPLE: directive text ;
TUPLE: instruction text ;

: start-tag ( -- name ? )
    #! Outputs the name and whether this is a closing tag
    char CHAR: / = dup [ incr-spot ] when
    parse-name swap ;

: (parse-quot) ( ch vector sbuf -- vector )
    {
        { [ more? not ] [ "File ended in quote" <xml-string-error> throw ] }
        { [ char >r pick r> swap = ] [ >string over push nip incr-spot ] }
        { [ char CHAR: & = ] [ parse-entity (parse-quot) ] }
        { [ t ] [ char parsed-ch (parse-quot) ] }
    } cond ;

: parse-quot ( ch -- array )
   V{ } clone SBUF" " clone (parse-quot) ;

: parse-prop-value ( -- str )
    char dup "'\"" member? [
        incr-spot parse-quot
    ] [
        "Attribute lacks quote" <xml-string-error> throw
    ] if ;

: parse-prop ( -- seq )
    parse-name pass-blank CHAR: = expect pass-blank
    parse-prop-value 2array ;

: (middle-tag) ( seq -- seq )
    pass-blank char name-char?
    [ parse-prop over push (middle-tag) ] when ;

: middle-tag ( -- hash )
    V{ } clone (middle-tag) alist>hash pass-blank ;

: end-tag ( string hash -- tag )
    pass-blank char CHAR: / =
    [ <contained> incr-spot ] [ <opener> ] if ;

: skip-comment ( -- comment )
    "--" expect-string
    "--" take-until-string
    <comment>
    CHAR: > expect ;

: cdata ( -- string )
    "[CDATA[" expect-string "]]>" take-until-string ;

: directive ( -- object )
    {
        { [ "--" string-matches? ] [ skip-comment ] }
        { [ "[CDATA[" string-matches? ] [ cdata ] }
        { [ t ] [ ">" take-until-string <directive> ] }
    } cond ;

: instruction ( -- instruction )
    ! this should make sure the name doesn't include 'xml'
    "?>" take-until-string <instruction> ;

: make-tag ( -- tag/f )
    CHAR: < expect
    { { [ char dup CHAR: ! = ] [ drop incr-spot directive ] }
      { [ CHAR: ? = ] [ incr-spot instruction ] } 
      { [ t ] [
            start-tag [ <closer> ] [
                middle-tag end-tag
            ] if pass-blank CHAR: > expect
        ] } } cond ;

!   -- Overall parser with data tree

TUPLE: tag name props children ;

TUPLE: contained-tag ;
C: contained-tag ( name props -- contained-tag )
    [ >r { } <tag> r> set-delegate ] keep ;

! A stack of { tag children } pairs
SYMBOL: xml-stack

! A stack of hashtables
SYMBOL: namespace-stack

TUPLE: mismatched open close ;
: write-name ( name -- )
    dup name-space dup "" = [ drop ] [ write ":" write ] if
    name-tag write ;
M: mismatched error.
    "Mismatched tags" print
    "Opening tag: <" write dup mismatched-open write-name ">" print
    "Closing tag: </" write mismatched-close write-name ">" print ;

TUPLE: unclosed tags ;
C: unclosed ( -- unclosed )
    xml-stack get 1 tail-slice [ first opener-name ] map
    swap [ set-unclosed-tags  ] keep ;
M: unclosed error.
    "Unclosed tags" print
    "Tags: " print
    unclosed-tags [ "  <" write write ">" print ] each ;

: add-child ( object -- )
    xml-stack get peek second push ;

: push-xml-stack ( object -- )
    V{ } clone 2array xml-stack get push ;

: process-ns ( hash -- hash )
    ! This should assure all namespaces are URIs by replacing first
    [
        dup [ swap dup name-space "xmlns" =
            [ >r first r> name-tag set ] [ 2drop ] if
        ] hash-each
        T{ name f "" "xmlns" } swap hash [ first "" set ] when*
    ] make-hash ;

TUPLE: nonexist-ns name ;
M: nonexist-ns error.
    "Namespace " write nonexist-ns-name write " has not been declared" print ;

: add-ns2name ( name -- )
    dup name-space dup namespace-stack get hash-stack
    [ nip ] [ <nonexist-ns> throw ] if* swap set-name-url ;

: push-ns-stack ( hash -- )
    dup process-ns namespace-stack get push
    [ drop add-ns2name ] hash-each ;

: pop-ns-stack ( -- )
    namespace-stack get pop drop ;

GENERIC: process ( object -- )

M: f process drop ;

M: object process add-child ;

M: contained process
    [ contained-name ] keep contained-props
    dup push-ns-stack >r dup add-ns2name r>
    pop-ns-stack <contained-tag> add-child ;

M: opener process ! move add-ns2name on name to closer and fix mismatched
    dup opener-props push-ns-stack push-xml-stack ;

M: closer process
    closer-name xml-stack get pop first2 >r [ 
        opener-name [
            2dup = [ nip add-ns2name ] [ swap <mismatched> throw ] if
        ] keep
    ] keep opener-props r> <tag> add-child pop-ns-stack ;

: init-ns-stack ( -- )
    V{ H{
        { "xml" "http://www.w3.org/XML/1998/namespace" }
        { "xmlns" "http://www.w3.org/2000/xmlns" }
        { "" "" }
    } } clone
    namespace-stack set ;

: init-xml-stack ( -- )
    V{ } clone xml-stack set f push-xml-stack ;

TUPLE: xml-doc prolog before after ;
C: xml-doc ( prolog before main after -- xml-doc )
    [ set-xml-doc-after ] keep
    [ set-delegate ] keep
    [ set-xml-doc-before ] keep
    [ set-xml-doc-prolog ] keep ;

TUPLE: not-yes/no text ;
M: not-yes/no error.
    "Standalone must be either yes or no, not \"" write
    not-yes/no-text write "\"." print ;

: yes/no>bool ( string -- t/f )
    dup "yes" = [ drop t ] [
        dup "no" = [ drop f ] [
            <not-yes/no> throw
        ] if
    ] if ;

TUPLE: extra-attrs attrs ;
M: extra-attrs error.
    "Extra attributes included in xml version declaration:" print
    extra-attrs-attrs . ;

: assure-no-extra ( hash -- )
    hash-keys {
        T{ name f "" "version" f }
        T{ name f "" "encoding" f }
        T{ name f "" "standalone" f }
    } swap diff dup empty? [ drop ] [ <extra-attrs> throw ] if ; 

: concat-strings ( seq -- string )
    dup [ string? ] all?
    [ "XML prolog attributes contain undefined entities"
      <xml-string-error> throw ] unless
    concat ;

: prolog-attr ( hash name default -- value )
    >r "" swap <name> swap ?hash concat-strings
    [ r> drop ] [ r> ] if* ;    

: parse-prolog ( -- prolog )
    "<?xml" string-matches? [
        5 expect-string*
        pass-blank middle-tag "?>" expect-string
         dup assure-no-extra
    ] [ f ] if 
    [ "version" "1.0" prolog-attr ] keep
    [ "encoding" "iso-8859-1" prolog-attr ] keep
    "standalone" "no" prolog-attr yes/no>bool
    <prolog> dup prolog-data set ;

: init-xml ( string -- )
    code set
    [ spot line column ] [ 0 swap set ] each
    init-xml-stack init-ns-stack ;

UNION: any-tag tag contained-tag ;

TUPLE: notags ;
M: notags error.
    "XML document lacks a main tag" print ;

TUPLE: multitags ;
M: multitags error.
    "XML document contains multiple tags" print ;

: make-xml-doc ( prolog seq -- xml-doc )
    dup [ any-tag? ] find
    >r dup -1 = [ <notags> throw ] when
    swap cut 1 tail
    dup [ any-tag? ] contains? [ <multitags> throw ] when r>
    swap <xml-doc> ;

: (string>xml) ( -- )
    parse-text process
    more? [ make-tag process (string>xml) ] when ; inline

: string>xml ( string -- xml-doc )
    #! Produces a tree of XML nodes
    [
        init-xml
        parse-prolog (string>xml)
        xml-stack get
        dup length 1 = [ <unclosed> throw ] unless
        first second
    ] with-scope make-xml-doc ;

UNION: xml-parse-error multitags notags xml-error extra-attrs nonexist-ns
       not-yes/no unclosed mismatched xml-string-error expected no-entity ;