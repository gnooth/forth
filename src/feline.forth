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

LANGUAGE: forth

CONTEXT: forth feline ;
CURRENT: feline

import LANGUAGE:
import CONTEXT:
import CURRENT:

import feline-mode
import forth-mode

import bye

import vocabulary

import only
import also
import definitions

import [defined]
import [undefined]
import [if]
import [then]

import (
import \

import :
import ;

import include
import require
import include-system-file
import empty

import decimal

import constant
import local

import swap
import dup
import >r
import r>

\ REVIEW
import execute
import ?cr
import .(

: throw ( n -- ) untag-fixnum throw ;

: depth ( -- n ) depth tag-fixnum ;

: do ( n1 n2 -- )
    postpone untag-fixnum
    postpone swap
    postpone untag-fixnum
    postpone swap
    postpone do
; immediate

: ?do ( n1 n2 -- )
    postpone untag-fixnum
    postpone swap
    postpone untag-fixnum
    postpone swap
    postpone ?do
; immediate

: i ( -- index )
    postpone i
    postpone tag-fixnum
; immediate

: file-contents ( path -- string )
    string> r/o open-file throw local fileid
    fileid file-size throw drop local filesize
    filesize -allocate local buffer
    buffer filesize fileid read-file throw local bufsize
    fileid close-file throw
    buffer bufsize >string
    buffer -free
;
