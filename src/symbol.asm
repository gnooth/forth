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

; 12 slots: object header, name, vocab name, hashcode, def, props,
; value, raw code address, raw code size, flags, file, line number

%macro  _symbol_name 0                  ; symbol -- name
        _slot1
%endmacro

%macro  _this_symbol_name 0             ; -- name
        _this_slot1
%endmacro

%macro  _this_symbol_set_name 0         ; name --
        _this_set_slot1
%endmacro

%macro  _symbol_vocab_name 0            ; symbol -- vocab-name
        _slot2
%endmacro

%macro  _this_symbol_vocab_name 0       ; -- vocab-name
        _this_slot2
%endmacro

%macro  _this_symbol_set_vocab_name 0   ; vocab-name --
        _this_set_slot2
%endmacro

%macro  _symbol_hashcode 0              ; symbol -- hashcode
        _slot3
%endmacro

%macro  _symbol_set_hashcode 0          ; hashcode symbol --
        _set_slot3
%endmacro

%macro  _this_symbol_hashcode 0         ; -- hashcode
        _this_slot3
%endmacro

%macro  _this_symbol_set_hashcode 0     ; hashcode --
        _this_set_slot3
%endmacro

%macro  _symbol_def 0                   ; symbol -- definition
        _slot4
%endmacro

%macro  _symbol_set_def 0               ; definition symbol --
        _set_slot4
%endmacro

%macro  _this_symbol_def 0              ; -- definition
        _this_slot4
%endmacro

%macro  _this_symbol_set_def 0          ; definition --
        _this_set_slot4
%endmacro

%macro  _symbol_props 0
        _slot5
%endmacro

%macro  _symbol_set_props 0             ; props symbol --
        _set_slot5
%endmacro

%macro  _this_symbol_props 0            ; -- props
        _this_slot5
%endmacro

%macro  _this_symbol_set_props 0        ; props --
        _this_set_slot5
%endmacro

%macro  _symbol_value 0                 ; symbol -- value
        _slot 6
%endmacro

%macro  _symbol_set_value 0             ; value symbol --
        _set_slot 6
%endmacro

%macro  _this_symbol_set_value 0        ; value --
        _this_set_slot 6
%endmacro

%macro  _symbol_raw_code_address 0      ; symbol -- raw-code-address
        _slot 7
%endmacro

%macro  _symbol_set_raw_code_address 0  ; raw-code-address symbol --
        _set_slot 7
%endmacro

%macro  _this_symbol_set_raw_code_address 0     ; raw-code-address --
        _this_set_slot 7
%endmacro

%macro  _symbol_raw_code_size 0         ; symbol -- raw-code-size
        _slot 8
%endmacro

%macro  _symbol_set_raw_code_size 0     ; raw-code-size symbol --
        _set_slot 8
%endmacro

%macro  _this_symbol_set_raw_code_size 0        ; raw-code-size --
        _this_set_slot 8
%endmacro

%macro  _symbol_flags 0                 ; symbol -- flags
        _slot 9
%endmacro

%macro  _symbol_set_flags 0             ; flags symbol --
        _set_slot 9
%endmacro

%macro  _this_symbol_set_flags 0        ; flags --
        _this_set_slot 9
%endmacro

%macro  _symbol_file 0                  ; symbol -- file
        _slot 10
%endmacro

%macro  _symbol_set_file 0              ; file symbol --
        _set_slot 10
%endmacro

%macro  _this_symbol_set_file 0         ; file --
        _this_set_slot 10
%endmacro

%macro  _symbol_line_number 0           ; symbol -- line-number
        _slot 11
%endmacro

%macro  _symbol_set_line_number 0       ; line_number symbol --
        _set_slot 11
%endmacro

%macro  _this_symbol_set_line_number 0  ; line_number --
        _this_set_slot 11
%endmacro

; ### symbol?
code symbol?, 'symbol?'                 ; x -- ?
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object/0
        _?dup_if .2
        _object_type                    ; -- object-type
        _eq? OBJECT_TYPE_SYMBOL
        _return
        _then .2
        ; Empty handle.
        _f
        _return
        _then .1

        ; Not a handle. Make sure address is in a permissible range.
        _dup
        _ in_static_data_area?
        _zeq_if .3
        ; Address is not in a permissible range.
        ; -- x
        mov     ebx, f_value
        _return
        _then .3

        ; -- object
        _object_type                    ; -- object-type
        _eq? OBJECT_TYPE_SYMBOL

        next
endcode

; ### error-not-symbol
code error_not_symbol, 'error-not-symbol' ; x --
        _error "not a symbol"
        next
endcode

; ### verify-unboxed-symbol
code verify_unboxed_symbol, 'verify-unboxed-symbol'     ; symbol -- symbol
        ; make sure address is in a permissible range
        _dup
        _ in_static_data_area?
        _zeq_if .1
        ; address is not in a permissible range
        _ error_not_symbol
        _return
        _then .1

        _dup
        _object_type                    ; -- object object-type
        cmp     rbx, OBJECT_TYPE_SYMBOL
        poprbx
        jne .2
        _return
