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

; ### lookup-method
code lookup_method, 'lookup-method'     ; object methods-vector -- object xt/0
; Returns untagged 0 if no method.
        _tor                            ; -- object
        _dup
        _ object_type                   ; -- object tagged-type-number

        _dup
        _tagged_if_not .1
        _error "no object type"
        _then .1

        _rfrom                          ; -- object tagged-type-number vector
        _twodup
        _ vector_length
        _ fixnum_lt
        _tagged_if .2                   ; -- object n vector
        _ vector_nth_unsafe             ; -- object method/0
        _else .2
        _2drop                          ; -- object
        _zero                           ; -- object 0
        _then .2
        next
endcode

; ### do-generic
code do_generic, 'do-generic'
        _fetch
        _ lookup_method                 ; -- xt/0
        _dup
        _if .1
        _execute
        _else .1
        _true
        _abortq "no method"
        _then .1
        next
endcode

%macro generic 2
        code %1, %2
        section .data
        global  %1_data
        align   DEFAULT_DATA_ALIGNMENT
%1_data:
        dq      0                       ; address of methods vector (will be patched)
        section .text
        pushrbx
        mov     ebx, %1_data            ; REVIEW assumes 32-bit address
        call    do_generic
        next
%endmacro

; ### initialize-generic-function
code initialize_generic_function, 'initialize-generic-function' ; xt --
        _tobody
        _tor
        _lit 10
        _ new_vector_untagged
        _rfetch
        _store
        _rfrom
        _ gc_add_root
        next
endcode

; ### add-method
code add_method, 'add-method'           ; -- method-xt untagged-type-number generic-xt
        _tobody
        _fetch                          ; -- method-xt untagged-type-number methods-vector
        _ vector_set_nth_untagged
        next
endcode

; ### hashcode
generic hashcode, 'hashcode'

; ### equal?
generic equal?, 'equal?'

; ### f-equal?
code f_equal?, 'f-equal?'
        _2drop
        _f
        next
endcode

; ### length
generic length, 'length'

; ### push
generic push, 'push'

; ### nth
generic nth, 'nth'

; ### nth-unsafe
generic nth_unsafe, 'nth-unsafe'

; ### set-nth
generic set_nth, 'set-nth'

; ### new-sequence
generic new_sequence, 'new-sequence'    ; len seq -- newseq

; ### initialize-generic-functions
code initialize_generic_functions, 'initialize-generic-functions' ; --
        _lit hashcode_xt
        _ initialize_generic_function

        _lit force_hashcode_xt
        _lit OBJECT_TYPE_STRING
        _lit hashcode_xt
        _ add_method

        _lit symbol_hashcode_xt
        _lit OBJECT_TYPE_SYMBOL
        _lit hashcode_xt
        _ add_method

        _lit equal?_xt
        _ initialize_generic_function

        _lit fixnum_equal?_xt
        _lit OBJECT_TYPE_FIXNUM
        _lit equal?_xt
        _ add_method

        _lit string_equal?_xt
        _lit OBJECT_TYPE_STRING
        _lit equal?_xt
        _ add_method

        _lit symbol_equal?_xt
        _lit OBJECT_TYPE_SYMBOL
        _lit equal?_xt
        _ add_method

        _lit f_equal?_xt
        _lit OBJECT_TYPE_F
        _lit equal?_xt
        _ add_method

        _lit length_xt
        _ initialize_generic_function

        _lit string_length_xt
        _lit OBJECT_TYPE_STRING
        _lit length_xt
        _ add_method

        _lit sbuf_length_xt
        _lit OBJECT_TYPE_SBUF
        _lit length_xt
        _ add_method

        _lit array_length_xt
        _lit OBJECT_TYPE_ARRAY
        _lit length_xt
        _ add_method

        _lit vector_length_xt
        _lit OBJECT_TYPE_VECTOR
        _lit length_xt
        _ add_method

        _lit push_xt
        _ initialize_generic_function

        _lit vector_push_xt
        _lit OBJECT_TYPE_VECTOR
        _lit push_xt
        _ add_method

        _lit sbuf_push_xt
        _lit OBJECT_TYPE_SBUF
        _lit push_xt
        _ add_method

        _lit nth_xt
        _ initialize_generic_function

        _lit array_nth_xt
        _lit OBJECT_TYPE_ARRAY
        _lit nth_xt
        _ add_method

        _lit vector_nth_xt
        _lit OBJECT_TYPE_VECTOR
        _lit nth_xt
        _ add_method

        _lit string_nth_xt
        _lit OBJECT_TYPE_STRING
        _lit nth_xt
        _ add_method

        _lit sbuf_nth_xt
        _lit OBJECT_TYPE_SBUF
        _lit nth_xt
        _ add_method

        _lit nth_unsafe_xt
        _ initialize_generic_function

        _lit string_nth_unsafe_xt
        _lit OBJECT_TYPE_STRING
        _lit nth_unsafe_xt
        _ add_method

        _lit sbuf_nth_unsafe_xt
        _lit OBJECT_TYPE_SBUF
        _lit nth_unsafe_xt
        _ add_method

        _lit array_nth_unsafe_xt
        _lit OBJECT_TYPE_ARRAY
        _lit nth_unsafe_xt
        _ add_method

        _lit vector_nth_unsafe_xt
        _lit OBJECT_TYPE_VECTOR
        _lit nth_unsafe_xt
        _ add_method

        _lit set_nth_xt
        _ initialize_generic_function

        _lit array_set_nth_xt
        _lit OBJECT_TYPE_ARRAY
        _lit set_nth_xt
        _ add_method

        _lit vector_set_nth_xt
        _lit OBJECT_TYPE_VECTOR
        _lit set_nth_xt
        _ add_method

        _lit new_sequence_xt
        _ initialize_generic_function

        _lit array_new_sequence_xt
        _lit OBJECT_TYPE_ARRAY
        _lit new_sequence_xt
        _ add_method

        _lit vector_new_sequence_xt
        _lit OBJECT_TYPE_VECTOR
        _lit new_sequence_xt
        _ add_method

        next
endcode
