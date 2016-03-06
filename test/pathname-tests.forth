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

0 value s

test: test1
    "foo" path-get-extension 0= check
;

test1

test: test2
    "foo.bar" path-get-extension to s
    s string? check
    s transient? check
    s ".bar" string= check
;

test2

test: test3
    "foo.bar/zork" path-get-extension 0= check
;

test3

empty

?cr .( Reached end of pathname-tests.forth )
