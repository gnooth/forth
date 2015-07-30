\ Copyright (C) 2012-2015 Peter Graves <gnooth@gmail.com>

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

$08 constant #bs
$7f constant #del
$0d constant #cr
$0a constant #lf
$1b constant #esc

0 value bufstart
0 value buflen
0 value number-chars-accepted
0 value done?

: do-bs  ( -- )
   number-chars-accepted if
      -1 +to number-chars-accepted
      #bs emit space #bs emit
   then ;

: clear-line  ( -- )
   number-chars-accepted dup backspaces dup spaces backspaces
   0 to number-chars-accepted ;

: redisplay-line  ( -- )
   bufstart number-chars-accepted type ;

: do-escape  ( -- )
   clear-line ;

\ The number of slots allocated for the history list.
100 constant history-size

\ The current location of the interactive history pointer.
-1 value history-offset

\ The number of strings currently stored in the history list.
0 value history-length

\ An array of history entries.
create history-array  history-size cells allot  history-array history-size cells erase

: current-history  ( -- addr )
   history-array 0= if 0 exit then      \ shouldn't happen
   history-offset 0 history-length within if
      history-array history-offset cells + @
   else
      0
   then ;

\ Returns the address of the first (i.e. zeroth) cell in the history array.
: first-history  ( -- addr )
   history-array 0= if 0 exit then      \ shouldn't happen
   history-array ;

\ Returns the address of the last cell in the history array.
: last-history  ( -- addr )
   history-array 0= if 0 exit then      \ shouldn't happen
   history-array history-size 1- cells + ;

: history  ( -- )
   history-array 0= if exit then        \ shouldn't happen
   history-length 0 ?do
      history-array i cells + @
      cr count type
   loop ;

: save-history  ( -- )
   history-array 0= if exit then        \ shouldn't happen
   s" .history" w/o create-file 0= if   \ -- fileid
      history-length 0 ?do
         dup                            \ -- fileid fileid
         history-array i cells + @
         count                          \ -- fileid fileid c-addr u
         rot                            \ -- fileid c-addr u fileid
         write-line                     \ -- fileid ior
         drop                           \ -- fileid
      loop
      close-file drop
   then ;

create restore-array  10 cells allot

create restore-buffer  258 allot

: read-history-line  ( fileid -- c-addr u2 )
   restore-buffer 256 rot read-line     \ -- u2 flag ior
   0= if
      ( flag ) if
         restore-buffer swap
      else
         drop 0 0
      then
   else
      2drop 0 0
   then ;

: store-history-line  ( c-addr1 u -- c-addr2 )
   ?dup if
      \ non-zero count
      dup 1+ allocate 0= if
        dup >r
        place
        r>                              \ -- c-addr2
      then
   else
      drop
      0
   then ;

: allocate-history-entry  ( c-addr u -- alloc-addr )
   dup 1+ allocate 0= if                \ -- c-addr u alloc-addr
      dup >r
      place
      r>
   else
      -1 abort" allocation failed"
   then ;

: restore-history  ( -- )
   s" .history" r/o open-file 0= if
      history-array history-size cells erase
      0 to history-length
      0 to history-offset
      >r
      begin
         r@ read-history-line           \ -- c-addr u
         ?dup if
            allocate-history-entry      \ -- alloc-addr
            history-array history-offset cells + !
            1 +to history-offset
            1 +to history-length
         else
            drop
            r> close-file
            drop                        \ REVIEW
            -1 to history-offset
            exit
         then
      again
   then ;

: clear-history  ( -- )
   history-array history-size cells erase
   0 to history-length
   -1 to history-offset ;

: add-history  ( -- )
   number-chars-accepted if
      history-length history-size < if
         number-chars-accepted 1+ allocate 0= if
            >r
            bufstart number-chars-accepted r@ place
            r> history-array history-length cells + !
            1 +to history-length
            -1 to history-offset
         then
      then
   then ;

: do-previous
   history-length 0= if exit then
   history-offset 0< if
      history-length to history-offset  \ most recent entry is at highest offset
   then
   history-offset 0> if
      -1 +to history-offset
   then
   history-offset history-length < if
      current-history
      ?dup if
         clear-line
         count dup to number-chars-accepted
         bufstart swap cmove
         redisplay-line
      then
   then ;

: do-next  ( -- )
   history-length 0= if exit then
   history-offset history-length 1- < if
      1 +to history-offset
      current-history
      ?dup if
         clear-line
         count dup to number-chars-accepted
         bufstart swap cmove
         redisplay-line
      then
   else
      clear-line
   then ;

: do-enter  ( -- )
   add-history
   save-history
   space
   true to done? ;

: do-command  ( n -- )
   case
      #lf of \ Linux
         do-enter
      endof
      #cr of \ Windows
         do-enter
      endof
      #bs of \ Windows
         do-bs
      endof
      #del of \ Linux
         do-bs
      endof
      #esc of
         do-escape
         -1 to history-offset
      endof
      $10 of                            \ control p
        do-previous
      endof
      $0e of                            \ control n
        do-next
      endof
   endcase ;

: new-accept  ( c-addr +n1 -- +n2 )
   to buflen
   to bufstart
   false to done?
   0 to number-chars-accepted
   begin
      number-chars-accepted buflen <
      done? 0= and
   while
      key
      dup bl $7f within if
         dup emit
         bufstart number-chars-accepted + c!
         1 +to number-chars-accepted
         -1 to history-offset
      else
         do-command
      then
   repeat
   number-chars-accepted ;

line-input? 0= [if]
   restore-history
   ' new-accept is accept
[then]
