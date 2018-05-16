; Copyright (C) 2012-2018 Peter Graves <gnooth@gmail.com>

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

; maximum number of local variables in a definition
%define MAX_LOCALS      16

%macro  _locals_enter 0
        push    r14
        lea     r14, [r14 - BYTES_PER_CELL * MAX_LOCALS];
%endmacro

%macro  _locals_leave 0
        pop     r14
%endmacro

asm_global lp0_, 0

%macro _lp0 0
        _dup
        mov     rbx, [lp0_]
%endmacro

; ### lp0
code lp0, 'lp0'                         ; -- tagged-address
        _lp0
        _tag_fixnum
        next
endcode

%macro  _lpstore 0
        mov     r14, rbx
        _drop
%endmacro

%macro  _lpfetch 0
        _dup
        mov     rbx, r14
%endmacro

; ### lp@
code lpfetch, 'lp@'                     ; -- tagged-address
        _lpfetch
        _tag_fixnum
        next
endcode

; ### local@
code local_fetch, 'local@'              ; index -- value
        _check_index
        mov     rbx, [r14 + rbx * BYTES_PER_CELL]
        next
endcode

; ### local_0_fetch
inline local_0_fetch, 'local_0_fetch', SYMBOL_INTERNAL  ; -- value
        pushrbx
        mov     rbx, [r14]
endinline

; ### local_1_fetch
inline local_1_fetch, 'local_1_fetch', SYMBOL_INTERNAL  ; -- value
        pushrbx
        mov     rbx, [r14 + BYTES_PER_CELL]
endinline

; ### local!
code local_store, 'local!'              ; value index --
        _check_index
        _cells
        add     rbx, r14
        mov     rax, [rbp]
        mov     [rbx], rax
        _2drop
        next
endcode

; ### local_0_store
inline local_0_store, 'local_0_store', SYMBOL_INTERNAL  ; value --
        mov     [r14], rbx
        poprbx
endinline

; ### local_1_store
inline local_1_store, 'local_1_store', SYMBOL_INTERNAL  ; value --
        mov     [r14 + BYTES_PER_CELL], rbx
        poprbx
endinline

; ### local-inc
code local_inc, 'local-inc'     ; index --
        _check_index
        _cells
        add     rbx, r14
        mov     rdx, rbx        ; address
        mov     rbx, [rbx]
        _check_fixnum
        add     rbx, 1
        _tag_fixnum
        mov     [rdx], rbx
        _drop
        next
endcode

; ### local-dec
code local_dec, 'local-dec'     ; index --
        _check_index
        _cells
        add     rbx, r14
        mov     rdx, rbx        ; address
        mov     rbx, [rbx]
        _check_fixnum
        sub     rbx, 1
        _tag_fixnum
        mov     [rdx], rbx
        _drop
        next
endcode

; ### allocate_locals_stack
code allocate_locals_stack, 'allocate_locals_stack', SYMBOL_INTERNAL    ; -- raw-lp0
        _lit 4096
        _dup
        _ raw_allocate
        _plus
        next
endcode

; ### free_locals_stack
code free_locals_stack, 'free_locals_stack', SYMBOL_INTERNAL
; called by BYE to make sure we're freeing all allocated memory
        _lp0
        _?dup
        _if .1
        _lit 4096
        _minus
        _ raw_free
        _then .1
        next
endcode

asm_global locals_, f_value

; ### locals
code locals, 'locals'                   ; -- hashtable/f
        pushrbx
        mov     rbx, [locals_]
        next
endcode

asm_global locals_count_, 0

; ### locals-count
code locals_count, 'locals-count'       ; -- n
        pushrbx
        mov     rbx, [locals_count_]
        _tag_fixnum
        next
endcode

asm_global local_names_, f_value

; ### local-names
code local_names, 'local-names'
        pushrbx
        mov     rbx, [local_names_]
        next
endcode

; ### cold_initialize_locals
code cold_initialize_locals, 'cold_initialize_locals', SYMBOL_INTERNAL

        _ allocate_locals_stack
        mov     [lp0_], rbx
        _lpstore

        _lit locals_
        _ gc_add_root

        _lit local_names_
        _ gc_add_root

        next
endcode

; ### locals-enter
always_inline locals_enter, 'locals-enter'
        _locals_enter
endinline

; ### locals-leave
always_inline locals_leave, 'locals-leave'
        _locals_leave
endinline

; ### initialize-locals
code initialize_locals, 'initialize-locals'

        _lit MAX_LOCALS
        _ new_hashtable_untagged
        mov     [locals_], rbx
        poprbx

        _lit MAX_LOCALS
        _ new_vector_untagged
        mov     [local_names_], rbx
        poprbx

        next
endcode

; ### add-local
code add_local, 'add-local'             ; string -- index

        cmp     qword [locals_count_], MAX_LOCALS
        jb      .1
        _error "too many locals"

.1:
        ; is there already a local with this name?
        _dup
        _ locals
        _ hashtable_at
        _tagged_if .2
        _error "duplicate local name"
        _then .2                        ; -- string

        ; add name
        _dup
        _ local_names
        _ vector_push

        _ locals_count
        _swap
        _ locals
        _ hashtable_set_at

         ; return index of added name
        _ locals_count                  ; -- index

        ; update locals count
        add     qword [locals_count_], 1

        next
endcode

; ### forget-locals
code forget_locals, 'forget-locals'     ; --
        mov     qword [locals_], f_value
        mov     qword [locals_count_], 0
        mov     qword [local_names_], f_value
        next
endcode
