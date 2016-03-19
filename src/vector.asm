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
code vector?, 'vector?'                 ; object -- flag
        test    rbx, rbx
        jz      .1
        _object_type
        cmp     rbx, OBJECT_TYPE_VECTOR
        jnz     .2
        mov     rbx, -1
        _return
.2:
        xor     ebx, ebx
.1:
        next
endcode

; ### check-vector
code check_vector, 'check-vector'       ; handle-or-object -- vector
        ; REVIEW
        _dup
        _ handle?
        _if .1
        _ to_object
        _then .1

        _dup
        _ vector?
        _if .2
        _return
        _then .2

        _drop
        _true
        _abortq "not a vector"
        next
endcode

; ### vector-length
code vector_length, 'vector-length'     ; vector -- length
        _ check_vector
        _slot1
        next
endcode

; ### vector-set-length
code vector_set_length, 'vector-set-length' ; vector length --
        _swap
        _ check_vector
        _swap
        _set_slot1
        next
endcode

; ### vector-data
code vector_data, 'vector-data'         ; vector -- data-address
        _slot2
        next
endcode

; ### vector-set-data
code vector_set_data, 'vector-set-data' ; vector data-address  --
        _swap
        _ check_vector
        _swap
        _set_slot2
        next
endcode

; ### vector-capacity
code vector_capacity, 'vector-capacity' ; vector -- capacity
        _ check_vector
        _slot3
        next
endcode

; ### vector-set-capacity
code vector_set_capacity, 'vector-set-capacity' ; vector capacity --
        _swap
        _ check_vector
        _swap
        _set_slot3
        next
endcode

; ### <vector>
code new_vector, '<vector>'             ; capacity -- vector
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
        _swap                           ; -- capacity vector data-address       r: -- vector
        _ vector_set_data               ; -- capacity                           r: -- vector
        _rfetch                         ; -- capacity vector                    r: -- vector
        _swap                           ; -- vector capacity                    r: -- vector
        _ vector_set_capacity           ; --                                    r: -- vector
        _rfrom                          ; -- vector

        ; return handle of allocated object
        _ new_handle

        next
endcode

; ### ~vector
code destroy_vector, '~vector'          ; vector --
        _ check_vector
        _ check_allocated_object

        _dup
        _ vector_data
        _ ifree                         ; -- vector

        _ in_gc?
        _zeq_if .1
        ; Not in gc. Update the allocated-objects vector. (If we are in gc,
        ; we don't need to update the allocated-objects vector because we
        ; replace it with the live-objects vector at the end of gc.)
        _dup
        _ remove_allocated_object
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
        _swap
        _ check_vector
        _swap
        _ over                          ; -- vector new-capacity vector
        _ vector_data                   ; -- vector new-capacity data-address
        _ over                          ; -- vector new-capacity data-address new-capacity
        _cells
        _ resize                        ; -- vector new-capacity new-data-address ior
        _ throw                         ; -- vector new-capacity new-data-address
        _tor
        _ over                          ; -- vector new-capacity vector     r: -- new-data-addr
        _ swap
        _ vector_set_capacity           ; -- vector                         r: -- new-data-addr
        _rfrom                          ; -- vector new-data-addr
        _ vector_set_data
        next
endcode

; ### vector-ensure-capacity
code vector_ensure_capacity, 'vector-ensure-capacity'   ; u vector --
        _ check_vector
        _ twodup                        ; -- u vector u vector
        _ vector_capacity               ; -- u vector u capacity
        _ ugt
        _if .1                          ; -- u vector
        _dup                            ; -- u vector vector
        _ vector_capacity               ; -- u vector capacity
        _twostar                        ; -- u vector capacity*2
        _ rot                           ; -- vector capacity*2 u
        _ max                           ; -- vector new-capacity
        _ vector_resize
        _else .1
        _2drop
        _then .1
        next
endcode

; ### vector-nth
code vector_nth, 'vector-nth'           ; index vector -- elt
        _twodup
        _ vector_length
        _ult
        _if .1
        _ vector_data
        _swap
        _cells
        _plus
        _fetch
        _else .1
        _true
        _abortq "vector-nth index out of range"
        _then .1
        next
endcode

; ### vector-check-index
code vector_check_index, 'vector-check-index' ; vector index -- flag
        _swap
        _ check_vector                  ; -- index vector
        _ vector_length                 ; -- index length
        _ult                            ; -- flag
        next
endcode

; ### vector-ref
code vector_ref, 'vector-ref'           ; vector index -- elt
        _twodup
        _ vector_check_index
        _if .1
        _swap
        _ vector_data
        _swap
        _cells
        _plus
        _fetch
        _else .1
        _true
        _abortq "vector-ref index out of range"
        _then .1
        next
endcode

; ### vector-set-nth
code vector_set_nth, 'vector-set-nth'   ; elt index vector --
        _twodup
        _ vector_length
        _ ult
        _if .1
        _ vector_data
        _swap
        _cells
        _plus
        _ store
        _else .1
        _true
        _abortq "vector-set-nth index out of range"
        _then .1
        next
endcode

