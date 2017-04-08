; Copyright (C) 2016-2017 Peter Graves <gnooth@gmail.com>

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

; 7 cells (object header, count, deleted, capacity, data address,
; hash function, test function)

%macro  _hashtable_raw_count 0          ; hashtable -- count
        _slot1
%endmacro

%macro  _this_hashtable_raw_count 0     ; -- count
        _this_slot1
%endmacro

%macro  _this_hashtable_set_raw_count 0 ; count --
        _this_set_slot1
%endmacro

%macro  _this_hashtable_increment_raw_count 0   ; --
        add     qword [this_register + BYTES_PER_CELL * 1], 1
%endmacro

%macro  _this_hashtable_deleted 0       ; -- deleted
        _this_slot2
%endmacro

%macro  _this_hashtable_set_deleted 0   ; deleted --
        _this_set_slot2
%endmacro

%macro  _hashtable_raw_capacity 0       ; hashtable -- untagged-capacity
        _slot3
%endmacro

%define this_hashtable_raw_capacity     this_slot3

%macro  _this_hashtable_raw_capacity 0  ; -- untagged-capacity
        _this_slot3
%endmacro

%macro  _this_hashtable_set_raw_capacity 0      ; untagged-capacity --
        _this_set_slot3
%endmacro

%macro  _hashtable_data 0               ; hashtable -- data-address
        _slot4
%endmacro

%define this_hashtable_data_address     this_slot4

%macro  _this_hashtable_data 0          ; -- data-address
        _this_slot4
%endmacro

%macro  _this_hashtable_set_data 0      ; data-address --
        _this_set_slot4
%endmacro

%macro  _this_hashtable_nth_key 0       ; n -- key
        shl     rbx, 4                  ; convert index to byte offset
        mov     rax, this_hashtable_data_address
        mov     rbx, [rax + rbx]
%endmacro

%macro  _this_hashtable_nth_value 0     ; n -- value
        shl     rbx, 4                  ; convert index to byte offset
        mov     rax, this_hashtable_data_address
        mov     rbx, [rax + rbx + BYTES_PER_CELL]
%endmacro

%macro  _this_hashtable_set_nth_key 0   ; key n --
        shl     rbx, 4                  ; convert index to byte offset
        _this_hashtable_data            ; -- key offset data-address
        _plus
        _store
%endmacro

%macro  _this_hashtable_set_nth_value 0 ; value n --
        shl     rbx, 4                  ; convert index to byte offset
        _this_hashtable_data            ; -- value offset data-address
        _plus
        add     rbx, BYTES_PER_CELL
        _store
%endmacro

%define this_hashtable_hash_function    this_slot5

%macro  _this_hashtable_hash_function 0
        _this_slot5
%endmacro

%macro  _hashtable_set_hash_function 0
        _set_slot5
%endmacro

%macro  _this_hashtable_set_hash_function 0
        _this_set_slot5
%endmacro

%define this_hashtable_test_function    this_slot6

%macro  _hashtable_set_test_function 0
        _set_slot6
%endmacro

%macro  _this_hashtable_test_function 0
        _this_slot6
%endmacro

%macro  _this_hashtable_set_test_function 0
        _this_set_slot6
%endmacro

; ### hashtable?
code hashtable?, 'hashtable?'   ; x -- ?
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_type                    ; -- object-type
        _eq? OBJECT_TYPE_HASHTABLE
        _return
        _then .2
        _then .1
        mov     ebx, f_value
        next
endcode

; ### check-hashtable
code check_hashtable, 'check-hashtable'         ; handle -- hashtable
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        movzx   eax, word [rbx]
        cmp     eax, OBJECT_TYPE_HASHTABLE
        jne     .error
        _nip
        next
.error:
        _drop
        _ error_not_hashtable
        next
endcode

; ### verify-hashtable
code verify_hashtable, 'verify-hashtable'       ; handle -- handle
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        movzx   eax, word [rbx]
        cmp     eax, OBJECT_TYPE_HASHTABLE
        jne     .error
        _drop
        next
.error:
        _drop
        _ error_not_hashtable
        next
endcode

; ### hashtable-count
code hashtable_count, 'hashtable-count' ; hashtable -- count
        _ check_hashtable
        _hashtable_raw_count
        _tag_fixnum
        next
endcode

