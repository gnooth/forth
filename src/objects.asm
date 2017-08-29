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

; ### raw-allocate-cells
code raw_allocate_cells, 'raw-allocate-cells', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
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

; ### object_raw_typecode
code object_raw_typecode, 'object_raw_typecode', SYMBOL_INTERNAL
; x -- raw-typecode

%ifdef TAGGED_HANDLES
        cmp     bl, HANDLE_TAG
        je      .2
        ; not a handle
        test    ebx, LOWTAG_MASK
        jz      .3
%else
        test    ebx, LOWTAG_MASK
        jz      .2
%endif

%if FIXNUM_TAG_BITS = 1 && FIXNUM_TAG = 1
        test    ebx, FIXNUM_TAG
        jz      .1
%else
        mov     eax, ebx
        and     eax, FIXNUM_TAG_MASK
        cmp     eax, FIXNUM_TAG
        jne     .1
%endif
        mov     ebx, TYPECODE_FIXNUM
        _return

.1:
        mov     eax, ebx
        and     eax, BOOLEAN_TAG_MASK
        cmp     eax, BOOLEAN_TAG
        jne     .4
        mov     ebx, TYPECODE_BOOLEAN
        _return

.2:
%ifndef TAGGED_HANDLES
        cmp     rbx, [handle_space_]
        jb      .3
        cmp     rbx, [handle_space_free_]
        jae     .3
%endif
        _handle_to_object_unsafe
        test    rbx, rbx
        jz      error_empty_handle
        _object_raw_typecode
        _return

.3:
        cmp     rbx, static_data_area
        jb      .4
        cmp     rbx, static_data_area_limit
        jae     .4
        _object_raw_typecode
        _return

.4:
        ; not an object
        ; return -1
        xor     ebx, ebx
        not     rbx

        next
endcode

; ### object-typecode
code object_typecode, 'object-typecode' ; x -- typecode
; return value is tagged
; error if x is not an object
        _ object_raw_typecode
        _tag_fixnum
        next
endcode

; ### type-of
code type_of, 'type-of'         ; object -- type
        _ object_raw_typecode
        _ types
        _ vector_nth_untagged
        next
endcode

; ### .t
code dot_t, '.t'                ; object -- object
        _lit tagged_fixnum(1)
        _ ?enough
        _dup
        _ type_of
        _ dot_object
        next
endcode

; ### destroy_object_unchecked
code destroy_object_unchecked, 'destroy_object_unchecked', SYMBOL_INTERNAL      ; raw-object-address --

; The argument is known to be the raw address of a valid heap object, not a
; handle or null. Called only by maybe-collect-handle during gc.

        _object_raw_typecode_eax

        cmp     eax, TYPECODE_SBUF
        je      destroy_sbuf_unchecked
        cmp     eax, TYPECODE_VECTOR
        je      destroy_vector_unchecked
        cmp     eax, TYPECODE_HASHTABLE
        je      destroy_hashtable_unchecked
        cmp     eax, TYPECODE_QUOTATION
        je      destroy_quotation_unchecked
        cmp     eax, TYPECODE_CURRY
        je      destroy_curry_unchecked

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

%ifdef FELINE_FEATURE_BIGNUMS
        _dup
        _ bignum?
        _tagged_if .8
        _ bignum_to_string
        _return
        _then .8
%endif

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

        _dup
        _ type?
        _tagged_if .21
        _ type_to_string
        _return
        _then .21

        _dup
        _ method?
        _tagged_if .22
        _ method_to_string
        _return
        _then .22

        _dup
        _ generic_function?
        _tagged_if .23
        _ generic_function_to_string
        _return
        _then .23

        _dup
        _ uint64?
        _tagged_if .24
        _ uint64_to_string
        _return
        _then .24

        _dup
        _ int64?
        _tagged_if .25
        _ int64_to_string
        _return
        _then .25

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

; ### fixnum-tag-bits
code fixnum_tag_bits, 'fixnum-tag-bits'
        _lit FIXNUM_TAG_BITS
        _tag_fixnum
        next
endcode

; ### tag-fixnum
code tag_fixnum, 'tag-fixnum'           ; n -- tagged
        _tag_fixnum
        next
endcode