; ### vector-set
code vector_set, 'vector-set'           ; vector index element --
        _ rrot                          ; -- element vector index
        _ twodup
        _ vector_check_index
        _if .1                          ; -- element vector index
        _ swap
        _ vector_data
        _ swap
        _cells
        _plus
        _ store
        _else .1
        _true
        _abortq "vector-set index out of range"
        _then .1
        next
endcode

; ### vector-insert-nth
code vector_insert_nth, 'vector-insert-nth' ; elt n vector --
        push    r15
        mov     r15, rbx                ; -- elt n vector

        _ twodup                        ; -- elt n vector n vector
        _ vector_length                 ; -- elt n vector n length
        _ ugt                           ; -- elt n vector
        _abortq "vector-insert-nth n > length"

        _dup                            ; -- elt n vector vector
        _ vector_length                 ; -- elt n vector length
        _oneplus                        ; -- elt n vector length+1
        _ over                          ; -- elt n vector length+1 vector
        _ vector_ensure_capacity        ; -- elt n vector

        _ vector_data                   ; -- elt n data-address
        _ over                          ; -- elt n data-address n
        _duptor                         ; -- elt n data-address n       r: -- n
        _cells
        _plus                           ; -- elt n addr
        _dup
        _cellplus                       ; -- elt n addr addr+8
        pushd   r15
        _ vector_length
        _rfrom
        _ minus
        _cells                          ; -- elt n addr addr+8 #bytes
        _ cmoveup                       ; -- elt n

        pushd   r15                     ; -- elt n vector
        _dup                            ; -- elt n vector vector
        _ vector_length                 ; -- elt n vector length
        _oneplus                        ; -- elt n vector length+1
        _ vector_set_length             ; -- elt n

        pushd   r15                     ; -- elt n vector
        _ vector_set_nth                ; ---

        pop     r15
        next
endcode

; ### vector-remove-nth
code vector_remove_nth, 'vector-remove-nth' ; n vector --
        push    r15
        mov     r15, rbx

        _ twodup
        _ vector_length                 ; -- n vector n length
        _zero                           ; -- n vector n length 0
        _ swap                          ; -- n vector n 0 length
        _ within                        ; -- n vector flag
        _ zeq
        _abortq "vector-remove-nth n > length - 1"      ; -- n vector

        _ vector_data                   ; -- n addr
        _ swap                          ; -- addr n
        _duptor                         ; -- addr n                      r: -- n
        _oneplus
        _cells
        _plus                           ; -- addr2
        _dup                            ; -- addr2 addr2
        _cellminus                      ; -- addr2 addr2-8
        _this
        _ vector_length
        _oneminus                       ; -- addr2 addr2-8 len-1         r: -- n
        _rfrom                          ; -- addr2 addr2-8 len-1 n
        _ minus                         ; -- addr2 addr2-8 len-1-n
        _cells                          ; -- addr2 addr2-8 #bytes
        _ cmove

        _zero
        _this
        _ vector_data
        _this
        _ vector_length
        _oneminus
        _cells
        _plus
        _ store

        _this
        _dup
        _ vector_length
        _oneminus
        _ vector_set_length

        pop     r15
        next
endcode

; ### vector-push
code vector_push, 'vector-push'         ; elt vector --
        _ check_vector
        push    r15                     ; save callee-saved register
        mov     r15, rbx                ; vector in r15
        _ vector_length                 ; -- elt length
        _dup                            ; -- elt length length
        _oneplus                        ; -- elt length length+1
        _dup                            ; -- elt length length+1 length+1
        _this                           ; -- elt length length+1 length+1 this
        _ vector_ensure_capacity        ; -- elt length length+1
        _this                           ; -- elt length length+1 this
        _swap                           ; -- elt length this length+1
        _ vector_set_length             ; -- elt length
        _this                           ; -- elt length this
        _ vector_set_nth
        pop     r15                     ; restore callee-saved register
        next
endcode

; ### vector-pop
code vector_pop, 'vector-pop'           ; vector -- elt
        _ check_vector                  ; -- vector
        push    r15
        mov     r15, rbx

        _ vector_length
        _oneminus
        _dup
        _zlt
        _abortq "vector-pop vector is empty"

        _this
        _ vector_nth                    ; -- elt

        _this
        _dup
        _ vector_length
        _oneminus
        _ vector_set_length

        pop     r15
        next
endcode

; ### vector-each
code vector_each, 'vector-each'         ; vector xt --
        _swap
        _ check_vector
        push    r15
        mov     r15, rbx
        _ vector_length
        _zero
        _?do .1
        _i
        _this
        _ vector_nth                    ; -- xt elt
        _over                           ; -- xt elt xt
        _ execute
        _loop .1                        ; -- xt
        _drop
        pop     r15
        next
endcode

; ### .vector
code dot_vector, '.vector'              ; vector --
        push    r15
        mov     r15, rbx

        _dotq "{ "
        _ vector_length
        _zero
        _?do .1
        _i
        _this
        _ vector_nth
        _dup
        _ object?
        _if .2
        _ dot_object
        _else .2
        _ dot
        _then .2
        _loop .1
        _dotq "}"

        pop     r15
        next
endcode