.2:
        _ error_not_symbol
        next
endcode

; ### check-symbol
code check_symbol, 'check-symbol'       ; x -- unboxed-symbol
        _dup
        _ deref                         ; -- x object/0
        test    rbx, rbx
        jz      .1
        movzx   eax, word [rbx]
        cmp     eax, OBJECT_TYPE_SYMBOL
        jne     .2
        _nip
        _return
.1:
        _drop
        _ verify_unboxed_symbol
        _return
.2:
        _ error_not_symbol
        next
endcode

; ### <symbol>
code new_symbol, '<symbol>'             ; name vocab -- symbol
; 12 slots: object header, name, vocab name, hashcode, def, props,
; value, code address, code size, flags, file, line number

        _lit 12
        _ allocate_cells                ; -- name vocab object-address

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- name vocab

        _this_object_set_type OBJECT_TYPE_SYMBOL

        _tuck
        _ vocab_name
        _this_symbol_set_vocab_name     ; -- vocab name

        _this_symbol_set_name           ; -- vocab

        _this_symbol_name
        _ string_hashcode
        _this_symbol_vocab_name
        _ string_hashcode
        _ hash_combine
        _this_symbol_set_hashcode

        _f
        _this_symbol_set_def

        _f
        _this_symbol_set_props

        _f
        _this_symbol_set_value

        _zero
        _this_symbol_set_raw_code_address

        _zero
        _this_symbol_set_raw_code_size

        _zero
        _this_symbol_set_flags

        _f
        _this_symbol_set_file

        _f
        _this_symbol_set_line_number

        pushrbx
        mov     rbx, this_register      ; -- vocab symbol
        pop     this_register

        _ new_handle                    ; -- vocab handle

        _swap
        _dupd                           ; -- handle handle vocab
        _ vocab_add_symbol              ; -- handle

        next
endcode

; ### create-symbol
code create_symbol, 'create-symbol'     ; name vocab -- symbol
; REVIEW does not check for redefinition

        _ lookup_vocab
        _dup
        _tagged_if_not .1
        _error "no such vocab"
        _then .1                        ; -- name vocab

        _ new_symbol                    ; -- symbol

        _dup
        _ new_wrapper
        _ one_quotation
        _over
        _ symbol_set_def                ; -- handle

        _dup
        _ compile_word

        next
endcode

; ### symbol-equal?
code symbol_equal?, 'symbol-equal?'
        _2drop
        _f
        next
endcode

; ### symbol-name
code symbol_name, 'symbol-name'         ; symbol -- name
        _ check_symbol
        _symbol_name
        next
endcode

; ### symbol-hashcode
code symbol_hashcode, 'symbol-hashcode' ; symbol -- hashcode
        _ check_symbol
        _symbol_hashcode
        next
endcode

; ### symbol-set-hashcode
code symbol_set_hashcode, 'symbol-set-hashcode' ; hashcode symbol --
        _ check_symbol
        _symbol_set_hashcode
        next
endcode

; ### symbol-vocab-name
code symbol_vocab_name, 'symbol-vocab-name' ; symbol -- vocab-name
        _ check_symbol
        _symbol_vocab_name
        next
endcode

; ### symbol-def
code symbol_def, 'symbol-def'           ; symbol -- definition
        _ check_symbol
        _symbol_def
        next
endcode

; ### symbol-set-def
code symbol_set_def, 'symbol-set-def'   ; definition symbol --
        _ check_symbol
        _symbol_set_def
        next
endcode

; ### symbol-props
code symbol_props, 'symbol-props'       ; symbol -- props
        _ check_symbol
        _symbol_props
        next
endcode

; ### symbol-prop
code symbol_prop, 'symbol-prop'         ; key symbol -- value
        _ check_symbol
        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- key

        _this_symbol_props
        _dup
        _tagged_if .1
        _ at_
        _else .1
        _nip
        _then .1

        pop     this_register
        next
endcode

; ### symbol-set-prop
code symbol_set_prop, 'symbol-set-prop' ; value key symbol --
        _ check_symbol
        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- value key

        _this_symbol_props
        _tagged_if_not .1
        _lit 2
        _ new_hashtable_untagged
        _this_symbol_set_props
        _then .1

        _this_symbol_props
        _ set_at

        pop     this_register
        next
endcode

; ### symbol-help
code symbol_help, 'symbol-help'         ; symbol -- content/f
        _quote "help"
        _swap
        _ symbol_prop
        next
endcode

; ### symbol-set-help
code symbol_set_help, 'symbol-set-help' ; content symbol --
        _quote "help"
        _swap
        _ symbol_set_prop
        next
endcode

%macro _symbol_flags_bit 1      ; symbol -- ?
        _ check_symbol
        _symbol_flags
        mov     eax, t_value
        and     rbx, %1
        mov     ebx, f_value
        cmovnz  rbx, rax
%endmacro

; ### symbol-primitive?
code symbol_primitive?, 'symbol-primitive?'     ; symbol -- ?
        _symbol_flags_bit SYMBOL_PRIMITIVE
        next
