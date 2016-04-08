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

; ### release-handle-for-object
code release_handle_for_object, 'release-handle-for-object' ; object --
        _ find_handle
        _?dup_if .1
        _ release_handle_unsafe
        _then .1
        next
endcode

; ### gc-roots
value gc_roots, 'gc-roots', 0           ; initialized in cold

; ### gc-add-root
code gc_add_root, 'gc-add-root'         ; address --
        _ gc_roots
        _ vector_push
        next
endcode

; ### mark-vector
code mark_vector, 'mark-vector'         ; vector --
        push    this_register
        mov     this_register, rbx
        _vector_length
        _zero
        _?do .1
        _i
        _this
        _vector_nth_unsafe              ; -- element
        _ maybe_mark_handle
        _loop .1                        ; --
        pop     this_register
        next
endcode

; ### mark-array
code mark_array, 'mark-array'           ; array --
        push    this_register
        mov     this_register, rbx
        _array_length
        _zero
        _?do .1
        _i
        _this_array_nth_unsafe          ; -- element
        _ maybe_mark_handle
        _loop .1                        ; --
        pop     this_register
        next
endcode

; ### mark-handle
code mark_handle, 'mark-handle'         ; handle --
        _handle_to_object_unsafe        ; -- object|0
        test    rbx, rbx
        jz .1
        ; Set the marked bit in the object header.
        or      OBJECT_FLAGS_BYTE, OBJECT_MARKED_BIT

        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_VECTOR
        _equal
        _if .2
        _ mark_vector
        _return
        _then .2

        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_ARRAY
        _equal
        _if .3
        _ mark_array
        _return
        _then .3
.1:
        _drop
        next
endcode

; ### maybe-mark-handle
code maybe_mark_handle, 'maybe-mark-handle' ; handle --
        _dup
        _ handle?
        _if .1
        _ mark_handle
        _else .1
        _drop
        _then .1
        next
endcode

; ### maybe-mark-from-root
code maybe_mark_from_root, 'maybe-mark-from-root' ; root --
        _fetch
        _ maybe_mark_handle
        next
endcode

; ### mark-data-stack
code mark_data_stack, 'mark-data-stack' ; --
        _ depth
        mov     rcx, rbx
        jrcxz   .2
.1:
        push    rcx
        pushd   rcx
        _pick
        _ maybe_mark_handle
        pop     rcx
        loop    .1
.2:
        _drop
        next
endcode

; ### mark-return-stack
code mark_return_stack, 'mark-return-stack' ; --
        _ rdepth
        mov     rcx, rbx                ; depth in rcx
        jrcxz   .2
.1:
        mov     rax, rcx
        shl     rax, 3
        add     rax, rsp
        pushrbx
        mov     rbx, [rax]
        push    rcx
        _ maybe_mark_handle
        pop     rcx
        dec     rcx
        jnz     .1
.2:
        poprbx
        next
endcode

; ### mark-locals-stack
code mark_locals_stack, 'mark-locals-stack' ; --
        _ lpfetch
        _begin .3
        _dup
        _ lp0
        _ult
        _while .3
        _dup
        _ maybe_mark_from_root
        _cellplus
        _repeat .3
        _drop
        next
endcode

; ### maybe-collect-handle
code maybe_collect_handle, 'maybe-collect-handle' ; handle --
        _dup                            ; -- handle handle
        _handle_to_object_unsafe        ; -- handle object|0
        ; Check for null object address.
        test    rbx, rbx
        jnz     .1
        ; Null object address, nothing to do.
        _2drop
        _return
.1:                                     ; -- handle object
        ; Is object marked?
        test    OBJECT_FLAGS_BYTE, OBJECT_MARKED_BIT
        jz .2
        ; Object is marked.
        _nip                            ; -- object
        _unmark_object
        _return
.2:                                     ; -- handle object
        ; Object is not marked.
        _ destroy_object_unchecked      ; -- handle
        _ release_handle_unsafe
        next
endcode

; ### in-gc?
value in_gc?, 'in-gc?', 0

; ### gc-start-ticks
value gc_start_ticks, 'gc-start-ticks', 0

; ### gc-verbose
value gc_verbose, 'gc-verbose', 0

; ### gc
code gc, 'gc'                           ; --
        _ ticks
        _to gc_start_ticks

        _true
        _to in_gc?

        ; data stack
        _ mark_data_stack

        ; return stack
        _ mark_return_stack

        ; locals stack
        _ mark_locals_stack

        ; explicit roots
        _ gc_roots
        _lit maybe_mark_from_root_xt
        _ vector_each

        ; sweep
        _lit maybe_collect_handle_xt
        _ each_handle

        _zeroto in_gc?

        _ gc_verbose
        _if .1
        _ ticks
        _ gc_start_ticks
        _minus
        _ ?cr
        _ decdot
        _dotq "ms "
        _then .1

        next
endcode
