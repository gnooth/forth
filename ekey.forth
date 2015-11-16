\ Copyright (C) 2015 Peter Graves <gnooth@gmail.com>

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

: test-key ( -- )
    begin
        key?
    until
    begin
        key?
    while
        key h.
    repeat ;

windows? [if]

windows-ui? [if]

: ekey ( -- x )
    key ;

$20027 constant k-right
$20025 constant k-left
$20026 constant k-up
$20028 constant k-down
$20024 constant k-home
$20023 constant k-end
$2002e constant k-delete
$20021 constant k-prior
$20022 constant k-next

\ REVIEW non-standard, should use K-CTRL-MASK
$60024 constant k-^home
$60023 constant k-^end

[else]

\ Windows console
: ekey ( -- x )                         \ FACILITY EXT
    key
    dup 0= if
        drop
        key $8000 or
        exit
    then
    dup $80 u< if                       \ normal character
        exit
    then
    dup $e0 = if
        drop
        key $8000 or
        exit
    then ;

$804d constant k-right
$804b constant k-left
$8048 constant k-up
$8050 constant k-down
$8047 constant k-home
$804f constant k-end
$8053 constant k-delete
$8049 constant k-prior
$8051 constant k-next

\ REVIEW non-standard, should use K-CTRL-MASK
$8077   constant k-^home
$8075   constant k-^end

[then]

[else]

\ Linux
: ekey ( -- x )                         \ FACILITY EXT
    key
    dup $1b = if
        begin
            key?
        while
            8 lshift
            key or
        repeat
    then ;

$1b5b43   constant k-right
$1b5b44   constant k-left
$1b5b41   constant k-up
$1b5b42   constant k-down
$1b5b48   constant k-home
$1b5b46   constant k-end
$1b5b337e constant k-delete
$1b5b357e constant k-prior
$1b5b367e constant k-next

\ REVIEW non-standard, should use K-CTRL-MASK
$1b5b313b3548   constant k-^home
$1b5b313b3546   constant k-^end

[then]

: ekey>char ( x -- x false | char true )
\ FACILITY EXT
    dup 128 u< ;

: ekey>fkey ( x -- x false | u true )
\ FACILITY EXT
    ekey>char 0= ;
