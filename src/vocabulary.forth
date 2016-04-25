\ Copyright (C) 2012-2016 Peter Graves <gnooth@gmail.com>

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

language: forth

context: forth feline ;
current: forth

: vocabulary
   wordlist
   create dup ,
   latest over wid>name !
   add-vocab
   does>
      @ 0 context-vector vector-set-nth ;

current: root

import forth
import forth-wordlist
import set-order
import order

import feline

import language:
import context:
import current:

current: forth
