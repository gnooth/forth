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

value globals, 'globals', 0

value scopes, 'scopes', 0

; ### initialize-globals
code initialize_globals, 'initialize-globals'
        _lit 16
        _ new_hashtable_untagged
        _to globals
        _lit globals_data
        _ gc_add_root
        _lit 16
        _ new_vector_untagged
        _to scopes
        _lit scopes_data
        _ gc_add_root
        _ globals
        _ scopes
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
        _ scopes
        _ vector_push
        next
endcode

; ### end-scope
code end_scope, 'end-scope'             ; --
        _ scopes
        _ vector_pop_star
        next
endcode

; ### set
code set, 'set'                         ; value variable --
        _ scopes
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
        _ scopes

        _dup
        _ vector_length
        _lit tagged_fixnum(1)
        _ fixnum_minus                  ; -- scopes index
        _dup
        _lit tagged_zero
        _ fixnum_lt
        _tagged_if .1
        _3drop
        _rdrop
        _f
        _return
        _then .1

.top:                                   ; -- scopes index       r: -- variable
        _twodup
        _swap
        _ vector_nth                    ; -- scopes index
        _rfetch
        _swap                           ; -- scopes index variable scope
        _ find_in_scope                 ; -- scopes index value/f ?
        _tagged_if .2
        ; found
        _2nip
        _rdrop
        _return
        _then .2                        ; -- scopes index f

        _drop                           ; -- scopes index

        _lit tagged_fixnum(1)
        _ feline_minus                  ; -- scopes index-1
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
