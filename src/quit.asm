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

; ### vocab-find-name
code vocab_find_name, 'vocab-find-name' ; name vocab -- symbol/name ?
        _ lookup_vocab
        _dup
        _tagged_if .1
        _ vocab_hashtable
        _ at_star
        _then .1
        next
endcode

; ### find-qualified-name               ; string -- symbol/string ?
code find_qualified_name, 'find-qualified-name'
        _lit ':'
        _tag_char
        _over
        _ index                         ; -- string index/f
        cmp     rbx, f_value
        jnz     .1
        _return
.1:
        ; -- string index
        _dupd                           ; -- string string index

        _quotation .2
        _ string_head
        _end_quotation .2

        _quotation .3
        _lit tagged_fixnum(1)
        _ plus
        _ string_tail
        _end_quotation .3

        _ twobi                         ; -- string head tail

        _swap

        _ vocab_find_name               ; -- string symbol/string ?

        _tagged_if .4
        _nip
        _t
        _else .4
        _drop
        _f
        _then .4

        next
endcode

; ### find-name
code find_name, 'find-name'             ; string -- symbol/string ?
        _dup
        _ current_vocab
        _ vocab_hashtable
        _ at_star
        _tagged_if .0
        _nip
        _t
        _return
        _else .0
        _drop
        _then .0

        _ context_vector
        _ vector_length
        _untag_fixnum
        _zero
        _?do .1
        _dup                            ; -- string string
        _i
        _ context_vector
        _ vector_nth_untagged           ; -- string string vocab
        _ vocab_hashtable
        _ at_star                       ; -- string symbol/f ?
        _tagged_if .2
        _nip
        _t
        _unloop
        _return
        _then .2
        _drop
        _loop .1

        _ find_qualified_name

        next
endcode

; ### error
code error, 'error'                     ; string --
        _ throw
        next
endcode

; ### undefined
code undefined, 'undefined'             ; string/symbol --
        _dup
        _ symbol?
        _tagged_if .1
        _ symbol_name
        _then .1
        _quote " ?"
        _ concat
        _ error
        next
endcode

; ### must-find-name
code must_find_name, 'must-find-name'   ; string -- symbol
        _ find_name
        _tagged_if_not .1
        _ undefined
        _then .1
        next
endcode

; ### must-find-global
code must_find_global, 'must-find-global'       ; string -- global
        _ find_name
        _tagged_if .1
        _ verify_global
        _else .1
        _ undefined
        _then .1
        next
endcode

; ### literal?
code literal?, 'literal?'               ; string -- literal/string ?
        _ token_character_literal?
        _tagged_if .1                   ; -- literal
        _t
        _return
        _then .1                        ; -- string

        _ token_string_literal?
        _tagged_if .2                   ; -- literal
        _t
        _return
        _then .2                        ; -- string

        _dup
        _ string_to_number              ; -- string n/f
        _dup
        _tagged_if .3                   ; -- string n
        _nip
        _t
        _return
        _else .3
        _drop
        _then .3                        ; -- string

        _f

        next
endcode

; ### interpret1
code interpret1, 'interpret1'   ; string --
        _ find_name             ; -- symbol/string ?
        _tagged_if .1
        _ call_symbol
        _return
        _then .1

        _ literal?
        _tagged_if .2
        _return
        _then .2                ; -- string

        _ undefined

        next
endcode

; ### ?stack
code ?stack, '?stack'
        cmp     rbp, [sp0_data]
        ja      .1
        next
.1:
        mov     rbp, [sp0_data]
        _error "data stack underflow"
        next
endcode

; ### interpret
code interpret, 'interpret'             ; --
        _begin .1
        _ ?stack
        _ parse_token                   ; -- string/f
        _dup
        _tagged_while .1
        _ interpret1
        _repeat .1
        _drop
        next
endcode

; ### reset
code reset, 'reset'
        _ lp0
        _?dup_if .1
        _ lpstore
        _then .1

        _ get_namestack
        _dup
        _ vector?
        _tagged_if .2
        _lit tagged_fixnum(1)
        _swap
        _ vector_set_length
        _then .2

        ; REVIEW windows-ui
        _ forth_standard_output

        _f
        _to_global in_definition?

        jmp     quit
        next                            ; for decompiler
