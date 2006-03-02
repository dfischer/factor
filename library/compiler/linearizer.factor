! Copyright (C) 2004, 2006 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: arrays compiler-backend hashtables inference kernel
namespaces sequences words ;
IN: compiler-frontend

SYMBOL: node-stack

: >node node-stack get push ;
: node> node-stack get pop ;
: node@ node-stack get peek ;

DEFER: iterate-nodes

: iterate-children ( quot -- )
    node@ node-children [ swap iterate-nodes ] each ;

: iterate-next ( -- node ) node@ node-successor ;

: iterate-nodes ( node quot -- )
    over [
        [ swap >node call node> drop ] keep
        over [ iterate-nodes ] [ 2drop ] if
    ] [
        2drop
    ] if ; inline

: with-node-iterator ( quot -- )
    [
        V{ } clone node-stack set call
    ] with-scope ; inline

DEFER: #terminal?

PREDICATE: #merge #terminal-merge node-successor #terminal? ;

UNION: #terminal POSTPONE: f #return #values #terminal-merge ;

: tail-call? ( -- ? )
    node-stack get [ node-successor ] map [ #terminal? ] all? ;

GENERIC: linearize* ( node -- next )

: linearize-child ( node -- )
    [ node@ linearize* ] iterate-nodes ;

! A map from words to linear IR.
SYMBOL: linearized

! Renamed labels. To avoid problems with labels with the same
! name in different scopes.
SYMBOL: renamed-labels

: make-linear ( word quot -- )
    [
        swap >r [ %prologue , call ] { } make r>
        linearized get set-hash
    ] with-node-iterator ; inline

: linearize-1 ( word node -- )
    swap [ linearize-child ] make-linear ;

: init-linearizer ( -- )
    H{ } clone linearized set
    H{ } clone renamed-labels set ;

: linearize ( word dataflow -- linearized )
    #! Outputs a hashtable mapping from labels to their
    #! respective linear IR.
    init-linearizer linearize-1 linearized get ;

M: node linearize* ( node -- next ) drop iterate-next ;

: linearize-call ( label -- next )
    tail-call? [
        %jump , f
    ] [
        %call , iterate-next
    ] if ;

: rename-label ( label -- label )
    <label> dup rot renamed-labels get set-hash ;

: renamed-label ( label -- label )
    renamed-labels get hash ;

: linearize-call-label ( label -- next )
    rename-label linearize-call ;

M: #label linearize* ( node -- next )
    #! We remap the IR node's label to a new label object here,
    #! to avoid problems with two IR #label nodes having the
    #! same label in different lexical scopes.
    dup node-param dup linearize-call-label >r
    renamed-label swap node-child linearize-1
    r> ;

: in-1 0 0 %peek-d , ;
: in-2 0 1 %peek-d ,  1 0 %peek-d , ;
: in-3 0 2 %peek-d ,  1 1 %peek-d ,  2 0 %peek-d , ;
: out-1 T{ vreg f 0 } 0 %replace-d , ;

: intrinsic ( #call -- quot ) node-param "intrinsic" word-prop ;

: if-intrinsic ( #call -- quot )
    dup node-successor #if?
    [ node-param "if-intrinsic" word-prop ] [ drop f ] if ;

: linearize-if ( node label -- next )
    <label> dup >r >r >r node-children first2 linearize-child
    r> r> %jump-label , %label , linearize-child r> %label ,
    iterate-next ;

M: #call linearize* ( node -- )
    dup if-intrinsic [
        >r <label> 2dup r> call
        >r node-successor r> linearize-if
    ] [
        dup intrinsic
        [ call iterate-next ] [ node-param linearize-call ] if*
    ] if* ;

M: #call-label linearize* ( node -- next )
    node-param renamed-label linearize-call ;

M: #if linearize* ( node -- next )
    in-1 -1 %inc-d , <label> dup 0 %jump-t , linearize-if ;

: dispatch-head ( vtable -- label/node )
    #! Output the jump table insn and return a list of
    #! label/branch pairs.
    in-1 -1 %inc-d , 0 %dispatch ,
    [ <label> dup %target-label ,  2array ] map ;

: dispatch-body ( label/node -- )
    <label> swap [
        first2 %label , linearize-child dup %jump-label ,
    ] each %label , ;

M: #dispatch linearize* ( node -- next )
    #! The parameter is a list of nodes, each one is a branch to
    #! take in case the top of stack has that type.
    node-children dispatch-head dispatch-body iterate-next ;

M: #return linearize* drop %return , f ;
