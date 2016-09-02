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

%macro  _quotation_array 0              ; quotation -- array
        _slot1
%endmacro

%macro  _this_quotation_array 0         ; -- array
        _this_slot1
%endmacro

%macro  _this_quotation_set_array 0     ; array --
        _this_set_slot1
%endmacro

%macro  _quotation_code_address 0       ; quotation -- code-address
        _slot2
%endmacro

%macro  _quotation_set_code_address 0   ; code-address quotation --
        _set_slot2
%endmacro

%macro  _this_quotation_set_code_address 0 ; code-address --
        _this_set_slot2
%endmacro

; ### quotation?
code quotation?, 'quotation?'           ; handle -- ?
        _ ?unhandle                     ; -- object/f
        cmp     rbx, f_value
        je      .exit
        cmp     word [rbx], OBJECT_TYPE_QUOTATION
        jne     .false
        mov     ebx, t_value
.exit:
        _return
.false:
        mov     ebx, f_value
        next
endcode

; ### error-not-quotation
code error_not_quotation, 'error-not-quotation' ; x --
        ; REVIEW
        _drop
        _true
        _abortq "not a quotation"
        next
endcode

; ### check-quotation
code check_quotation, 'check-quotation' ; handle -- quotation
        _ unhandle                      ; -- object/0
        test    rbx, rbx
        jz      .error
        cmp     word [rbx], OBJECT_TYPE_QUOTATION
        jne     .error
        _return
.error:
        _ error_not_quotation
        next
endcode

; ### array>quotation
code array_to_quotation, 'array>quotation' ; array -- quotation
; 3 cells: object header, array, code address

        _lit 3
        _ allocate_cells

        push    this_register
        mov     this_register, rbx
        poprbx

        _this_object_set_type OBJECT_TYPE_QUOTATION

        _this_quotation_set_array

        _zero
        _this_quotation_set_code_address

        pushrbx
        mov     rbx, this_register      ; -- quotation

        ; Return handle.
        _ new_handle                    ; -- handle

        pop     this_register
        next
endcode

; ### ~quotation
code destroy_quotation, '~quotation'    ; handle --
        _ check_quotation               ; -- quotation
        _ destroy_quotation_unchecked
        next
endcode

; ### ~quotation-unchecked
code destroy_quotation_unchecked, '~quotation-unchecked' ; quotation --
        _dup
        _quotation_code_address
        _?dup_if .1
        _ free_executable
        _then .1

        _ in_gc?
        _zeq_if .2
        _dup
        _ release_handle_for_object
        _then .2

        ; Zero out the object header so it won't look like a valid object
        ; after it has been destroyed.
        xor     eax, eax
        mov     [rbx], rax

        _ ifree

        next
endcode

; ### quotation-array
code quotation_array, 'quotation-array' ; quotation -- array
        _ check_quotation
        _quotation_array
        next
endcode

; ### quotation-code-address
code quotation_code_address, 'quotation-code-address' ; quotation -- code-address
        _ check_quotation
        _quotation_code_address
        next
endcode

; ### quotation-set-code-address
code quotation_set_code_address, 'quotation-set-code-address' ; code-address quotation --
        _ check_quotation
        _quotation_set_code_address
        next
endcode

; ### call
code call_quotation, 'call'             ; callable --
        _dup
        _ curry?
        _tagged_if .1
        _ curry_code_address
        mov     rax, rbx
        poprbx
        call    rax
        _return
        _then .1

        _dup
        _ quotation_code_address
        _dup_if .2
        _nip                            ; -- code-address
        _else .2
        _drop
        _ compile_quotation             ; -- code-address
        _then .2
        mov     rax, rbx
        poprbx
        call    rax

        next
endcode

; ### callable-code-address
code callable_code_address, 'callable-code-address' ; callable -- code-address
        _dup
        _ quotation?
        _tagged_if .1
        _dup
        _ quotation_code_address        ; -- quotation code-address
        _?dup_if .2
        _nip
        _else .2
        _ compile_quotation
        _then .2
        _return
        _then .1

        _dup
        _ curry?
        _tagged_if .3
        _ curry_code_address
        _return
        _then .3

        ; xt
        _fetch
        next
endcode
