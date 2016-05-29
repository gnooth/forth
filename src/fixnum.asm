; Copyright (C) 2016 Peter Graves <gnooth@gmail.com>

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

; ### MOST_POSITIVE_FIXNUM
code MOST_POSITIVE_FIXNUM, 'MOST_POSITIVE_FIXNUM'
; Return value is untagged.
        _lit 1
        _lit 63 - TAG_BITS
        _ lshift
        _oneminus
        next
endcode

; ### MOST_NEGATIVE_FIXNUM
code MOST_NEGATIVE_FIXNUM, 'MOST_NEGATIVE_FIXNUM'
; Return value is untagged.
        _ MOST_POSITIVE_FIXNUM
        _oneplus
        _negate
        next
endcode

; ### most-positive-fixnum
code most_positive_fixnum, 'most-positive-fixnum'
; Returns tagged fixnum.
        _lit 1
        _lit 63 - TAG_BITS
        _ lshift
        _oneminus
        _tag_fixnum
        next
endcode

; ### most-negative-fixnum
code most_negative_fixnum, 'most-negative-fixnum'
; Returns tagged fixnum.
        _ MOST_NEGATIVE_FIXNUM
        _tag_fixnum
        next
endcode

; ### fixnum?
code fixnum?, 'fixnum?'                 ; x -- t|f
        _fixnum?
        _tag_boolean
        next
endcode

; ### error-not-fixnum
code error_not_fixnum, 'error-not-fixnum' ; x --
        ; REVIEW
        _drop
        _true
        _abortq "not a fixnum"
        next
endcode

%macro _check_fixnum 0
        mov     eax, ebx
        and     eax, TAG_MASK
        cmp     eax, FIXNUM_TAG
        jne     error_not_fixnum
        _untag_fixnum
%endmacro

; ### check-fixnum
code check_fixnum, 'check-fixnum'       ; fixnum -- untagged-fixnum
        _check_fixnum
        next
endcode

; ### fixnum<
inline fixnum_lt, 'fixnum<'             ; x y -- t|f
; No type checking.
        mov     eax, t_value
        cmp     [rbp], rbx
        mov     ebx, f_value
        cmovl   ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
endinline

; ### <
code feline_lt, '<'                     ; x y -- t|f
; FIXME optimize
        _check_fixnum
        _swap
        _check_fixnum
        _swap
        _ fixnum_lt
        next
endcode

; ### fixnum>=
code fixnum_ge, 'fixnum>='              ; x y -- t|f
; No type checking.
        mov     eax, t_value
        cmp     [rbp], rbx
        mov     ebx, f_value
        cmovge  ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### >=
code feline_ge, '>='                    ; x y -- t|f
; FIXME optimize
        _ check_fixnum
        _swap
        _ check_fixnum
        _swap
        _ fixnum_ge
        next
endcode

; ### fixnum+
inline fixnum_plus, 'fixnum+'           ; x y -- x+y
; No type checking.
        sub     rbx, FIXNUM_TAG
        _plus
endinline

; ### +
code feline_plus, '+'                   ; x y -- x+y
        _check_fixnum
        _swap
        _check_fixnum
        _plus
        _tag_fixnum
        next
endcode

; ### fixnum-
inline fixnum_minus, 'fixnum-'          ; x y -- x-y
; No type checking.
        mov     rax, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        sub     rax, rbx
        add     rax, FIXNUM_TAG
        mov     rbx, rax
endinline

; ### -
code feline_minus, '-'                  ; x y -- x-y
        _check_fixnum
        _swap
        _check_fixnum
        sub     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        _tag_fixnum
        next
endcode

; ### fixnum*
code fixnum_multiply, 'fixnum*'         ; x y -- x*y
; No type checking.
        _untag_2_fixnums
        imul    rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        _tag_fixnum
        next
endcode

; ### *
code feline_multiply, '*'               ; x y -- x*y
        _ check_fixnum
        _swap
        _ check_fixnum
        imul    rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        _tag_fixnum
        next
endcode

%macro _divide 0
        mov     rax, [rbp]
        cqo                             ; sign-extend rax into rdx:rax
        idiv    rbx                     ; quotient in rax, remainder in rdx
        mov     rbx, rax
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

; ### fixnum/i
code fixnum_divide, 'fixnum/i'          ; n1 n2 -- n3
        _untag_2_fixnums
        _divide
        _tag_fixnum
        next
endcode

; ### /
code feline_divide, '/'
        _ check_fixnum
        _swap
        _ check_fixnum
        _swap
        _divide
        _tag_fixnum
        next
endcode

%unmacro _divide 0

%macro _mod 0
        mov     rax, [rbp]
        cqo                             ; sign-extend rax into rdx:rax
        idiv    rbx                     ; quotient in rax, remainder in rdx
        mov     rbx, rdx
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

; ### fixnum-mod
code fixnum_mod, 'fixnum-mod'           ; n1 n2 -- n3
        _untag_2_fixnums
        _mod
        _tag_fixnum
        next
endcode

; ### mod
code feline_mod, 'mod'                  ; n1 n2 -- n3
        _ check_fixnum
        _swap
        _ check_fixnum
        _swap
        _mod
        _tag_fixnum
        next
endcode

%unmacro _mod 0

; ### fixnum-bitand
code fixnum_bitand, 'fixnum-bitand'     ; n1 n2 -- n3
        _untag_2_fixnums
        _and
        _tag_fixnum
        next
endcode

; ### bitand
code bitand, 'bitand'
        _ check_fixnum
        _swap
        _ check_fixnum
        _and
        _tag_fixnum
        next
endcode
