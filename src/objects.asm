; Copyright (C) 2015-2017 Peter Graves <gnooth@gmail.com>

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

; ### allocate-object
code allocate_object, 'allocate-object' ; size -- object
        _ raw_allocate
        next
endcode

; ### allocate-cells
code allocate_cells, 'allocate-cells', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; n -- address
; Argument and return value are untagged.
        _dup
        _cells                          ; -- cells bytes
        _ raw_allocate
        _swap                           ; -- address cells
        _dupd                           ; -- address address cells
        _ raw_erase_cells
        next
endcode

; ### object?
code object?, 'object?'                 ; x -- ?
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe
        _zne
        _tag_boolean
        _return
        _then .1

        ; Not allocated. Must be a string or not an object.
        _ string?
        next
endcode

; ### object-address
code object_address, 'object-address'   ; handle -- tagged-address
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe
        _tag_fixnum
        _return
        _then .1

        ; not allocated
        _dup
        _ string?
        _tagged_if .2
        _tag_fixnum
        _return
        _then .2

        _dup
        _ symbol?
        _tagged_if .3
        _tag_fixnum
        _return
        _then .3

        ; apparently not an object
        mov     ebx, f_value

        next
endcode

; ### error-empty-handle
code error_empty_handle, 'error-empty-handle'
        _error "empty handle"
        next
endcode

; ### object-raw-type
code object_raw_type, 'object-raw-type'         ; x -- raw-type-number
        mov     eax, ebx
        and     eax, TAG_MASK
        cmp     eax, FIXNUM_TAG
        jnz     .1
        mov     ebx, OBJECT_TYPE_FIXNUM
        _return

.1:
        cmp     rbx, f_value
        jnz     .2
        mov     ebx, OBJECT_TYPE_F
        _return

.2:
        _dup
        _ handle?
        _tagged_if .3
        _handle_to_object_unsafe
        test    rbx, rbx
        jz      error_empty_handle
        _object_raw_type_number
        _return
        _then .3

        ; Not allocated. Is it a static string or symbol?
        _dup
        _ string?
        _tagged_if .4
        mov     ebx, OBJECT_TYPE_STRING
        _return
        _then .4

        _dup
        _ symbol?
        _tagged_if .5
        mov     ebx, OBJECT_TYPE_SYMBOL
        _return
        _then .5

        _error "not an object"

        next
endcode

; ### object-type
code object_type, 'object-type'         ; x -- type-number
; return value is tagged
; error if x is not an object
        _ object_raw_type
        _tag_fixnum
        next
endcode

; ### type
code type, 'type'                       ; object -- object
        _dup
        _ object_raw_type

        _dup
        _eq? OBJECT_TYPE_FIXNUM
        _tagged_if .1
        _write "fixnum"
        _drop
        _return
        _then .1

        _dup
        _eq? OBJECT_TYPE_BIGNUM
        _tagged_if .2
        _drop
        _write "bignum"
        _return
        _then .2

        _drop
        next
endcode

; ### type?
code type?, 'type?'                     ; x type-number -- ?
        _swap
        _ deref                         ; -- type-number object-address/0
        _?dup_if .1
        _object_raw_type_number
        _eq?
        _return
        _then .1

        mov     ebx, f_value
        next
endcode

; ### destroy-object-unchecked
code destroy_object_unchecked, 'destroy-object-unchecked', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; object --
; The argument is known to be the address of a valid heap object, not a
; handle or null. Called only by maybe-collect-handle during gc.
        _dup

        ; Macro is OK here since we have a valid object address.
        _string?

        _if .1
        _ destroy_string_unchecked
        _return
        _then .1

        _dup
        _sbuf?
        _if .2
        _ destroy_sbuf_unchecked
        _return
        _then .2

        _dup
        _vector?
        _if .3
        _ destroy_vector_unchecked
        _return
        _then .3

        _dup
        _array?
        _if .4
        _ destroy_array_unchecked
        _return
        _then .4

        _dup
        _hashtable?
        _if .5
        _ destroy_hashtable_unchecked
        _return
        _then .5

        _dup
        _quotation?
        _if .6
        _ destroy_quotation_unchecked
        _return
        _then .6

        _dup
        _curry?
        _if .7
        _ destroy_curry_unchecked
        _return
        _then .7

        _dup
        _bignum?
        _if .8
        _ destroy_bignum_unchecked
        _return
        _then .8

        ; Default behavior for objects with only one allocation.

        ; Zero out the object header so it won't look like a valid object
        ; after it has been freed.
        xor     eax, eax
        mov     [rbx], rax

        _ raw_free

        next
