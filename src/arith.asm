; Copyright (C) 2012-2016 Peter Graves <gnooth@gmail.com>

; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

file __FILE__

; ### +
inline plus, '+'
        _plus
endinline

; ### 1+
inline oneplus, '1+'
        _oneplus
endinline

; ### 2+
inline twoplus, '2+'
        _twoplus
endinline

; ### under+
code underplus, 'under+'                ; n1 n2 n3 -- n1+n3 n2
        add     [rbp + BYTES_PER_CELL], rbx
        poprbx
        next
endcode

; ### char+
inline charplus, 'char+'                ; c-addr1 -- c-addr2
; CORE 6.1.0897
        _oneplus
endinline

; ### chars
code chars, 'chars', IMMEDIATE          ; n1 -- n2
; CORE 6.1.0898
        ; nothing to do
        next
endcode

; ### cell+
inline cellplus, 'cell+'                ; a-addr1 -- a-addr2
; CORE 6.1.0880
        _cellplus
endinline

; ### cell-
inline cellminus, 'cell-'               ; a-addr1 -- a-addr2
; not in standard
        _cellminus
endinline

; ### cells
inline cells, 'cells'                   ; n1 -- n2
; CORE 6.1.0890
; "n2 is the size in address units of n1 cells"
        _cells
endinline

; ### -
inline minus, '-'
        _minus
endinline

; ### swap-
inline swapminus, 'swap-'
        _swapminus
endinline

; ### 1-
inline oneminus, '1-'
        _oneminus
endinline

; ### *
code star, '*'                          ; n1 n2 -- n3
; CORE
        imul    rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### m*
code mstar, 'm*'                        ; n1 n2 -- d
; CORE
; "d is the signed product of n1 times n2."
        mov     rax, rbx
        imul    qword [rbp]
        mov     [rbp], rax
        mov     rbx, rdx
        next
endcode

; ### 2*
inline twostar, '2*'
        _twostar
endinline

; ### /
code slash, '/'                         ; n1 n2 -- n3
; CORE
        mov     rax, [rbp]
        cqo                             ; sign-extend rax into rdx:rax
        idiv    rbx                     ; quotient in rax, remainder in rdx
        mov     rbx, rax
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### mod
code mod, 'mod'                          ; n1 n2 -- n3
; CORE
        mov     rax, [rbp]
        cqo                             ; sign-extend rax into rdx:rax
        idiv    rbx                     ; quotient in rax, remainder in rdx
        mov     rbx, rdx
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### /mod
code slmod, '/mod'                      ; n1 n2 -- remainder quotient
; CORE
        mov     rax, [rbp]
        cqo                             ; sign-extend rax into rdx:rax
        idiv    rbx                     ; quotient in rax, remainder in rdx
        mov     [rbp], rdx              ; remainder
        mov     rbx, rax                ; quotient
        next
endcode

; ### */mod
code starslashmod, '*/mod'              ; n1 n2 n3 -- remainder quotient
; CORE
; "Multiply n1 by n2 producing the intermediate double-cell result d. Divide d
; by n3 producing the single-cell remainder n4 and the single-cell quotient n5."
        mov     rax, [rbp + BYTES_PER_CELL]
        imul    qword [rbp]             ; result in rdx:rax
        lea     rbp, [rbp + BYTES_PER_CELL]
        idiv    rbx                     ; quotient in rax, remainder in rdx
        mov     rbx, rax                ; quotient in rbx
        mov     [rbp], rdx              ; remainder in [rbp]
        next
endcode

; ### */
code starslash, '*/'                    ; n1 n2 n3 -- n4
; CORE
        _ starslashmod
        _nip
        next
endcode

; ### 2/
code twoslash, '2/'
        sar     rbx, 1
        next
endcode

; ### um*
code umstar, 'um*'                      ; u1 u2 -- ud
; 6.1.2360 CORE
; "Multiply u1 by u2, giving the unsigned double-cell product ud. All
; values and arithmetic are unsigned."
        mov     rax, rbx
        mul     qword [rbp]
        mov     [rbp], rax
        mov     rbx, rdx
        next
endcode

; ### um/mod
code umslmod, 'um/mod'                  ; ud u1 -- u2 u3
; 6.1.2370 CORE
        mov     rdx, [rbp]
        mov     rax, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL]
        div     rbx                     ; remainder in RDX, quotient in RAX
        mov     [rbp], rdx
        mov     rbx, rax
        next
endcode

; ### fm/mod
code fmslmod, 'fm/mod'                  ; d1 n1 -- n2 n3
; CORE n2 is remainder, n3 is quotient
; gforth
        _duptor
        _ dup
        _zlt
        _if fmslmod1
        _negate
        _ tor
        _ dnegate
        _ rfrom
        _then fmslmod1
        _ over
        _zlt
        _if fmslmod2
        _ tuck
        _ plus
        _ swap
        _then fmslmod2
        _ umslmod
        _ rfrom
        _zlt
        _if fmslmod3
        _ swap
        _negate
        _ swap
        _then fmslmod3
        next
endcode

