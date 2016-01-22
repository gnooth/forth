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

include-system-file vocabulary.forth
include-system-file bracket-if.forth
include-system-file backtrace.forth
include-system-file locals.forth
include-system-file escaped-strings.forth
include-system-file defer.forth
include-system-file case.forth
include-system-file dump.forth
include-system-file view.forth
include-system-file ekey.forth
include-system-file switch.forth
include-system-file accept.forth
include-system-file search.forth
include-system-file words.forth
include-system-file args.forth
include-system-file tools.forth
include-system-file empty.forth
include-system-file double.forth
include-system-file environment.forth
include-system-file process-init-file.forth

only forth definitions

: see ( "<spaces>name" -- )
    feline-home $" see.forth" path-append-filename count included
    -4 >in +! ;

: edit ( "<spaces>name" -- )
    warning @ >r
    warning off
    feline-home $" editor.forth" path-append-filename count included
    r> warning !
    -5 >in +! ;

empty!
