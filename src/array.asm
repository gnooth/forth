; Copyright (C) 2015-2016 Peter Graves <gnooth@gmail.com>

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

; ### array?
code array?, 'array?'                   ; handle -- ?
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_type                    ; -- object-type
        _lit OBJECT_TYPE_ARRAY
        _eq?
        _return
        _then .2
        _then .1
        mov     ebx, f_value
        next
endcode

; ### error-not-array
code error_not_array, 'error-not-array' ; x --
        ; REVIEW
        _error "not an array"
        next
endcode

; ### check-array
code check_array, 'check-array'         ; handle -- array
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object/0
        _dup_if .2
        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_ARRAY
        _equal
        _if .3
        _return
        _then .3
        _then .2
        _then .1

        _ error_not_array
        next
endcode

; ### array-length
code array_length, 'array-length'       ; array -- length
        _ check_array
        _array_length
        _tag_fixnum
        next
endcode

; ### <array>
code new_array, '<array>'               ; length element -- handle

        _swap
        _untag_fixnum
        _swap

new_array_untagged:
        push    this_register

        _over                           ; -- length element length
        _cells
        _lit 16
        _plus                           ; -- length element total-size
        _ allocate_object               ; -- length element array
        popd    this_register           ; -- length element

        ; Zero all bits of object header.
        xor     eax, eax
        mov     [this_register], rax

        _this_object_set_type OBJECT_TYPE_ARRAY
        _this_object_set_flags OBJECT_ALLOCATED_BIT

        _over                           ; -- length element length
        _this_array_set_length          ; -- length element

        popd    rax                     ; element in rax
        popd    rcx                     ; length in rcx
%ifdef WIN64
        push    rdi
%endif
        lea     rdi, [this_register + ARRAY_DATA_OFFSET]
        rep     stosq
%ifdef WIN64
        pop     rdi
%endif

        pushrbx
        mov     rbx, this_register      ; -- array

        ; Return handle of allocated array.
        _ new_handle                    ; -- handle

        pop     this_register
        next
endcode

; ### 1array
code one_array, '1array'                ; x -- handle
        _lit 1
        _swap
        _ new_array_untagged            ; -- handle
        next
endcode

; ### 2array
code two_array, '2array'                ; x y -- handle
        _lit 2
        _lit 0
        _ new_array_untagged            ; -- x y handle
        _duptor
        _lit 1
        _swap
        _ array_set_nth_untagged
        _lit 0
        _rfetch
        _ array_set_nth_untagged
        _rfrom
        next
endcode

; ### 3array
code three_array, '3array'              ; x y z -- handle
        _lit 3
        _lit 0
        _ new_array_untagged            ; -- x y z handle
        _duptor
        _handle_to_object_unsafe        ; -- x y z array
        push    this_register
        popd    this_register           ; -- x y z
%ifdef WIN64
        push    rdi
%endif
        lea     rdi, [this_register + ARRAY_DATA_OFFSET]
        mov     rax, [rbp + BYTES_PER_CELL]
        stosq
        mov     rax, [rbp]
        stosq
        mov     [rdi], rbx
%ifdef WIN64
        pop     rdi
%endif
        _3drop
        pop     this_register
        _rfrom
        next
endcode

; ### 4array
code four_array, '4array'               ; w x y z -- handle
        _lit 4
        _lit 0
        _ new_array_untagged            ; -- w x y z handle
        _duptor
        _handle_to_object_unsafe        ; -- w x y z array
        push    this_register
        popd    this_register           ; -- w x y z
%ifdef WIN64
        push    rdi
%endif
        lea     rdi, [this_register + ARRAY_DATA_OFFSET]
        mov     rax, [rbp + BYTES_PER_CELL * 2]
        stosq
        mov     rax, [rbp + BYTES_PER_CELL]
        stosq
        mov     rax, [rbp]
        stosq
        mov     [rdi], rbx
%ifdef WIN64
        pop     rdi
%endif
        _4drop
        pop     this_register
        _rfrom
        next
endcode

