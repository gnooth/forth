; Copyright (C) 2019 Peter Graves <gnooth@gmail.com>

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

asm_global gtkui_raw_sp0_, 0

; ### gtkui-initialize
code gtkui_initialize, 'gtkui-initialize'

        _ current_thread_raw_sp0
        mov     [gtkui_raw_sp0_], rbx
        _drop

        extern  gtkui__initialize
        xcall   gtkui__initialize

        next
endcode

; ### gtkui-char-width
code gtkui_char_width, 'gtkui-char-width' ; void -> fixnum
        extern  gtkui__char_width
        xcall   gtkui__char_width
        pushrbx
        mov     rbx, rax
        _tag_fixnum
        next
endcode

; ### gtkui-char-height
code gtkui_char_height, 'gtkui-char-height' ; void -> fixnum
        extern  gtkui__char_height
        xcall   gtkui__char_height
        pushrbx
        mov     rbx, rax
        _tag_fixnum
        next
endcode

; ### gtkui-textview-text-out
code gtkui_textview_text_out, 'gtkui-textview-text-out' ; x y string -> void
        _ string_from
        _drop
        mov     arg2_register, rbx
        poprbx
        _ check_fixnum
        mov     arg1_register, rbx
        poprbx
        _ check_fixnum
        mov     arg0_register, rbx
        poprbx

        extern  gtkui__textview_text_out
        xcall   gtkui__textview_text_out

        next
endcode

; ### gtkui_textview_paint
subroutine gtkui_textview_paint         ; void -> void
; 0-arg callback

        ; enter callback
        push    rbx
        push    rbp
        mov     rbp, [gtkui_raw_sp0_]

        _quote "repaint"
        _quote "editor"
        _ ?lookup_symbol
        _ call_symbol

        ; leave callback
        pop     rbp
        pop     rbx

        ret
endsub
