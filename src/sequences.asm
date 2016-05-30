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

; ### shorter?
code shorter?, 'shorter?'               ; seq1 seq2 -- ?
; Factor
        _lit length_xt
        _ bi_at
        _ fixnum_lt
        next
endcode

; ### min-length
code min_length, 'min-length'           ; seq1 seq2 -- n
        _lit length_xt
        _ bi_at
        _ min
        next
endcode

; ### 2nth-unsafe
code two_nth_unsafe, '2nth-unsafe'      ; n seq1 seq2 -- elt1 elt2
        _tor                            ; -- n seq1     r: -- seq2
        _dupd                           ; -- n n seq1   r: -- seq2
        _ nth                           ; -- n elt1     r: -- seq2
        _swap                           ; -- elt1 n     r: -- seq2
        _rfrom                          ; -- elt1 n seq2
        _ nth                           ; -- elt2 elt2
        next
endcode
