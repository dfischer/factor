USING: errors definitions generic kernel kernel-internals math
parser sequences test words hashtables namespaces ;
IN: temporary

[ t ] [ \ tuple-class \ class class< ] unit-test
[ f ] [ \ class \ tuple-class class< ] unit-test

TUPLE: rect x y w h ;
C: rect
    [ set-rect-h ] keep
    [ set-rect-w ] keep
    [ set-rect-y ] keep
    [ set-rect-x ] keep ;
    
: move ( x rect -- )
    [ rect-x + ] keep set-rect-x ;

[ f ] [ 10 20 30 40 <rect> dup clone 5 swap [ move ] keep = ] unit-test

[ t ] [ 10 20 30 40 <rect> dup clone 0 swap [ move ] keep = ] unit-test

GENERIC: delegation-test
M: object delegation-test drop 3 ;
TUPLE: quux-tuple ;
C: quux-tuple ;
M: quux-tuple delegation-test drop 4 ;
TUPLE: quuux-tuple ;
C: quuux-tuple
    [ set-delegate ] keep ;

[ 3 ] [ <quux-tuple> <quuux-tuple> delegation-test ] unit-test

GENERIC: delegation-test-2
TUPLE: quux-tuple-2 ;
C: quux-tuple-2 ;
M: quux-tuple-2 delegation-test-2 drop 4 ;
TUPLE: quuux-tuple-2 ;
C: quuux-tuple-2
    [ set-delegate ] keep ;

[ 4 ] [ <quux-tuple-2> <quuux-tuple-2> delegation-test-2 ] unit-test

! Make sure we handle changing shapes!

[
    FORGET: point
    FORGET: point?
    FORGET: point-x
    TUPLE: point x y ;
    C: point [ set-point-y ] keep [ set-point-x ] keep ;
    
    100 200 <point>
    
    ! Use eval to sequence parsing explicitly
    "IN: temporary TUPLE: point x y z ;" eval
    
    point-x
] unit-test-fails

TUPLE: predicate-test ;
: predicate-test drop f ;

[ t ] [ <predicate-test> predicate-test? ] unit-test

PREDICATE: tuple silly-pred
    class \ rect = ;

GENERIC: area
M: silly-pred area dup rect-w swap rect-h * ;

TUPLE: circle radius ;
M: circle area circle-radius sq pi * ;

[ 200 ] [ T{ rect f 0 0 10 20 } area ] unit-test

[ ] [ "IN: temporary  SYMBOL: #x  TUPLE: #x ;" eval ] unit-test

! Hashcode breakage
TUPLE: empty ;
[ t ] [ <empty> hashcode fixnum? ] unit-test

TUPLE: delegate-clone ;

[ T{ delegate-clone T{ empty f } } ]
[ T{ delegate-clone T{ empty f } } clone ] unit-test

FORGET: empty

[ t ] [ \ null \ delegate-clone class< ] unit-test
[ f ] [ \ object \ delegate-clone class< ] unit-test
[ f ] [ \ object \ delegate-clone class< ] unit-test
[ t ] [ \ delegate-clone \ tuple class< ] unit-test
[ f ] [ \ tuple \ delegate-clone class< ] unit-test

! Compiler regression
[ t ] [ [ t length ] catch no-method-object ] unit-test

[ "<constructor-test>" ]
[ "TUPLE: constructor-test ; C: constructor-test ;" eval word word-name ] unit-test

! There was a typo in check-shape; it would unintern the wrong
! words!
[ "temporary-1" ]
[
    "IN: temporary-1 SYMBOL: foobar IN: temporary TUPLE: foobar ;" eval
    "foobar" { "temporary" "temporary-1" } [ vocab ] map
    hash-stack word-vocabulary
] unit-test

TUPLE: size-test a b c d ;

[ t ] [
    T{ size-test } array-capacity
    size-test tuple-size =
] unit-test

GENERIC: <yo-momma>

TUPLE: yo-momma ;

[ f ] [ \ <yo-momma> generic? ] unit-test

! Test forget
[ t ] [ \ yo-momma class? ] unit-test
[ ] [ \ yo-momma forget ] unit-test
[ f ] [ \ yo-momma typemap get hash-values memq? ] unit-test

[ f ] [ \ yo-momma interned? ] unit-test
[ f ] [ \ yo-momma? interned? ] unit-test
[ f ] [ \ <yo-momma> interned? ] unit-test

! Test if C: sets last word correctly
[ ] [ "IN: temporary TUPLE: C:-test ; C: C:-test ( -- x ) ;" eval ] unit-test
[ "<C:-test>" ] [ word word-name ] unit-test
[ "( -- x )" ] [ "<C:-test>" "temporary" lookup stack-effect effect>string ] unit-test

TUPLE: loc-recording ;

[ f ] [ \ loc-recording where not ] unit-test
[ f ] [ \ <loc-recording> where not ] unit-test
[ f ] [ \ loc-recording? where not ] unit-test