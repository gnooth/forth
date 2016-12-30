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

; Stringbuffers

; 4 cells: object header, length, data address, capacity

; ### sbuf?
code sbuf?, 'sbuf?'                     ; object -- t|f
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_type                    ; -- object-type
        _eq? OBJECT_TYPE_SBUF
        _return
        _then .2
        _then .1
        mov     ebx, f_value
        next
endcode

; ### error-not-sbuf
code error_not_sbuf, 'error-not-sbuf'   ; x --
        ; REVIEW
        _drop
        _error "not an sbuf"
        next
endcode

; ### check_sbuf
subroutine check_sbuf   ; handle -- sbuf
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object/0
        _dup_if .2
        _dup
        _object_type                    ; -- object object-type
        _eq? OBJECT_TYPE_SBUF
        _tagged_if .3
        ret
        _then .3
        _then .2
        _then .1

        _ error_not_sbuf
        ret
endsub

; ### sbuf-length
code sbuf_length, 'sbuf-length'         ; handle -- length
        _ check_sbuf
        _sbuf_length
        _tag_fixnum
        next
endcode

; ### sbuf-data
code sbuf_data, 'sbuf-data'             ; sbuf -- data-address
        _ check_sbuf
        _sbuf_data
        next
endcode

; ### sbuf-capacity
code sbuf_capacity, 'sbuf-capacity'     ; sbuf -- capacity
        _ check_sbuf
        _sbuf_raw_capacity
        _tag_fixnum
        next
endcode

; ### make_sbuf_internal
subroutine make_sbuf_internal   ; untagged-capacity -- sbuf
        _lit 4
        _ allocate_cells                ; -- capacity addr

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- capacity

        _this_object_set_type OBJECT_TYPE_SBUF
        _this_object_set_flags OBJECT_ALLOCATED_BIT

        _dup
        _oneplus                        ; terminal null byte
        _ iallocate
        _this_sbuf_set_data             ; -- capacity

        _this_sbuf_set_raw_capacity

        pushrbx
        mov     rbx, this_register      ; -- sbuf

        pop     this_register
        ret
endsub

; ### <sbuf>
code new_sbuf, '<sbuf>'                 ; tagged-capacity -- sbuf
        _untag_fixnum
new_sbuf_untagged:
        _ make_sbuf_internal            ; -- sbuf
        _dup
        _sbuf_data                      ; -- sbuf data-address
        _over
        _sbuf_raw_capacity              ; -- sbuf data-address capacity
        _oneplus
        _ erase                         ; -- sbuf
        _ new_handle
        next
endcode

; ### copy_to_sbuf
subroutine copy_to_sbuf ; from-addr length -- handle
        _dup
        _ make_sbuf_internal

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- from-addr length

        _dup
        _this_sbuf_set_length

        _this_sbuf_data                 ; -- from-addr length to-address
        _swap
        _ cmove                         ; --

        _zero
        _this_sbuf_data
        _this_sbuf_length
        _plus
        _cstore

        pushrbx
        mov     rbx, this_register

        _ new_handle

        pop     this_register
        ret
endsub

; ### string>sbuf
code string_to_sbuf, 'string>sbuf'      ; handle-or-string -- handle
        _ string_from
        _ copy_to_sbuf
        next
endcode

subroutine sbuf_from    ; handle -- c-addr u
        _ check_sbuf
        _duptor
        _sbuf_data
        _rfrom
        _sbuf_length
        ret
endsub

; ### sbuf>string
code sbuf_to_string, 'sbuf>string'      ; handle -- string
        _ sbuf_from
        _ copy_to_string
        next
endcode

; ### ~sbuf
code destroy_sbuf, '~sbuf'              ; handle --
        _ check_sbuf
        _ destroy_sbuf_unchecked
        next
endcode

; ### ~sbuf-unchecked
code destroy_sbuf_unchecked, '~sbuf-unchecked' ; sbuf --
        _dup
        _zeq_if .1
        _drop
        _return
        _then .1

        _dup
        _object_allocated?
        _if .2
        _dup
        _sbuf_data
        _ ifree

        _ in_gc?
        _zeq_if .4
        _dup
        _ release_handle_for_object
        _then .4
        ; Zero out the object header so it won't look like a valid object
        ; after it has been freed.
        xor     eax, eax
        mov     [rbx], rax
        _ ifree
        _else .2
        _drop
        _then .2
        next
