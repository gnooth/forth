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

; ### dip
code dip, 'dip'                         ; x quot -- x
; Removes x, calls quot, restores x to top of stack after quot returns.
        _ callable_code_address         ; code address in rbx
        mov     rax, [rbp]              ; x in rax
        push    rax
        mov     rax, rbx
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        call    rax
        pushrbx
        pop     rbx
        next
endcode

; ### 2dip
code twodip, '2dip'                     ; x y quot -- x y
; Remove x and y, call quot, restore x and y to top of stack after
; quot returns.
        _ callable_code_address         ; code address in rbx
        mov     rax, rbx                ; code address in rax
        poprbx                          ; -- x y
        _tor
        _tor
        call    rax
        _rfrom
        _rfrom
        next
endcode

; ### keep
code keep, 'keep'                       ; .. x quot -- .. x
; Factor
; "Call a quotation with a value on the stack, restoring the value when
; the quotation returns."
        _ callable_code_address         ; code address in rbx
        mov     rax, rbx                ; code address in rax
        poprbx
        push    rbx
        call    rax
        pushrbx
        pop     rbx
        next
endcode

; ### 2keep
code twokeep, '2keep'                   ; .. x y quot -- .. x y
        _ callable_code_address         ; code address in rbx
        mov     rax, rbx                ; code address in rax
        poprbx
        push    qword [rbp]
        push    rbx
        call    rax
        _tworfrom
        next
endcode

; ### bi
code bi, 'bi'                           ; x quot1 quot2 --
; Apply quot1 to x, then apply quot2 to x.
        _ callable_code_address
        _tor
        _ keep
        pop     rax
        call    rax
        next
endcode

; ### 2bi
code twobi, '2bi'                       ; x y quot1 quot2 --
; Apply quot1 to x and y, then apply quot2 to x and y.
        _ callable_code_address
        _tor
        _ twokeep
        pop     rax
        call    rax
        next
endcode

; ### bi@
code bi_at, 'bi@'                       ; x y quot --
; Apply quot to x, then to y.
; Quotation must have stack effect ( obj -- ... ).

        ; protect callable from gc
        push    rbx

        _ callable_code_address

        push    r12                     ; save non-volatile register
        mov     r12, rbx                ; address to call in r12
        mov     rax, [rbp]              ; y in rax
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2] ; -- x
        push    rax                     ; save y
        call    r12
        pushrbx
        pop     rbx                     ; -- y
        call    r12
        pop     r12

        ; drop callable
        pop     rax

        next
endcode

; ### ?
code question, '?'                      ; ? true false -- true/false
        cmp     qword [rbp + BYTES_PER_CELL], f_value
        mov     rax, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        cmovne  rbx, rax
        next
endcode