endcode

; ### slot
code slot, 'slot'                       ; obj tagged-fixnum -- value
        _untag_fixnum
        _cells
        _swap
        _handle_to_object_unsafe
        _plus
        _fetch
        next
endcode

; ### slot!
code set_slot, 'slot!'                  ; value obj tagged-fixnum --
        _untag_fixnum
        _cells
        _swap
        _handle_to_object_unsafe
        _plus
        _store
        next
endcode

; ### object>string
code object_to_string, 'object>string'  ; object -- string
; FIXME make this a generic word

        cmp     rbx, f_value
        jnz     .1
        _drop
        _quote "f"
        _return

.1:
        cmp     rbx, t_value
        jnz     .2
        _drop
        _quote "t"
        _return

.2:
        _dup
        _ string?
        _tagged_if .3
        _ quote_string
        _return
        _then .3

        _dup
        _ sbuf?
        _tagged_if .4
        _quote "sbuf{ "
        _ string_to_sbuf
        _swap
        _ sbuf_to_string
        _ quote_string
        _over
        _ sbuf_append_string
        _quote " }"
        _over
        _ sbuf_append_string
        _ sbuf_to_string
        _return
        _then .4

        _dup
        _ vector?
        _tagged_if .5
        _ vector_to_string
        _return
        _then .5

        _dup
        _ array?
        _tagged_if .6
        _ array_to_string
        _return
        _then .6

        _dup_fixnum?_if .7
        _ fixnum_to_string
        _return
        _then .7

        _dup
        _ bignum?
        _tagged_if .8
        _ bignum_to_string
        _return
        _then .8

        _dup
        _ hashtable?
        _tagged_if .9
        _ hashtable_to_string
        _return
        _then .9

        _dup
        _ symbol?
        _tagged_if .10
        _ symbol_name
        _return
        _then .10

        _dup
        _ vocab?
        _tagged_if .11
        ; REVIEW
        _ vocab_name
        _return
        _then .11

        _dup
        _ quotation?
        _tagged_if .12
        _ quotation_to_string
        _return
        _then .12

        _dup
        _ wrapper?
        _tagged_if .13
        _ wrapper_to_string
        _return
        _then .13

        _dup
        _ tuple?
        _tagged_if .14
        _ tuple_to_string
        _return
        _then .14

        _dup
        _ curry?
        _tagged_if .15
        _ curry_to_string
        _return
        _then .15

        _dup
        _ slice?
        _tagged_if .16
        _ slice_to_string
        _return
        _then .16

        _dup
        _ range?
        _tagged_if .17
        _ range_to_string
        _return
        _then .17

        _dup
        _ lexer?
        _tagged_if .18
        _ lexer_to_string
        _return
        _then .18

        _dup
        _ float?
        _tagged_if .19
        _ float_to_string
        _return
        _then .19

        _dup
        _ iterator?
        _tagged_if .20
        _ iterator_to_string
        _return
        _then .20

        ; give up
        _tag_fixnum
        _ fixnum_to_hex
        _quote "$"
        _swap
        _ concat

        next
endcode

; ### .
code dot_object, '.'                    ; handle-or-object --
        _ object_to_string
        _ write_string
        next
endcode

; ### tag-bits
code tag_bits, 'tag-bits'
        _lit TAG_BITS
        _tag_fixnum
        next
endcode

; ### tag-fixnum
code tag_fixnum, 'tag-fixnum'           ; n -- tagged
        _tag_fixnum
        next
endcode

; ### untag-fixnum
inline untag_fixnum, 'untag-fixnum'     ; tagged -- n
        _untag_fixnum
endinline

; ### tag-char
code tag_char, 'tag-char'               ; char -- tagged
        _tag_char
        next
endcode

; ### untag-char
code untag_char, 'untag-char'           ; tagged -- char
        _untag_char
        next
endcode

; ### tag-boolean
code tag_boolean, 'tag-boolean'         ; -1|0 -- t|f
        _tag_boolean
        next
endcode

; ### untag-boolean
code untag_boolean, 'untag-boolean'     ; t|f -- 1|0
        _untag_boolean
        next
endcode

; ### tag
code tag, 'tag'                         ; object -- tag
        _tag
        _tag_fixnum
        next
endcode