endcode

; ### error-location
feline_global error_location, 'error-location'

; ### print-source-line
code print_source_line, 'print-source-line'     ; path line-number --
        _swap
        _ file_lines
        _ nth
        _ write_string
        next
endcode

; ### mark-error-location
code mark_error_location, 'mark-error-location'         ; --
        _ error_location
        _dup
        _tagged_if .1
        _ nl
        _ third
        _ spaces
        _lit '^'
        _tag_char
        _ write_char
        _ nl
        _else .1
        _drop
        _then .1
        next
endcode

; ### print-error-location
code print_error_location, 'print-error-location'       ; --
        _ error_location
        _dup
        _ array_first           ; path
        _dup
        _tagged_if .1
        _ write_string
        _else .1
        _2drop
        _return
        _then .1
        _ array_second          ; line number
        _dup
        _tagged_if .2
        _write " line "
        _lit tagged_fixnum(1)
        _ plus
        _ decimal_dot
        _else .2
        _drop
        _then .2
        next
endcode

; ### where
code where, 'where'             ; --
        _ error_location
        _tagged_if_not .1
        _ location
        _to_global error_location
        _then .1

        _ ?nl
        _ white
        _ foreground

        _ error_location
        _ first
        _dup
        _tagged_if .2
        _ error_location
        _ second
        _ print_source_line
        _ mark_error_location
        _else .2
        _drop
        _ lexer
        _ get
        _ lexer_string
        _ write_string
        _ mark_error_location
        _then .2

        _ print_error_location

        _f
        _to_global error_location

        next
endcode

; ### do-error
code do_error, 'do-error'               ; error --
        _dup
        _ string?
        _tagged_if .1
        _ ?nl
        _ red
        _ foreground
        _ write_string
        _ where
        _ reset
        _else .1

        ; not a string

        ; REVIEW
        _ red
        _ foreground
        _write "Error: "
        _ dot_object
        _ reset

        _then .1

        next
endcode

; ### line-input?
value line_input, 'line-input?', -1

; ### query
code query, 'query'                     ; -- string/f
        _ ?nl

        _quote "accept-string"          ; -- name
        _quote "accept"                 ; -- name vocab-name
        _ ?lookup_symbol
        _dup
        _tagged_if .1
        _ call_symbol
        _return
        _then .1

        _drop

        _write "> "
        xcall   os_accept_string        ; -- untagged
        pushrbx
        mov     rbx, rax
        _?dup_if .2
        _ zcount
        _ copy_to_string
        _else .2
        _f
        _then .2

        ; last char was a newline
        mov     qword [last_char], 10
        mov     qword [output_column], 0

        next
endcode

; ### print-datastack
code print_datastack, 'print-datastack' ; --
        _ depth
        _if .1
        _ ?nl
        _ white
        _ foreground
        _write "--- Data stack:"
        _ feline_dot_s
        _then .1
        next
endcode

; ### evaluate
code evaluate, 'evaluate'               ; string --
        _ begin_scope

        _ new_lexer
        _ lexer
        _ set

        _quotation .2
        _ interpret
        _end_quotation .2
        _quotation .3
        _ do_error
        _end_quotation .3
        _ recover

        _ end_scope
        next
endcode

; ### quit
code quit, 'quit'                       ; --
        _begin .1

        ; REVIEW
        mov     rsp, [rp0_data]

        _ query                         ; -- string
        _ evaluate
        _ print_datastack

        ; REVIEW
        _ gc

        _again .1
        next
endcode

; ### break
code break, 'break'                     ; --
        _ ?nl
        _ red
        _ foreground
        _write "break called"
        _ nl
        _ white
        _ foreground
        _write "--- Data stack: "
        _ depth
        _if .1
        _ feline_dot_s
        _else .1
        _write "Empty"
        _then .1
        _ nl
        _write "Press c to continue..."
        _ nl
        _begin .2
        _ key
        _lit 'c'
        _equal
        _if .3
        _return
        _then .3
        _again .2
        next
endcode