; ### hashtable-capacity
code hashtable_capacity, 'hashtable-capacity'   ; hashtable -- capacity
; Return value is tagged.
        _ check_hashtable
        _hashtable_raw_capacity
        _tag_fixnum
        next
endcode

; ### hashtable-set-hash-function
code hashtable_set_hash_function, 'hashtable-set-hash-function' ; hash-function hashtable --
        _ check_hashtable
        _hashtable_set_hash_function
        next
endcode

; ### hashtable-set-test-function
code hashtable_set_test_function, 'hashtable-set-test-function' ; test-function hashtable --
        _ check_hashtable
        _hashtable_set_test_function
        next
endcode

; ### empty-or-deleted?
code empty_or_deleted?, 'empty-or-deleted?'     ; x -- ?
        _dup
        _tagged_if_not .1
        ; empty
        mov     rbx, t_value
        _return
        _then .1

        _dup
        _eq? S_deleted
        _tagged_if .2
        ; deleted
        mov     rbx, t_value
        _return
        _then .2

        ; none of the above
        mov     rbx, f_value
        next
endcode

; ### hashtable-keys
code hashtable_keys, 'hashtable-keys'   ; hashtable -- keys
        _ check_hashtable               ; -- hashtable

hashtable_keys_unchecked:
        push    this_register
        mov     this_register, rbx
        _hashtable_raw_count
        _ new_vector_untagged           ; -- handle-to-vector
        _this_hashtable_raw_capacity
        _register_do_times .1
        _i
        _this_hashtable_nth_key
        _dup
        _ empty_or_deleted?
        _tagged_if_not .2
        _over
        _ vector_push
        _else .2
        _drop
        _then .2
        _loop .1
        pop     this_register
        next
endcode

; ### hashtable-values
code hashtable_values, 'hashtable-values'       ; hashtable -- values
        _ check_hashtable               ; -- hashtable

hashtable_values_unchecked:
        push    this_register
        mov     this_register, rbx
        _hashtable_raw_count
        _ new_vector_untagged           ; -- handle-to-vector
        _this_hashtable_raw_capacity
        _register_do_times .1
        _i
        _this_hashtable_nth_key
        _ empty_or_deleted?
        _tagged_if_not .2
        _i
        _this_hashtable_nth_value
        _over
        _ vector_push
        _then .2
        _loop .1
        pop     this_register
        next
endcode

; ### next-power-of-2
code next_power_of_2, 'next-power-of-2' ; m -- n
; Argument and return value are tagged fixnums.
        _check_fixnum
        _lit 2
        _begin .1
        _twodup
        _ugt
        _while .1
        _twostar
        _repeat .1
        _nip
        _tag_fixnum
        next
endcode

; ### <hashtable>
code new_hashtable, '<hashtable>'       ; fixnum -- hashtable

        _ next_power_of_2               ; -- fixnum
        _untag_fixnum

new_hashtable_untagged:

        ; 7 cells (object header, count, deleted, capacity, data address,
        ; hash function, test function)
        _lit 7
        _ allocate_cells
        push    this_register
        mov     this_register, rbx
        poprbx

        _this_object_set_type OBJECT_TYPE_HASHTABLE

        _dup
        _this_hashtable_set_raw_capacity        ; -- n

        ; each entry occupies two cells (key, value)
        shl     rbx, 4                  ; -- n*16
        _ raw_allocate                  ; -- data-address
        _this_hashtable_set_data        ; --

        _this_hashtable_raw_capacity
        _twostar
        _register_do_times .1
        _f
        _this_hashtable_data
        _i
        _cells
        _plus
        _store
        _loop .1

        _lit S_generic_hashcode
        _ symbol_raw_code_address
        _this_hashtable_set_hash_function

        _lit S_feline_equal
        _ symbol_raw_code_address
        _this_hashtable_set_test_function

        pushrbx
        mov     rbx, this_register      ; -- hashtable

        ; return handle
        _ new_handle                    ; -- handle

        pop     this_register
        next
endcode

; ### ~hashtable
code destroy_hashtable, '~hashtable'    ; handle --
        _ check_hashtable               ; -- hashtable
        _ destroy_hashtable_unchecked
        next
endcode

; ### ~hashtable-unchecked
code destroy_hashtable_unchecked, '~hashtable-unchecked'        ; hashtable --
        _dup
        _hashtable_data
        _ raw_free                      ; -- hashtable

        _ in_gc?
        _zeq_if .1
        _dup
        _ release_handle_for_object
        _then .1

        ; Zero out the object header so it won't look like a valid object
        ; after it has been destroyed.
        xor     eax, eax
        mov     [rbx], rax

        _ raw_free

        next