endcode

; ### symbol-immediate?
code symbol_immediate?, 'symbol-immediate?'     ; symbol -- ?
        _symbol_flags_bit SYMBOL_IMMEDIATE
        next
endcode

; ### symbol-inline?
code symbol_inline?, 'symbol-inline?'   ; symbol -- ?
        _symbol_flags_bit SYMBOL_INLINE
        next
endcode

; ### symbol-global?
code symbol_global?, 'symbol-global?'   ; symbol -- ?
        _symbol_flags_bit SYMBOL_GLOBAL
        next
endcode

; ### symbol-constant?
code symbol_constant?, 'symbol-constant?'       ; symbol -- ?
        _symbol_flags_bit SYMBOL_CONSTANT
        next
endcode

; ### symbol-special?
code symbol_special?, 'symbol-special?' ; symbol -- ?
        _symbol_flags_bit SYMBOL_SPECIAL
        next
endcode

; ### symbol-value
code symbol_value, 'symbol-value'       ; symbol -- value
        _ check_symbol
        _symbol_value
        next
endcode

; ### symbol-set-value
code symbol_set_value, 'symbol-set-value'       ; value symbol --
        _ check_symbol
        _symbol_set_value
        next
endcode

; ### error-not-global
code error_not_global, 'error-not-global'       ; x --
        _error "not a global"
        next
endcode

; ### verify-global
code verify_global, 'verify-global'     ; global -- global
        _dup
        _ check_symbol
        _symbol_flags
        and     rbx, SYMBOL_GLOBAL
        poprbx
        jz      error_not_global
        next
endcode

; ### check_global
subroutine check_global         ; x -- unboxed-symbol
        _ check_symbol
        _dup
        _symbol_flags
        and     rbx, SYMBOL_GLOBAL
        poprbx
        jz      error_not_global
        ret
endsub

; ### global-inc
code global_inc, 'global-inc'   ; symbol --
        _ check_global
        _dup
        _symbol_value
        _check_fixnum
        _oneplus
        _tag_fixnum
        _swap
        _symbol_set_value
        next
endcode

; ### global-dec
code global_dec, 'global-dec'   ; symbol --
        _ check_global
        _dup
        _symbol_value
        _check_fixnum
        _oneminus
        _tag_fixnum
        _swap
        _symbol_set_value
        next
endcode

; ### symbol_raw_code_address
subroutine symbol_raw_code_address      ; symbol -- raw-code-address/0
        _ check_symbol
        _symbol_raw_code_address
        ret
endsub

; ### symbol-code-address
code symbol_code_address, 'symbol-code-address' ; symbol -- code-address/f
        _ check_symbol
        _symbol_raw_code_address
        _?dup_if .1
        _tag_fixnum
        _else .1
        _f
        _then .1
        next
endcode

; ### symbol-set-code-address
code symbol_set_code_address, 'symbol-set-code-address' ; tagged-code-address symbol --
        _ check_symbol
        _verify_fixnum [rbp]
        _untag_fixnum qword [rbp]
        _symbol_set_raw_code_address
        next
endcode

; ### symbol-code-size
code symbol_code_size, 'symbol-code-size'       ; symbol -- code-size/f
        _ check_symbol
        _symbol_raw_code_size
        _?dup_if .1
        _tag_fixnum
        _else .1
        _f
        _then .1
        next
endcode

; ### symbol-set-code-size
code symbol_set_code_size, 'symbol-set-code-size'       ; tagged-code-size symbol --
        _ check_symbol
        _verify_fixnum [rbp]
        _untag_fixnum qword [rbp]
        _symbol_set_raw_code_size
        next
endcode

subroutine symbol_flags                 ; symbol -- flags
        _ check_symbol
        _symbol_flags
        ret
endsub

subroutine symbol_set_flags             ; flags symbol --
        _ check_symbol
        _symbol_set_flags
        ret
endsub

; ### symbol_set_flags_bit
subroutine symbol_set_flags_bit         ; bit symbol --
        _ check_symbol
        _dup
        _symbol_flags                   ; -- bit symbol flags
        _ rot                           ; -- symbol flags bit
        or      rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        _swap
        _symbol_set_flags
        ret
endsub

; ### symbol-location
code symbol_location, 'symbol-location' ; -- location
        _ check_symbol
        _dup
        _symbol_file
        _swap
        _symbol_line_number
        _tag_fixnum
        next
endcode

; ### call-symbol
code call_symbol, 'call-symbol'         ; symbol --
        _dup
        _ symbol_code_address
        _dup
        _tagged_if .1
        _nip

        ; REVIEW _untag_fixnum
        _check_fixnum

        mov     rax, rbx
        poprbx
        jmp     rax
        _else .1
        _drop
        _then .1                        ; -- symbol

        _dup
        _ symbol_def
        _dup
        _tagged_if .2
        _nip
        _ call_quotation
        _return
        _else .2
        _drop
        _then .2

        _ undefined

        next
endcode
