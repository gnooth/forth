\ Copyright (C) 2016 Peter Graves <gnooth@gmail.com>

\ This program is free software: you can redistribute it and/or modify
\ it under the terms of the GNU General Public License as published by
\ the Free Software Foundation, either version 3 of the License, or
\ (at your option) any later version.

\ This program is distributed in the hope that it will be useful,
\ but WITHOUT ANY WARRANTY; without even the implied warranty of
\ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
\ GNU General Public License for more details.

\ You should have received a copy of the GNU General Public License
\ along with this program.  If not, see <http://www.gnu.org/licenses/>.

feline!

require-system-file test-framework

\ data stack
test: test1 ( -- )
    s" testing1" >string
    dup string? check
    gc
    dup string? check
    drop
;

test1

\ locals stack
test: test2 ( -- )
    s" testing2" >string local s1
    s1 object? check
    s1 string? check
    gc
    s1 object? check
    s1 string? check
;

test2

\ return stack
test: test3 ( -- )
    s" testing3" >string >r
    r@ string? check
    gc
    r> string? check
;

test3

empty

?cr .( Reached end of gc-tests.forth )