endcode

; ### sbuf-nth-unsafe
code sbuf_nth_unsafe, 'sbuf-nth-unsafe' ; tagged-index handle -- tagged-char
; No bounds check.
        _swap
        _untag_fixnum
        _swap
        _ check_sbuf
        _sbuf_nth_unsafe
        _tag_char
        next
endcode

; ### sbuf-nth
code sbuf_nth, 'sbuf-nth'               ; tagged-index handle -- tagged-char
; Return character at index.

        _ check_sbuf                    ; -- tagged-index sbuf

        _swap
        _untag_fixnum
        _swap                           ; -- index sbuf

        _twodup
        _sbuf_length
        _ult
        _if .1
        _sbuf_nth_unsafe
        _tag_char
        _else .1
        _2drop
        _error "index out of bounds"
        _then .1

        next
endcode

; ### sbuf-?last
code sbuf_?last, 'sbuf-?last'           ; sbuf -- char/f
        _dup
        _ sbuf_length
        _untag_fixnum
        _oneminus
        _dup
        _zge
        _if .1                          ; -- sbuf untagged-fixnum
        _tag_fixnum
        _swap
        _ sbuf_nth_unsafe
        _else .1
        _2drop
        _f
        _then .1
        next
endcode

; ### sbuf-check-index
code sbuf_check_index, 'sbuf-check-index' ; handle index -- flag
        _swap
        _ check_sbuf                    ; -- index sbuf
        _swap
        _sbuf_check_index
        next
endcode

; ### sbuf_resize
subroutine sbuf_resize                  ; sbuf new-capacity --

        _swap

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- new-capacity

        _this_sbuf_data                 ; -- new-capacity data-address

        _over                           ; -- new-capacity data-address new-capacity
        _oneplus                        ; terminal null byte
        _ resize                        ; -- new-capacity new-data-address

        _this_sbuf_set_data
        _this_sbuf_set_raw_capacity

        pop     this_register
        ret
endsub

; ### sbuf_ensure_capacity
subroutine sbuf_ensure_capacity         ; u sbuf --
; Numeric argument is untagged.
        _twodup                         ; -- u sbuf u sbuf
        _sbuf_raw_capacity              ; -- u sbuf u capacity
        _ugt
        _if .1                          ; -- u sbuf
        _dup                            ; -- u sbuf sbuf
        _sbuf_raw_capacity              ; -- u sbuf capacity
        _twostar                        ; -- u sbuf capacity*2
        _oneplus                        ; -- u sbuf capacity*2+1
        _ rot                           ; -- sbuf capacity*2 u
        _ max                           ; -- sbuf new-capacity
        _ sbuf_resize
        _else .1
        _2drop
        _then .1
        ret
endsub

; ### sbuf-shorten
code sbuf_shorten, 'sbuf-shorten'       ; fixnum handle --

        _swap
        _untag_fixnum
        _swap

        _ check_sbuf                    ; -- u sbuf
        _twodup
        _sbuf_length
        _ult
        _if .2
        _sbuf_set_length
        _else .2
        _2drop
        _then .2
        next
endcode

; ### sbuf-push
code sbuf_push, 'sbuf-push'             ; tagged-char sbuf --
        _ check_sbuf

        _verify_char [rbp]
        _untag_char qword [rbp]

        push    this_register           ; save callee-saved register
        mov     this_register, rbx      ; sbuf in this_register
        _sbuf_length                    ; -- char length
        _dup                            ; -- char length length
        _oneplus                        ; -- char length length+1
        _dup                            ; -- char length length+1 length+1
        _this                           ; -- char length length+1 length+1 this
        _ sbuf_ensure_capacity          ; -- char length length+1
        _this_sbuf_set_length           ; -- char length
        _this_sbuf_set_nth_unsafe       ; --
        pop     this_register           ; restore callee-saved register
        next
endcode