; ### sm/rem
code smslrem, 'sm/rem'                  ; d1 n1 -- n2 n3
; CORE
; gforth
        _ over
        _ tor
        _ dup
        _ tor
        _ abs_
        _ rrot
        _ dabs
        _ rot
        _ umslmod
        _ rfrom
        _ rfetch
        _ xor
        _zlt
        _if smslrem1
        _negate
        _then smslrem1
        _ rfrom
        _zlt
        _if smslrem2
        _ swap
        _negate
        _ swap
        _then smslrem2
        next
endcode

; ### mu/mod
code muslmod, 'mu/mod'                  ; d n -- rem dquot
        _ tor
        _zero
        _ rfetch
        _ umslmod
        _ rfrom
        _ swap
        _ tor
        _ umslmod
        _ rfrom
        next
endcode

; ### abs
code abs_, 'abs'
        or      rbx, rbx
        jns     abs1
        neg     rbx
abs1:
        next
endcode

; ### =
inline equal, '='                       ; x1 x2 -- flag
; CORE
        _equal
endinline

; ### <>
inline notequal, '<>'                   ; x1 x2 -- flag
; CORE EXT
        _notequal
endinline

; ### >
inline gt, '>'                          ; n1 n2 -- flag
        cmp     [rbp], rbx
        setg    bl
        neg     bl
        movsx   rbx, bl
        lea     rbp, [rbp + BYTES_PER_CELL]
endinline

; ### >=
inline ge, '>='                         ; n1 n2 -- flag
        cmp     [rbp], rbx
        setge   bl
        neg     bl
        movsx   rbx, bl
        lea     rbp, [rbp + BYTES_PER_CELL]
endinline

; ### <
inline lt, '<'                          ; n1 n2 -- flag
; CORE
        cmp     [rbp], rbx
        setl    bl
        neg     bl
        movsx   rbx, bl
        lea     rbp, [rbp + BYTES_PER_CELL]
endinline

; ### <=
inline le, '<='                         ; n1 n2 -- flag
        cmp     [rbp], rbx
        setle   bl
        neg     bl
        movsx   rbx, bl
        lea     rbp, [rbp + BYTES_PER_CELL]
endinline

; ### u<
inline ult, 'u<'
; CORE
        _ult
endinline

; ### u>
inline ugt, 'u>'
; CORE EXT
        _ugt
endinline

; ### within
code within, 'within'                   ; n min max -- flag
; CORE EXT
; return true if min <= n < max
; implementation adapted from Win32Forth
        mov     rax, [rbp]
        mov     rdx, [rbp + BYTES_PER_CELL]
        sub     rbx, rax
        sub     rdx, rax
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        sub     rdx, rbx
        sbb     rbx, rbx
        next
endcode

; ### between
code between, 'between'                 ; n min max -- flag
; return true if min <= n <= max
; implementation adapted from Win32Forth
        _oneplus
        mov     rax, [rbp]
        mov     rdx, [rbp + BYTES_PER_CELL]
        sub     rbx, rax
        sub     rdx, rax
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        sub     rdx, rbx
        sbb     rbx, rbx
        next
endcode

; ### 0=
inline zeq, '0='
; CORE
        _zeq
endinline

; ### 0<>
inline zne, '0<>'
; CORE EXT
        _zne
endinline

; ### 0>
inline zgt, '0>'
; CORE EXT
        _zgt
endinline

; ### 0>=
code zge, '0>='
        _zge
        next
endcode

; ### 0<
inline zlt, '0<'
; CORE
        _zlt
endinline

; ### s>d
inline stod, 's>d'                      ; n -- d
; CORE
        _stod
endinline

; ### min
code min, 'min'                         ; n1 n2 -- n3
        popd    rax
        cmp     rax, rbx
        jge     .1
        mov     rbx, rax
.1:
        next
endcode

; ### max
code max, 'max'                         ; n1 n2 -- n3
        popd    rax
        cmp     rax, rbx
        jle     .1
        mov     rbx, rax
.1:
        next
endcode

; ### lshift
inline lshift, 'lshift'                 ; x1 u -- x2
; CORE
        mov     ecx, ebx
        poprbx
        shl     rbx, cl
endinline

; ### rshift
inline rshift, 'rshift'                 ; x1 u -- x2
; CORE
        mov     ecx, ebx
        poprbx
        shr     rbx, cl
endinline

; ### rol
code rol, 'rol'
        mov     ecx, ebx
        poprbx
        rol     rbx, cl
        next
endcode

; ### and
inline and, 'and'                       ; x1 x2 -- x3
; CORE
        _and
endinline

; ### or
inline or, 'or'                         ; x1 x2 -- x3
; CORE
        or      rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
endinline

; ### xor
inline xor, 'xor'                       ; x1 x2 -- x3
; CORE
        _xor
endinline

; ### invert
inline invert, 'invert'                 ; x1 -- x2
; CORE
; "Invert all bits of x1, giving its logical inverse x2."
        not     rbx
endinline

; ### negate
inline negate, 'negate'                 ; n1 -- n2
; CORE
        _negate
endinline
