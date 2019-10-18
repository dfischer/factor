IN: temporary
USING: compiler kernel math sequences test ;

: (fac) ( n! i -- n! )
    dup zero? [
        drop
    ] [
        [ * ] keep 1- (fac)
    ] if ;

: fac ( n -- n! )
    1 swap (fac) ;

: small-fac-benchmark
    #! This tests fixnum math.
    1 swap [ 10 fac 10 [ 1+ / ] each max ] times ;

: big-fac-benchmark
    10000 fac 10000 [ 1+ / ] each ;

[ 1 ] [ big-fac-benchmark ] unit-test

[ 1 ] [ 1000000 small-fac-benchmark ] unit-test