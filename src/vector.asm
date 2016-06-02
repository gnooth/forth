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

; ### vector?
code vector?, 'vector?'                 ; handle -- t|f
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_type                    ; -- object-type
        _lit OBJECT_TYPE_VECTOR
        _feline_equal
        _return
        _then .2
        _then .1
        mov     ebx, f_value
        next
endcode

; ### error-not-vector
code error_not_vector, 'error-not-vector' ; x --
        ; REVIEW
        _drop
        _true
        _abortq "not a vector"
        next
endcode

; ### check-vector
code check_vector, 'check-vector'       ; handle -- vector
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object|0
        _dup_if .2
        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_VECTOR
        _equal
        _if .3
        _return
        _then .3
        _then .2
        _then .1

        _ error_not_vector
        next
endcode

; ### vector-length
code vector_length, 'vector-length'     ; vector -- length
        _ check_vector
        _vector_length
        _tag_fixnum
        next
endcode

; ### vector-set-length
code vector_set_length, 'vector-set-length' ; tagged-new-length handle --
        _ check_vector                  ; -- tagged-new-length vector
        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- tagged-new-length
        _untag_fixnum                   ; -- new-length
        _dup
        _this_vector_capacity
        _ugt
        _if .1                          ; -- new-length
        _dup
        _this
        _ vector_ensure_capacity
        _then .1                        ; -- new-length
        _dup
        _this_vector_length
        _ugt
        _if .2                          ; -- new-length
        ; initialize new cells to f
        _dup
        _this_vector_length
        _?do .3
        _f
        _i
        _this_vector_set_nth_unsafe
        _loop .3
        _then .2
        _this_vector_set_length
        pop     this_register
        next
endcode

; ### vector-delete-all
code vector_delete_all, 'vector-delete-all' ; handle --
        _ check_vector
        _zero
        _swap                           ; -- 0 vector
        _vector_set_length
        next
endcode

; ### vector-data
code vector_data, 'vector-data'         ; vector -- data-address
        _ check_vector
        _vector_data
        next
endcode

; ### <vector>
code new_vector, '<vector>'             ; capacity -- handle

        _untag_fixnum

new_vector_untagged:
        _lit 4
        _cells
        _ allocate_object
        _duptor                         ; -- capacity vector                    r: -- vector
        _lit 4
        _cells
        _ erase                         ; -- capacity                           r: -- vector
        _rfetch
        _lit OBJECT_TYPE_VECTOR
        _object_set_type                ; -- capacity
        _dup                            ; -- capacity capacity                  r: -- vector
        _cells
        _ iallocate                     ; -- capacity data-address              r: -- vector
        _rfetch                         ; -- capacity data-address vector       r: -- vector
        _vector_set_data                ; -- capacity                           r: -- vector
        _rfetch                         ; -- capacity vector                    r: -- vector
        _swap                           ; -- vector capacity                    r: -- vector
        _vector_set_capacity            ; --                                    r: -- vector
        _rfrom                          ; -- vector

        ; return handle of allocated object
        _ new_handle                    ; -- handle

        next
endcode

; ### vector-new-sequence
code vector_new_sequence, 'vector-new-sequence' ; len seq -- newseq
        _drop
        _ new_vector
        next
endcode

; ### process-token
code process_token, 'process-token'     ; string -- object
        _ token_character_literal?
        _tagged_if .1
        _return
        _then .1

        _ token_string_literal?
        _tagged_if .2
        _return
        _then .2

        _ string_to_number

        next
endcode

; ### V{
code parse_vector, 'V{', IMMEDIATE      ; -- handle
        _lit 10
        _ new_vector_untagged
        _tor
        _begin .1
        _ parse_token                   ; -- string
        _dup
        _quote "}"
        _ string_equal?
        _untag_boolean
        _zeq
        _while .1
        _ process_token                 ; -- object
        _rfetch
        _ vector_push
        _repeat .1
        _drop
        _rfrom                          ; -- handle

        _ statefetch
        _if .2
        ; Add the newly-created vector to gc-roots. This protects it from
        ; being collected and also ensures that its children will be scanned.
        _dup
        _ gc_add_root
        _ literal
        _then .2

        next
endcode

; ### ~vector
code destroy_vector, '~vector'          ; handle --
        _ check_vector                  ; -- vector
        _ destroy_vector_unchecked
        next
endcode

; ### ~vector-unchecked
code destroy_vector_unchecked, '~vector-unchecked' ; vector --
        _dup
        _vector_data
        _ ifree                         ; -- vector

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