endcode

; ### hashtable-data-address
code hashtable_data_address, 'hashtable-data-address' ; ht -- data-address
; Return value is untagged.
        _ check_hashtable
        push    this_register
        popd    this_register
        _this_hashtable_data
        pop     this_register
        next
endcode

%macro  _this_hashtable_hash_at 0       ; key -- start-index
        mov     rax, this_hashtable_hash_function
        call    rax
        _untag_fixnum
        mov     rax, this_hashtable_raw_capacity
        sub     rax, 1
        and     rbx, rax
%endmacro

%macro  _compute_index 0                ; start-index -- computed-index
        add     rbx, index_register
        mov     rax, this_hashtable_raw_capacity
        sub     rax, 1
        and     rbx, rax
%endmacro

; ### this-hashtable-find-index-for-key
code this_hashtable_find_index_for_key, 'this-hashtable-find-index-for-key', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; key -- tagged-index/f ?

; Must be called with the address of the raw hashtable object in this_register (r15).

        _dup
        _this_hashtable_hash_at         ; -- key start-index

        _this_hashtable_raw_capacity
        _register_do_times .1

        _twodup                         ; -- key start-index key start-index
        _compute_index                  ; -- key start-index key computed-index

        _this_hashtable_nth_key         ; -- key start-index key nth-key

        cmp     rbx, f_value
        jne     .2
        ; found empty slot
        _2drop
        _nip
        _compute_index
        _tag_fixnum
        _f
        _unloop
        _return
.2:
        mov     rax, this_hashtable_test_function
        call    rax

        _tagged_if .3                   ; -- key start-index
        ; found key
        _nip
        _compute_index
        _tag_fixnum
        _t
        _unloop
        _return
        _then .3                        ; -- key start-index

        _loop .1

        _2drop
        _f
        _f

        next
endcode

; ### find-index-for-key
code find_index_for_key, 'find-index-for-key'   ; key hashtable -- tagged-index/f ?

        _ check_hashtable               ; -- key raw-hashtable

find_index_for_key_unchecked:

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- key
        _ this_hashtable_find_index_for_key
        pop     this_register

        next
endcode

; ### at*
code at_star, 'at*'                     ; key hashtable -- value/f ?
        _ check_hashtable
        push    this_register
        mov     this_register, rbx
        poprbx                                  ; -- key
        _ this_hashtable_find_index_for_key     ; -- tagged-index/f ?
        _tagged_if .1
        _untag_fixnum
        _this_hashtable_nth_value
        _t
        _else .1
        _drop
        _f
        _f
        _then .1
        pop     this_register
        next
endcode

; ### at
code at_, 'at'                          ; key hashtable -- value
        _ check_hashtable
        push    this_register
        mov     this_register, rbx
        poprbx                                  ; -- key
        _ this_hashtable_find_index_for_key     ; -- tagged-index/f ?
        cmp     rbx, f_value
        jz      .1
        _drop
        _untag_fixnum
        _this_hashtable_nth_value
        pop     this_register
        _return
.1:
        _2drop
        _f
        pop     this_register
        next
endcode

%macro _this_hashtable_set_nth_pair 0   ; -- value key index
        _tuck
        _this_hashtable_set_nth_key
        _this_hashtable_set_nth_value
%endmacro

; ### set-at
code set_at, 'set-at'                   ; value key handle --

        _ check_hashtable               ; -- value key hashtable

        _dup
        _hashtable_raw_count
        _lit 3
        _star
        _over
        _hashtable_raw_capacity
        _twostar
        _ugt
        _if .1
        _dup
        _ hashtable_grow_unchecked
        _then .1

set_at_unchecked:

        push    this_register
        mov     this_register, rbx      ; -- value key hashtable
        poprbx                          ; -- value key
        _dup
        _ this_hashtable_find_index_for_key     ; -- value key tagged-index ?
        _tagged_if_not .2
        ; key was not found
        ; we're adding an entry
        _this_hashtable_increment_raw_count
        _then .2                        ; -- value key tagged-index
        _untag_fixnum
        _this_hashtable_set_nth_pair
        pop     this_register

        next
endcode