; ### sbuf-append-chars
subroutine sbuf_append_chars    ; sbuf from-addr from-len --

        _ rot
        _ check_sbuf

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- from-addr from-length

        _this_sbuf_length               ; -- from-addr from-length to-length

        _over
        _plus                           ; -- from-addr from-length total-length

        _this
        _ sbuf_ensure_capacity          ; -- from-addr from-length

        _tuck                           ; -- from-length from-addr from-length

        _this_sbuf_data
        _this_sbuf_length
        _plus                           ; -- from-length from-addr from-length to-addr

        _swap
        _ cmove                         ; -- from-length

        _this_sbuf_length
        _plus                           ; -- total-length
        _this_sbuf_set_length           ; --

        _zero
        _this_sbuf_data
        _this_sbuf_length
        _plus
        _cstore

        pop     this_register
        ret
endsub

; ### sbuf-append-string
code sbuf_append_string, 'sbuf-append-string' ; sbuf string -- sbuf
; Modify sbuf by adding the characters of string to the end. Return sbuf.
        _dupd
        _ string_from
        _ sbuf_append_chars
        next
endcode

; ### sbuf-insert-nth!
code sbuf_insert_nth_destructive, 'sbuf-insert-nth!' ; tagged-char tagged-index handle -- handle

        _duptor

        ; REVIEW
        ; Handle the special case of inserting a character at offset 0
        ; in a 0-length string.
        _dup
        _ sbuf_length
        _ zero?
        _tagged_if .0
        _over
        _ zero?
        _tagged_if .00
        _nip
        _ sbuf_push
        _rfrom
        _return
        _then .00
        _then .0

        _ check_sbuf                    ; -- tagged-char tagged-index sbuf

        push    this_register
        popd    this_register           ; -- tagged-char tagged-index

        _untag_fixnum
        _swap
        _untag_char
        _swap                           ; -- char index

        _dup
        _this_sbuf_check_index          ; -- char index -1/0
        _zeq_if .1
        _error "index out of range"
        _then .1                        ; -- char index

        _this_sbuf_length
        _oneplus
        _this
        _ sbuf_ensure_capacity          ; -- char index

        ; sbuf sbuf-data index +
        _this_sbuf_data
        _over
        _plus                           ; -- char index source
        _dup
        _oneplus                        ; -- char index source dest

        _this_sbuf_length
        _lit 3
        _forth_pick
        _minus                          ; -- char index source dest count

        _ cmoveup                       ; -- char index

        _this_sbuf_length
        _oneplus
        _this_sbuf_set_length           ; -- char index

        _this_sbuf_set_nth_unsafe       ; --

        pop     this_register

        _rfrom                          ; -- handle

        next
endcode

; ### sbuf-remove-nth!
code sbuf_remove_nth_destructive, 'sbuf-remove-nth!' ; tagged-index handle -- handle
        _tuck                           ; -- handle tagged-index handle

        _ check_sbuf                    ; -- handle tagged-index sbuf

        push    this_register
        popd    this_register           ; -- handle tagged-index

        _untag_fixnum                   ; -- handle untagged-index

        _dup
        _this_sbuf_check_index          ; -- handle index -1|0
        _zeq_if .1
        _error "index out of range"
        _then .1                        ; -- handle index

        _this_sbuf_data                 ; -- handle index data-address
        _over                           ; -- handle index data-address index
        _plus
        _oneplus                        ; -- handle index src
        _dup
        _oneminus                       ; -- handle index src dest

        _ rot                           ; -- handle src dest index
        _this_sbuf_length               ; -- handle src dest index length
        _swapminus
        _oneminus
        _ cmove                         ; -- handle

        _this_sbuf_length
        _oneminus
        _this_sbuf_set_length

        pop     this_register
        next
endcode

; ### sbuf-reverse
code sbuf_reverse_in_place, 'sbuf-reverse!'     ; sbuf -- sbuf

        _duptor

        _ check_sbuf

        push    this_register
        mov     this_register, rbx
        poprbx

        _this_sbuf_length

        ; divide by 2
        shr     rbx, 1

        _lit 0
        _?do .1

        _i
        _this_sbuf_nth_unsafe           ; -- char1

        _this_sbuf_length
        _oneminus
        _i
        _minus
        _this_sbuf_nth_unsafe           ; -- char1 char2

        _i
        _this_sbuf_set_nth_unsafe

        _this_sbuf_length
        _oneminus
        _i
        _minus
        _this_sbuf_set_nth_unsafe

        _loop .1

        pop     this_register

        _rfrom

        next
endcode

; ### write-sbuf
code write_sbuf, 'write-sbuf'           ; sbuf --
        _ sbuf_from                     ; -- addr len
        call    write_chars
        next
endcode
