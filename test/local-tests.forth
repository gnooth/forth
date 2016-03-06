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

42 constant k1
17 constant k2
57 constant k3

: inner-no-throw ( x y -- )
    local y
    local x
    x k1 k2 + = check
    y k1 k2 - = check
;

: inner-throw ( x y -- )
    local y
    local x
    x k1 k2 + = check
    y k1 k2 - = check
    k3 throw
;

: outer ( x y inner -- )
    local inner
    local y
    local x
    x y +
    x y -
    inner catch
    ?dup if
        k3 = check
        2drop
    then
    depth 0= check
    x k1 = check
    y k2 = check
    x y +
;

: test1 ( -- )
    cr "test1" .string
    k1 k2 ['] inner-no-throw outer k1 k2 + = check
;

test1

: test2 ( -- )
    cr "test2" .string
    k1 k2 ['] inner-throw outer k1 k2 + = check
;

test2

empty

?cr .( Reached end of local-tests.forth )
