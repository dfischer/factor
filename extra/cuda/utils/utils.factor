! Copyright (C) 2010 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors alien.data alien.strings arrays assocs
byte-arrays classes.struct combinators cuda.ffi io io.backend
io.encodings.utf8 kernel math.parser namespaces prettyprint
sequences ;
QUALIFIED-WITH: alien.c-types a
IN: cuda.utils

SYMBOL: cuda-device
SYMBOL: cuda-context
SYMBOL: cuda-module
SYMBOL: cuda-function
SYMBOL: cuda-launcher

SYMBOL: cuda-modules
SYMBOL: cuda-functions

ERROR: throw-cuda-error n ;

: cuda-error ( n -- )
    dup CUDA_SUCCESS = [ drop ] [ throw-cuda-error ] if ;

: init-cuda ( -- )
    0 cuInit cuda-error ;

: cuda-version ( -- n )
    a:int <c-object> [ cuDriverGetVersion cuda-error ] keep a:*int ;

: #cuda-devices ( -- n )
    a:int <c-object> [ cuDeviceGetCount cuda-error ] keep a:*int ;

: n>cuda-device ( n -- device )
    [ CUdevice <c-object> ] dip [ cuDeviceGet cuda-error ] 2keep drop a:*int ;

: enumerate-cuda-devices ( -- devices )
    #cuda-devices iota [ n>cuda-device ] map ;

: cuda-device-properties ( device -- properties )
    [ CUdevprop <c-object> ] dip
    [ cuDeviceGetProperties cuda-error ] 2keep drop
    CUdevprop memory>struct ;

: cuda-devices ( -- assoc )
    enumerate-cuda-devices [ dup cuda-device-properties ] { } map>assoc ;

: cuda-device-name ( n -- string )
    [ 256 [ <byte-array> ] keep ] dip
    [ cuDeviceGetName cuda-error ]
    [ 2drop utf8 alien>string ] 3bi ;

: cuda-device-capability ( n -- pair )
    [ a:int <c-object> a:int <c-object> ] dip
    [ cuDeviceComputeCapability cuda-error ]
    [ drop [ a:*int ] bi@ ] 3bi 2array ;

: cuda-device-memory ( n -- bytes )
    [ a:uint <c-object> ] dip
    [ cuDeviceTotalMem cuda-error ]
    [ drop a:*uint ] 2bi ;

: get-function-ptr* ( module string -- function )
    [ CUfunction <c-object> ] 2dip
    [ cuModuleGetFunction cuda-error ] 3keep 2drop a:*void* ;

: get-function-ptr ( string -- function )
    [ cuda-module get ] dip get-function-ptr* ;

: with-cuda-function ( string quot -- )
    [
        get-function-ptr* cuda-function set
    ] dip call ; inline

: create-context ( flags device -- context )
    [ CUcontext <c-object> ] 2dip
    [ cuCtxCreate cuda-error ] 3keep 2drop a:*void* ;

: destroy-context ( context -- ) cuCtxDestroy cuda-error ;

SYMBOL: cuda-libraries
cuda-libraries [ H{ } clone ] initialize

SYMBOL: current-cuda-library

TUPLE: cuda-library name path handle ;

: <cuda-library> ( name path -- obj )
    \ cuda-library new
        swap >>path
        swap >>name ;

: add-cuda-library ( name path -- )
    normalize-path <cuda-library>
    dup name>> cuda-libraries get-global set-at ;

: ?delete-at ( key assoc -- old/key ? )
    2dup delete-at* [ 2nip t ] [ 2drop f ] if ; inline

ERROR: no-cuda-library name ;

: load-module ( path -- module )
    [ CUmodule <c-object> ] dip
    [ cuModuleLoad cuda-error ] 2keep drop a:*void* ;

: unload-module ( module -- )
    cuModuleUnload cuda-error ;

: load-cuda-library ( library -- handle )
    path>> load-module ;

: lookup-cuda-library ( name -- cuda-library )
    cuda-libraries get ?at [ no-cuda-library ] unless ;

: remove-cuda-library ( name -- library )
    cuda-libraries get ?delete-at [ no-cuda-library ] unless ;

: unload-cuda-library ( name -- )
    remove-cuda-library handle>> unload-module ;


: cached-module ( module-name -- alien )
    lookup-cuda-library
    cuda-modules get-global [ load-cuda-library ] cache ;

: cached-function ( module-name function-name -- alien )
    [ cached-module ] dip
    2array cuda-functions get [ first2 get-function-ptr* ] cache ;

: launch-function* ( function -- ) cuLaunch cuda-error ;

: launch-function ( -- ) cuda-function get cuLaunch cuda-error ;

: cuda-int* ( function offset value -- )
    cuParamSeti cuda-error ;

: cuda-int ( offset value -- )
    [ cuda-function get ] 2dip cuda-int* ;

: cuda-float* ( function offset value -- )
    cuParamSetf cuda-error ;

: cuda-float ( offset value -- )
    [ cuda-function get ] 2dip cuda-float* ;

: cuda-vector* ( function offset ptr n -- )
    cuParamSetv cuda-error ;

: cuda-vector ( offset ptr n -- )
    [ cuda-function get ] 3dip cuda-vector* ;

: param-size* ( function n -- )
    cuParamSetSize cuda-error ;

: param-size ( n -- )
    [ cuda-function get ] dip param-size* ;

: launch-function-grid* ( function width height -- )
    cuLaunchGrid cuda-error ;

: launch-function-grid ( width height -- )
    [ cuda-function get ] 2dip
    cuLaunchGrid cuda-error ;

ERROR: bad-cuda-parameter parameter ;

: cuda-device-attribute ( attribute dev -- n )
    [ a:int <c-object> ] 2dip
    [ cuDeviceGetAttribute cuda-error ]
    [ 2drop a:*int ] 3bi ;

: function-block-shape* ( function x y z -- )
    cuFuncSetBlockShape cuda-error ;

: function-block-shape ( x y z -- )
    [ cuda-function get ] 3dip
    cuFuncSetBlockShape cuda-error ;

: function-shared-size* ( function n -- )
    cuFuncSetSharedSize cuda-error ;

: function-shared-size ( n -- )
    [ cuda-function get ] dip
    cuFuncSetSharedSize cuda-error ;

: cuda-device. ( n -- )
    {
        [ "Device: " write number>string print ]
        [ "Name: " write cuda-device-name print ]
        [ "Memory: " write cuda-device-memory number>string print ]
        [
            "Capability: " write
            cuda-device-capability [ number>string ] map " " join print
        ]
        [ "Properties: " write cuda-device-properties . ]
        [
            "CU_DEVICE_ATTRIBUTE_GPU_OVERLAP: " write
            CU_DEVICE_ATTRIBUTE_GPU_OVERLAP swap
            cuda-device-attribute number>string print
        ]
    } cleave ;

: cuda. ( -- )
    "CUDA Version: " write cuda-version number>string print nl
    #cuda-devices iota [ nl ] [ cuda-device. ] interleave ;
