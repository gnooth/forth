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

section .data
namestack_data:
        dq      0

%macro _get_namestack 0
        pushrbx
        mov     rbx, [namestack_data]
%endmacro

; ### get-namestack
inline get_namestack, 'get-namestack'   ; -- namestack
        _get_namestack
endinline

%macro _set_namestack 0
        mov     [namestack_data], rbx
        poprbx
%endmacro

; ### set-namestack
inline set_namestack, 'set-namestack'   ; namestack --
        _set_namestack
endinline

value globals, 'globals', 0

; ### initialize-globals
code initialize_globals, 'initialize-globals'
        _lit 16
        _ new_hashtable_untagged
        _to globals
        _lit globals_data
        _ gc_add_root

        _lit 16
        _ new_vector_untagged
        _set_namestack
        _lit namestack_data
        _ gc_add_root

        _ globals
        _get_namestack
        _ vector_push
        next
endcode

; ### set-global
code set_global, 'set-global'           ; value variable --
        _from globals
        _ set_at
        next
endcode

; ### get-global
code get_global, 'get-global'           ; variable -- value
        _from globals
        _ at_
        next
endcode

; ### scope
code scope, 'scope'                     ; --
        _lit 4
        _ new_hashtable_untagged
        _get_namestack
        _ vector_push
        next
endcode

; ### end-scope
code end_scope, 'end-scope'             ; --
        _get_namestack
        _ vector_pop_star
        next
endcode

; ### set
code set, 'set'                         ; value variable --
        _get_namestack
        _ vector_last
        _ set_at
        next
endcode

; ### find-in-scope
code find_in_scope, 'find-in-scope'     ; variable scope -- value/f ?
        _ at_star
        next
endcode

; ### get
code get, 'get'                         ; variable -- value
        _tor
        _get_namestack

        _dup
        _ vector_length
        _lit tagged_fixnum(1)
        _ fixnum_minus                  ; -- namestack index
        _dup
        _lit tagged_zero
        _ fixnum_lt
        _tagged_if .1
        _3drop
        _rdrop
        _f
        _return
        _then .1

.top:                                   ; -- namestack index       r: -- variable
        _twodup
        _swap
        _ vector_nth                    ; -- namestack index
        _rfetch
        _swap                           ; -- namestack index variable scope
        _ find_in_scope                 ; -- namestack index value/f ?
        _tagged_if .2
        ; found
        _2nip
        _rdrop
        _return
        _then .2                        ; -- namestack index f

        _drop                           ; -- namestack index

        _lit tagged_fixnum(1)
        _ feline_minus                  ; -- namestack index-1
        _dup
        _lit tagged_zero
        _ fixnum_lt
        _tagged_if .3
        _2drop
        _rdrop

        _f

        _return
        _then .3

        jmp     .top

        next
endcode
