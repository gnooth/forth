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

; ### state
variable state, 'state', 0              ; CORE, TOOLS EXT

; ### state@
code statefetch, 'state@'
        pushrbx
        mov     rbx, state_data
        mov     rbx, [rbx]
        next
endcode

; ### [
code lbrack, '[', IMMEDIATE
        xor     eax, eax
        mov     rdx, state_data
        mov     [rdx], rax
        next
endcode

; ### ]
code rbrack, ']'
        xor     eax, eax
        dec     rax
        mov     rdx, state_data
        mov     [rdx], rax
        next
endcode

; ### ?stack
code ?stack, '?stack'
        cmp     rbp, [sp0_data]
        ja      .1
        next
.1:
        mov     rbp, [sp0_data]
        _dotq   "Stack underflow"
        jmp     abort
endcode

; ### do-defined
code do_defined, 'do-defined'           ; xt flag --
        _ statefetch
        _if do_defined1
        _ zgt
        _if do_defined2
        ; immediate word
        _ flush_compilation_queue
        _ execute
        _else do_defined2
        _ compilecomma
        _then do_defined2
        _else do_defined1
        _drop
        _ execute
        _ ?stack
        _then do_defined1
        next
endcode

; ### interpret
code interpret, 'interpret'             ; --
        _begin interp0
        _ blchar
        _ word_                         ; -- c-addr
        _ dup                           ; -- c-addr c-addr
        _cfetch                         ; -- c-addr len
        _zeq                            ; -- c-addr flag
        _if .1
        _ drop                          ; --
        _return
        _then .1                        ; -- c-addr
        _ find
        _ ?dup
        _if interp2
        _ do_defined
        _else interp2                   ; -- c-addr
        _ number
        _ statefetch
        _if interp3
        _ flush_compilation_queue
        _ double?
        _if interp4
        _ twoliteral
        _else interp4
        _ drop
        _ literal
        _then interp4
        _else interp3
        _ double?
        _zeq
        _if .6
        _ drop
        _then .6
        _then interp3
        _then interp2
        _again interp0
        next
endcode
