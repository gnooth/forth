; Copyright (C) 2012-2015 Peter Graves <gnooth@gmail.com>

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

; ### base
variable base, 'base', 10

; ### base@
code basefetch, 'base@'                 ; -- n
        pushrbx
        mov     rbx, base_data
        mov     rbx, [rbx]
        next
endcode

; ### base!
code basestore, 'base!'                 ; n --
        mov     rax, base_data
        mov     [rax], rbx
        poprbx
        next
endcode

; ### binary
code binary, 'binary'
        mov     rax, base_data
        mov     qword [rax], 2
        next
endcode

; ### decimal
code decimal, 'decimal'
; CORE
        mov     rax, base_data
        mov     qword [rax], 10
        next
endcode

; ### hex
code hex, 'hex'
; CORE EXT
        mov     rax, base_data
        mov     qword [rax], 16
        next
endcode

; ### digit
code digit, 'digit'                     ; char -- n true  |  char -- false
        _ dup
        _lit '0'
        _lit '9'
        _oneplus
        _ within
        _if digit1
        _lit '0'
        _ minus
        _ dup
        _ basefetch
        _ lt
        _if .2
        _ true
        _else .2
        _ drop
        _ false
        _then .2
        _return
        _then digit1
        _ upc
        _lit 'A'
        _ minus
        _ dup
        _zlt
        _if digit3
        _ drop
        _ false
        _return
        _then digit3
        _lit 10
        _ plus
        _ dup
        _ basefetch
        _ ge
        _if digit4
        _ drop
        _ false
        _return
        _then digit4
        _ true
        next
endcode

; ### >number
code tonumber, '>number'                ; ud1 c-addr1 u1 -- ud2 c-addr2 u2
; CORE
        _begin tonumber1
        _ dup
        _while tonumber1
        _ over
        _cfetch
        _ digit
        _zeq_if tonumber2
        _return
        _then tonumber2                 ; -- ud1 addr u1 digit
        _tor                            ; -- ud1 addr u1                r: -- digit
        _ twoswap                       ; -- c-addr u1 ud1              r: -- digit
        _rfrom                          ; -- c-addr u1 ud1 digit
        _ swap                          ; -- c-addr u1 lo digit hi
        _ basefetch                     ; -- c-addr u1 lo digit hi base
        _ umstar                        ; -- c-addr u1 lo digit ud
        _ drop                          ; -- c-addr u1 lo digit u
        _ rot
        _ basefetch
        _ umstar
        _ dplus
        _ twoswap
        _lit 1
        _ slashstring
        _repeat tonumber1
        next
endcode

; ### where
code where, 'where'                     ; --
        _ source_id
        _ zgt
        _if .1
        _ ?cr
        _ source_filename
        _fetch
        _ ?dup
        _if .2
        _ counttype
        _ space
        _then .2
        _dotq "line "
        _ source_line_number
        _fetch
        _ decdot
        _ cr
        _then .1
        next
endcode

; ### missing
code missing, 'missing'                 ; $addr --
        _cquote ' ?'
        _ appendstring
        _ msg
        _ store
        _lit -13
        _ throw
        next
endcode

; ### double?
value double?, 'double?', 0

; ### negative?
value negative?, 'negative?', 0

; ### number?
code number?, 'number?'                 ; c-addr u -- d flag
        _zero
        _to double?
        _ over
        _ cfetch
        _lit '-'
        _ equal
        _if ixnumber1
        _lit -1
        _to negative?
        _lit 1
        _ slashstring
        _else ixnumber1
        _zero
        _to negative?
        _then ixnumber1
        _zero
        _zero
        _ twoswap
        _ tonumber                      ; -- ud c-addr' u'
        _ dup                           ; -- ud c-addr' u' u'
        _zeq_if ixnumber3               ; -- ud c-addr' u'
        ; no chars left over
        _2drop
        _ true
        _return
        _then ixnumber3
        ; one or more chars left over
        _lit 1
        _ notequal
        _if ixnumber4                   ; -- ud c-addr'
        _ drop
        _ false
        _return
        _then ixnumber4
        _ cfetch                        ; -- ud char
        _lit '.'
        _ equal
        _if ixnumber5
        _lit -1
        _to double?
        _ true
        _else ixnumber5
        _ false
        _then ixnumber5
        next
endcode

; ### maybe-change-base
code maybe_change_base, 'maybe-change-base'     ; addr u -- addr' u'
        test    rbx, rbx
        jnz     .1
        ret
.1:
        _ over                          ; -- addr u addr
        _cfetch                         ; -- addr u char

        cmp     bl, '$'
        jne     .2
        _ hex
        jmp     .5
.2:
        cmp     bl, '%'
        jne     .3
        _ binary
        jmp     .5
.3:
        cmp     bl, '#'
        jne     .4
        _ decimal
        jmp     .5
.4:
        _drop
        ret
.5:
        mov     ebx, 1
        _ slashstring
        next
endcode

; ### number
code number, 'number'                   ; string -- d
; not in standard
        _duptor                         ; -- string             r: -- string
        _ count                         ; -- addr u
        _ basefetch
        _tor
        _ maybe_change_base             ; -- addr' u'
        _ number?                       ; -- d flag
        _rfrom
        _ basestore
        _zeq_if .1
        _rfrom
        _ missing                       ; doesn't return
        _then .1
        _rfromdrop
        _ negative?
        _if .2
        _ dnegate
        _then .2
        next
endcode