; ### vector-resize
code vector_resize, 'vector-resize'     ; vector new-capacity --
        _over                           ; -- vector new-capacity vector
        _vector_data                    ; -- vector new-capacity data-address
        _over                           ; -- vector new-capacity data-address new-capacity
        _cells
        _ resize                        ; -- vector new-capacity new-data-address ior
        _ throw                         ; -- vector new-capacity new-data-address
        _tor
        _over                           ; -- vector new-capacity vector         r: -- new-data-addr
        _swap
        _vector_set_capacity            ; -- vector                             r: -- new-data-addr
        _rfrom                          ; -- vector new-data-addr
        _swap                           ; -- new-data-addr vector
        _vector_set_data
        next
endcode

; ### vector-ensure-capacity
code vector_ensure_capacity, 'vector-ensure-capacity'   ; u vector --
        _ twodup                        ; -- u vector u vector
        _vector_capacity                ; -- u vector u capacity
        _ugt
        _if .1                          ; -- u vector
        _dup                            ; -- u vector vector
        _vector_capacity                ; -- u vector capacity
        _twostar                        ; -- u vector capacity*2
        _ rot                           ; -- vector capacity*2 u
        _ max                           ; -- vector new-capacity
        _ vector_resize
        _else .1
        _2drop
        _then .1
        next
endcode

; ### vector-nth-unsafe
code vector_nth_unsafe, 'vector-nth-unsafe' ; index handle -- element
        _swap
        _untag_fixnum
        _swap
        _handle_to_object_unsafe
        _vector_nth_unsafe
        next
endcode

; ### vector-nth
code vector_nth, 'vector-nth'           ; index handle -- element

%ifdef USE_TAGS
        _swap
        _untag_fixnum
        _swap
%endif

vector_nth_untagged:
        _ check_vector

        _twodup
        _vector_length
        _ult
        _if .1
        _vector_nth_unsafe
        _return
        _then .1

        _2drop
        _true
        _abortq "vector-nth index out of range"
        next
endcode

; ### vector-set-nth
code vector_set_nth, 'vector-set-nth'   ; element index vector --

%ifdef USE_TAGS
        _swap
        _untag_fixnum
        _swap
%endif

vector_set_nth_untagged:
        _ check_vector
        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- element untagged-index
        _dup
        _this
        _ vector_ensure_capacity        ; -- element untagged-index
        _dup
        _oneplus
        _this_vector_length
        _ max
        _this_vector_set_length
        _this_vector_set_nth_unsafe
        pop     this_register
        next
endcode

; ### vector-insert-nth
code vector_insert_nth, 'vector-insert-nth' ; element n vector --
        _ check_vector

        push    this_register
        mov     this_register, rbx      ; -- element n vector

        _twodup                         ; -- element n vector n vector
        _vector_length                  ; -- element n vector n length
        _ugt                            ; -- element n vector
        _abortq "vector-insert-nth n > length"

        _dup                            ; -- element n vector vector
        _vector_length                  ; -- element n vector length
        _oneplus                        ; -- element n vector length+1
        _over                           ; -- element n vector length+1 vector
        _ vector_ensure_capacity        ; -- element n vector

        _vector_data                    ; -- element n data-address
        _over                           ; -- element n data-address n
        _duptor                         ; -- element n data-address n           r: -- n
        _cells
        _plus                           ; -- element n addr
        _dup
        _cellplus                       ; -- element n addr addr+8
        _this
        _vector_length
        _rfrom
        _minus
        _cells                          ; -- element n addr addr+8 #bytes
        _ cmoveup                       ; -- element n

        _this_vector_length             ; -- element n length
        _oneplus                        ; -- element n length+1
        _this_vector_set_length         ; -- element n

        _this_vector_set_nth_unsafe     ; ---

        pop     this_register
        next
endcode

; ### vector-remove-nth
code vector_remove_nth, 'vector-remove-nth' ; n handle --

%ifdef USE_TAGS
        _swap
        _untag_fixnum
        _swap
%endif

        _ check_vector

        push    this_register
        mov     this_register, rbx

        _twodup
        _vector_length                  ; -- n vector n length
        _zero                           ; -- n vector n length 0
        _swap                           ; -- n vector n 0 length
        _ within                        ; -- n vector flag
        _zeq
        _abortq "vector-remove-nth n > length - 1" ; -- n vector

        _vector_data                    ; -- n addr
        _swap                           ; -- addr n
        _duptor                         ; -- addr n                     r: -- n
        _oneplus
        _cells
        _plus                           ; -- addr2
        _dup                            ; -- addr2 addr2
        _cellminus                      ; -- addr2 addr2-8
        _this
        _vector_length
        _oneminus                       ; -- addr2 addr2-8 len-1        r: -- n
        _rfrom                          ; -- addr2 addr2-8 len-1 n
        _minus                          ; -- addr2 addr2-8 len-1-n
        _cells                          ; -- addr2 addr2-8 #bytes
        _ cmove

        _zero
        _this_vector_data
        _this_vector_length
        _oneminus
        _cells
        _plus
        _store

        _this_vector_length
        _oneminus
        _this_vector_set_length

        pop     this_register
        next
endcode