; ### +deleted+
feline_constant deleted, '+deleted+', S_deleted

; ### delete-at
code delete_at, 'delete-at'     ; key handle --

        _ check_hashtable       ; -- key hashtable

        push    this_register
        mov     this_register, rbx      ; -- key hashtable

        _ find_index_for_key_unchecked  ; -- tagged-index/f ?

        _tagged_if .1

        ; -- tagged-index
        _ deleted
        _ deleted
        _ rot
        _untag_fixnum
        _this_hashtable_set_nth_pair

        _else .1

        ; not found
        _drop

        _then .1

        pop     this_register
        next
endcode

; ### hashtable-grow
code hashtable_grow, 'hashtable-grow'   ; hashtable --
        _ check_hashtable               ; -- hashtable

hashtable_grow_unchecked:
        push    this_register
        mov     this_register, rbx

        _dup
        _ hashtable_keys_unchecked
        _swap
        _ hashtable_values_unchecked    ; -- keys values

        _this_hashtable_data
        _ raw_free

        _this_hashtable_raw_capacity    ; -- ... n
        ; double existing capacity
        _twostar
        _dup
        _this_hashtable_set_raw_capacity
        ; 16 bytes per entry
        shl     rbx, 4                  ; -- ... n*16
        _ raw_allocate
        _this_hashtable_set_data        ; -- keys values

        _this_hashtable_raw_capacity
        _twostar
        _register_do_times .1
        _f
        _this_hashtable_data
        _i
        _cells
        _plus
        _store
        _loop .1

        ; reset count
        _zero
        _this_hashtable_set_raw_count

        _dup
        _ vector_length
        _untag_fixnum
        _register_do_times .2

        ; value
        _tagged_loop_index
        _over
        _ vector_nth                    ; -- keys values nth-value

        ; key
        _pick                           ; -- keys values nth-value keys
        _tagged_loop_index
        _swap
        _ vector_nth                    ; -- keys values nth-value nth-key

        _this
        _ set_at_unchecked

        _loop .2                        ; -- keys values
        _2drop
        pop     this_register
        next
endcode

; ### hash-combine
code hash_combine, 'hash-combine'       ; hash1 hash2 -- newhash

        sar     rbx, TAG_BITS           ; hash2 (untagged) in rbx
        mov     rax, [rbp]
        sar     rax, TAG_BITS           ; hash1 (untagged) in rax
        lea     rbp, [rbp + BYTES_PER_CELL]

        mov     rdx, $9e3779b97f4a7800
        add     rbx, rdx

        mov     rdx, rax
        shl     rdx, 6
        add     rbx, rdx

        mov     rdx, rax
        sar     rdx, 2
        add     rbx, rdx

        xor     rbx, rax

        _lit MOST_POSITIVE_FIXNUM
        _and

        _tag_fixnum

        next
endcode

; ### hashtable>string
code hashtable_to_string, 'hashtable>string'    ; hashtable -- string
        _ check_hashtable

        push    this_register
        mov     this_register, rbx
        poprbx

        _quote "H{"
        _ string_to_sbuf
        _this_hashtable_raw_capacity

        _register_do_times .1

        _raw_loop_index
        _this_hashtable_nth_key
        _dup
        _tagged_if .2
        _quote " { "
        _pick
        _ sbuf_append_string
        _ object_to_string
        _over
        _ sbuf_append_string
        _lit tagged_char(32)
        _over
        _ sbuf_push
        _raw_loop_index
        _this_hashtable_nth_value
        _ object_to_string
        _over
        _ sbuf_append_string
        _quote " }"
        _over
        _ sbuf_append_string
        _else .2
        _drop
        _then .2

        _loop .1

        pop     this_register

        _quote " }"
        _over
        _ sbuf_append_string
        _ sbuf_to_string

        next
endcode

; ### .hashtable
code dot_hashtable, '.hashtable'        ; hashtable --
        _ check_hashtable

        push    this_register
        mov     this_register, rbx

        _write "H{"
        _hashtable_raw_capacity
        _register_do_times .1
        _i
        _this_hashtable_nth_key
        _dup
        _tagged_if .2
        _write " { "
        _ dot_object
        _ space
        _i
        _this_hashtable_nth_value
        _ dot_object
        _ space
        _write "}"
        _else .2
        _drop
        _then .2
        _loop .1
        _write " }"

        pop     this_register
        next
endcode
