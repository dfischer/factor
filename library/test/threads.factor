IN: temporary

USE: namespaces
USE: io
USE: test
USE: threads
USE: errors

! This only tests co-operative threads in CFactor.
! It won't give intended results in Java (or in CFactor if
! we ever get preemptive threads).

3 "x" set
[ yield 2 "x" set ] in-thread
[ 2 ] [ yield "x" get ] unit-test
[ ] [ [ flush ] in-thread flush ] unit-test
[ ] [ [ "Errors, errors" throw ] in-thread ] unit-test
yield

[ ] [ 1/2 sleep ] unit-test
[ ] [ 0.3 sleep ] unit-test
[ "hey" sleep ] unit-test-fails