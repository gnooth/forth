\ Copyright (C) 2015 Peter Graves <gnooth@gmail.com>

\ This program is free software: you can redistribute it and/or modify
\ it under the terms of the GNU General Public License as published by
\ the Free Software Foundation, either version 3 of the License, or
\ (at your option) any later version.

\ This program is distributed in the hope that it will be useful,
\ but WITHOUT ANY WARRANTY; without even the implied warranty of
\ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
\ GNU General Public License for more details.

\ You should have received a copy of the GNU General Public License
\ along with this program.  If not, see <http://www.gnu.org/licenses/>.

only forth

\ TEMPORARY
[defined] assembler [if] warning off [then]

[undefined] assembler [if] vocabulary assembler [then]

[undefined] x86-64 [if] include-system-file x86-64.forth [then]

only forth also x86-64 also assembler definitions

decimal

: .2  ( ub -- )  base@ >r hex 0 <# # # #> r> base! type space ;

32 buffer: tbuf

: >tbuf ( byte -- ) tbuf count + c! 1 tbuf c+! ;

: .tbuf ( -- ) tbuf count bounds ?do i c@ .2 loop ;

defer byte,

\ ' .2 is byte,
' >tbuf is byte,

: make-modrm-byte ( mod reg rm -- byte )
    local rm
    local reg
    local mod
    mod 6 lshift
    reg 3 lshift +
    rm + ;

-1 value sreg \ source register
64 value ssize
-1 value dreg \ destination register
64 value dsize

 0 value prefix-byte

: prefix, ( -- ) prefix-byte ?dup if byte, then ;

false value dest?

: -> true to dest? ;

: define-reg64 ( reg# -- )
    create ,
    does>
        @ dest? if
            to dreg 64 to dsize
        else
            to sreg 64 to ssize
        then
;

 0 define-reg64 rax
 1 define-reg64 rcx
 2 define-reg64 rdx
 3 define-reg64 rbx
 4 define-reg64 rsp
 5 define-reg64 rbp
 6 define-reg64 rsi
 7 define-reg64 rdi
 8 define-reg64 r8
 9 define-reg64 r9
10 define-reg64 r10
11 define-reg64 r11
12 define-reg64 r12
13 define-reg64 r13
14 define-reg64 r14
15 define-reg64 r15

: extreg? ( reg64 -- flag )
    8 and ;

: ;opc ( -- )
    \ reset assembler for next instruction
    -1 to sreg
    -1 to dreg
    64 to ssize
    64 to dsize
     0 to prefix-byte
     0 to dest?

    \ for testing only!
    $c3 >tbuf
    .tbuf
    tbuf 1+ ( skip count byte ) disasm

    0 tbuf c!
;

: ret, ( -- ) $c3 byte, ;opc ;

: pop,  ( -- )
    sreg -1 = abort" no source register"
    sreg 7 > if
        \ extended register
        $41 to prefix-byte prefix,
        -8 +to sreg
    then
    sreg $58 + byte,
    ;opc ;

: push, ( -- )
    sreg -1 = abort" no source register"
    sreg 8 and if
        \ extended register
        $41 to prefix-byte prefix,
        -8 +to sreg
    then
    sreg $50 + byte,
    ;opc ;

: mov,  ( -- )
    sreg -1 <> dreg -1 <> and if
        ssize 64 = dsize 64 = or if
            $48 to prefix-byte
        then
        sreg extreg? if
            prefix-byte rex.r or to prefix-byte
            -8 +to sreg
        then
        dreg extreg? if
            prefix-byte rex.b or to prefix-byte
            -8 +to dreg
        then
        prefix,
        $89 byte,
        3 sreg dreg make-modrm-byte byte,
    then
    ;opc
;

: }asm ( -- ) previous ; immediate

also forth definitions

: asm{ ( -- ) also assembler ; immediate
