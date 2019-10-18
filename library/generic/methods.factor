! Copyright (C) 2006 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
IN: generic
USING: arrays definitions errors hashtables help kernel
sequences words namespaces ;

PREDICATE: array method-spec
    dup length 2 = [
        first2 generic? >r class? r> and
    ] [
        drop f
    ] if ;

TUPLE: method loc def ;

M: f method-def ;
M: f method-loc ;
M: quotation method-def ;
M: quotation method-loc drop f ;

: method ( class generic -- method/f )
    "methods" word-prop hash ;

: methods ( generic -- assoc )
    "methods" word-prop hash>alist
    [ [ first ] 2apply class-compare ] sort
    [ first2 method-def 2array ] map ;

: order ( generic -- seq )
    "methods" word-prop hash-keys [ class-compare ] sort ;

TUPLE: check-method class generic ;

: check-method ( class generic -- class generic )
    dup generic? [ <check-method> throw ] unless
    over class? [ <check-method> throw ] unless ;

: with-methods ( word quot -- )
    swap [ "methods" word-prop swap call ] keep ?make-generic ;
    inline

: define-method ( method class generic -- )
    >r bootstrap-word r> check-method
    [ set-hash ] with-methods ;

: implementors ( class -- seq )
    [ "methods" word-prop ?hash* nip ] word-subset-with ;

M: method-spec where*
    dup first2 method method-loc [ ] [ second where* ] ?if ;

M: method-spec subdefs drop f ;

M: generic subdefs
    dup "methods" word-prop hash-keys natural-sort
    [ swap 2array ] map-with ;

M: class subdefs
    [
        dup "constructor" word-prop [ , ] when*
        dup implementors natural-sort [ 2array , ] each-with
    ] { } make ;

M: method-spec forget
    first2 [ remove-hash ] with-methods ;