; ### vector-push-unchecked
code vector_push_unchecked, 'vector-push-unchecked' ; element vector --
        push    this_register           ; save callee-saved register
        mov     this_register, rbx      ; vector in this_register
        _vector_length                  ; -- element length
        _dup                            ; -- element length length
        _oneplus                        ; -- element length length+1
        _dup                            ; -- element length length+1 length+1
        _this                           ; -- element length length+1 length+1 this
        _ vector_ensure_capacity        ; -- element length length+1
        _this_vector_set_length         ; -- element length
        _this_vector_set_nth_unsafe     ; --
        pop     this_register           ; restore callee-saved register
        next
endcode

; ### vector-push
code vector_push, 'vector-push'         ; element handle --
        _ check_vector
        _ vector_push_unchecked
        next
endcode

; ### vector-pop-unchecked              ; vector -- element
code vector_pop_unchecked, 'vector-pop-unchecked'
        push    this_register
        mov     this_register, rbx

        _vector_length
        _oneminus
        _dup
        _zge
        _if .1
        _dup
        _this_vector_set_length
        _this_vector_nth_unsafe         ; -- element
        pop     this_register
        _else .1
        _drop
        pop     this_register
        _true
        _abortq "vector-pop-unchecked vector is empty"
        _then .1

        next
endcode

; ### vector-pop
code vector_pop, 'vector-pop'           ; handle -- element
        _ check_vector                  ; -- vector
        _ vector_pop_unchecked
        next
endcode

; ### vector-equal?
code vector_equal?, 'vector-equal?'     ; vector1 vector2 -- t|f
        _ check_vector
        _swap
        _ check_vector                  ; -- v1 v2

        _twodup
        _vector_length
        _swap
        _vector_length
        _notequal
        _if .1
        _2drop
        _f
        _return
        _then .1                        ; -- v1 v2

        _over
        _vector_length
        _tor
        _vector_data
        _swap
        _vector_data
        _rfrom
        _cells
        _ memequal
        _tag_boolean

        next
endcode

; ### vector-each
code vector_each, 'vector-each'         ; vector xt --
        _swap
        _ check_vector                  ; -- xt vector

        push    this_register
        mov     this_register, rbx
        push    r12
        mov     rax, [rbp]              ; xt in rax
        _2drop                          ; adjust stack
        mov     r12, [rax]              ; address to call in r12
        _this_vector_length
        _zero
        _?do .1
        _i
        _this_vector_nth_unsafe         ; -- element
        call    r12
        _loop .1
        pop     r12
        pop     this_register
        next
endcode

; ### vector-each-index
code vector_each_index, 'vector-each-index' ; vector quot: ( element index -- ) --
        _swap
        _ check_vector                  ; -- xt vector

        push    this_register
        mov     this_register, rbx
        push    r12
        mov     rax, [rbp]              ; xt in rax
        _2drop                          ; adjust stack
        mov     r12, [rax]              ; address to call in r12
        _this_vector_length
        _zero
        _?do .1
        _i                              ; -- i
        _this_vector_nth_unsafe         ; -- element
        _i                              ; -- element i
        _tag_fixnum                     ; -- element index
        call    r12
        _loop .1                        ; --
        pop     r12
        pop     this_register
        next
endcode

; ### vector-find-string
code vector_find_string, 'vector-find-string' ; string vector -- index t|f
        _ check_vector

        push    this_register
        mov     this_register, rbx

        _vector_length
        _zero
        _?do .1
        _i
        _this_vector_nth_unsafe         ; -- string element
        _over
        _ string_equal?                 ; -- string t|f
        _tagged_if .2
        ; found it!
        _drop
        _i
        _tag_fixnum
        _t
        _unloop
        jmp     .exit
        _then .2
        _loop .1

        ; not found
        _drop
        _f
        _f

.exit:
        pop     this_register
        next
endcode

; ### .vector
code dot_vector, '.vector'              ; vector --
        _ check_vector

        push    this_register
        mov     this_register, rbx

        _dotq "V{ "
        _vector_length
        _zero
        _?do .1
        _i
        _this
        _vector_nth_unsafe
        _ dot_object
        _loop .1
        _dotq "}"

        pop     this_register
        next
endcode

; ### vector-clone
code vector_clone, 'vector-clone'       ; old -- new
        _dup
        _ vector_length
        _ new_vector                    ; -- old new
        _swap

        _quotation .1
        _over
        _ vector_push
        _end_quotation .1

        _ vector_each
        next
endcode

; ### vector>array
code vector_to_array, 'vector>array'    ; vector -- array
        _dup
        _ vector_length
        _f
        _ new_array                     ; -- vector array
        _swap                           ; -- array vector

        _quotation .1
        ; -- element index
        _lit 2
        _forth_pick
        ; -- element index array
        _ array_set_nth
        _end_quotation .1               ; -- array vector quotation

        _ vector_each_index             ; -- array
        next
endcode