; ### array-new-sequence
code array_new_sequence, 'array-new-sequence' ; len seq -- newseq
        _drop
        _f
        _ new_array
        next
endcode

; ### ~array
code destroy_array, '~array'            ; handle --
        _ check_array                   ; -- array
        _ destroy_array_unchecked
        next
endcode

; ### ~array-unchecked
code destroy_array_unchecked, '~array-unchecked' ; array --
        _ in_gc?
        _zeq_if .1
        _dup
        _ release_handle_for_object
        _then .1

        ; Zero out the object header so it won't look like a valid object
        ; after it has been destroyed.
        xor     eax, eax
        mov     [rbx], rax

        _ ifree

        next
endcode

; ### array-nth-unsafe
code array_nth_unsafe, 'array-nth-unsafe' ; index handle -- element
        _swap
        _untag_fixnum
        _swap
        _handle_to_object_unsafe
        _array_nth_unsafe
        next
endcode

; ### array-nth
code array_nth, 'array-nth'             ; index handle -- element

        _swap
        _untag_fixnum
        _swap

array_nth_untagged:
        _ check_array

        _twodup
        _array_length
        _ult
        _if .2
        _array_nth_unsafe
        _return
        _then .2

        _2drop
        _error "array-nth index out of range"
        next
endcode

; ### array-set-nth
code array_set_nth, 'array-set-nth'     ; element index handle --

        _swap
        _untag_fixnum
        _swap

array_set_nth_untagged:
        _ check_array

        _twodup
        _array_length
        _ult
        _if .2
        _array_data
        _swap
        _cells
        _plus
        _store
        _else .2
        _error "array-set-nth index out of range"
        _then .2
        next
endcode

; ### array-first
code array_first, 'array-first'         ; handle -- element
        _zero
        _swap
        _ array_nth_untagged
        next
endcode

; ### array-second
code array_second, 'array-second'       ; handle -- element
        _lit 1
        _swap
        _ array_nth_untagged
        next
endcode

; ### array-each
code array_each, 'array-each'           ; array callable --

        ; protect callable from gc
        push    rbx

        _ callable_code_address

        _swap

        _ check_array                   ; -- code-address array

        push    this_register
        mov     this_register, rbx
        push    r12
        mov     r12, [rbp]              ; address to call in r12
        _2drop                          ; adjust stack
        _this_array_length
        _zero
        _?do .1
        _i
        _this_array_nth_unsafe          ; -- element
        call    r12
        _loop .1
        pop     r12
        pop     this_register

        ; drop callable
        pop     rax

        next
endcode

; ### map-array
code map_array, 'map-array'             ; array callable -- new-array

        ; protect callable from gc
        push    rbx

        _ callable_code_address

        _swap                           ; -- code-address array

        _ check_array

        push    this_register
        popd    this_register           ; -- code-address

        push    r12
        popd    r12                     ; code address in r12

        _this_array_length
        _f
        _ new_array_untagged            ; -- new-array

        _this_array_length
        _zero
        _?do .1
        _i
        _this_array_nth_unsafe
        call    r12                     ; -- new-array new-element
        _i
        _tag_fixnum                     ; -- new-array new-element i
        _pick                           ; -- new-array new-element i new-array
        _ array_set_nth

        _loop .1

        pop     r12
        pop     this_register

        ; drop callable
        pop     rax

        next
endcode

; ### array-equal?
code array_equal?, 'array-equal?'       ; array1 array2 -- ?
        _twodup

        _ array?
        _tagged_if_not .1
        _3drop
        _f
        _return
        _then .1

        _ array?
        _tagged_if_not .2
        _2drop
        _f
        _return
        _then .2

        _ sequence_equal
        next
endcode

; ### .array
code dot_array, '.array'                ; array --
        _ check_array

        push    this_register
        mov     this_register, rbx

        _write "{ "
        _array_length
        _zero
        _?do .1
        _i
        _this_array_nth_unsafe
        _ dot_object
        _loop .1
        _write "}"

        pop     this_register
        next
endcode
