! Copyright (C) 2009 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: continuations decimals grouping kernel kernel.private literals
locals math math.functions math.order random tools.test ;
in: decimals.tests

{ t } [
    decimal: 12.34 decimal: 00012.34000 =
] unit-test

: random-test-int ( -- n )
    10 random 2 random 0 = [ neg ] when ;

: random-test-decimal ( -- decimal )
    random-test-int random-test-int <decimal> ;

ERROR: decimal-test-failure D1 D2 quot ;

:: (test-decimal-op) ( D1 D2 quot1 quot2 -- ? )
    D1 D2
    quot1 [ decimal>ratio >float ] compose
    [ [ decimal>ratio ] bi@ quot2 call( obj obj -- obj ) >float ] 2bi -.1 ~
    [ t ] [ D1 D2 quot1 decimal-test-failure ] if ; inline

: test-decimal-op ( quot1 quot2 -- ? )
    [ random-test-decimal random-test-decimal ] 2dip (test-decimal-op) ; inline

{ t } [ 1000 [ drop [ D+ ] [ + ] test-decimal-op ] all-integers? ] unit-test
{ t } [ 1000 [ drop [ D- ] [ - ] test-decimal-op ] all-integers? ] unit-test
{ t } [ 1000 [ drop [ D* ] [ * ] test-decimal-op ] all-integers? ] unit-test
{ t } [
    1000 [
        drop
        [ [ 100 D/ ] [ /f ] test-decimal-op ]
        [ ${ KERNEL-ERROR ERROR-DIVIDE-BY-ZERO f f } = ] recover
    ] all-integers?
] unit-test

{ t } [
    { decimal: 0. decimal: .0 decimal: 0.0 decimal: 00.00 decimal: . } all-equal?
] unit-test

{ t } [ T{ decimal f 90 0 } T{ decimal f 9 1 } = ] unit-test

{ t } [ decimal: 1 decimal: 2 before? ] unit-test
{ f } [ decimal: 2 decimal: 2 before? ] unit-test
{ f } [ decimal: 3 decimal: 2 before? ] unit-test
{ f } [ decimal: -1 decimal: -2 before? ] unit-test
{ f } [ decimal: -2 decimal: -2 before? ] unit-test
{ t } [ decimal: -3 decimal: -2 before? ] unit-test
{ t } [ decimal: .5 decimal: 0 decimal: 1.0 between? ] unit-test