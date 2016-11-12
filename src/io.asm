; Copyright (C) 2012-2016 Peter Graves <gnooth@gmail.com>

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

; ### errno
value os_errno, 'errno', 0

; ### key
code key, 'key'
        xcall   os_key
        pushd   rax
        next
endcode

; ### key?
code key?, 'key?'
        xcall   os_key_avail
        pushd   rax
        next
endcode

; ### #rows
value nrows, '#rows', 0

; ### #cols
value ncols, '#cols', 0

; ### #out
value nout, '#out', 0

; For Windows, FORTH-STDOUT is initialized in prep_terminal().
; The value here is correct for Linux.

; ### stdout
value forth_stdout, 'forth-stdout', 1

; For Windows, FORTH-OUTPUT-FILE is initialized by calling STANDARD-OUTPUT in COLD.

; ### forth-output-file
value forth_output_file, 'forth-output-file', 1

; ### forth-standard-output
code forth_standard_output, 'forth-standard-output'
%ifndef WINDOWS_UI
        _ forth_stdout
        _to forth_output_file
%endif
        next
endcode

; ### emit-file
code emit_file, 'emit-file'             ; char fileid --
%ifdef WIN64
        popd    rdx
        popd    rcx
%else
        popd    rsi
        popd    rdi
%endif
        xcall   os_emit_file
        next
endcode

; ### file-status
code file_status, 'file-status'         ; c-addr u -- x ior
; FILE EXT
; "If the file exists, ior is zero; otherwise ior is the implementation-defined I/O result code."
        _ as_c_string
%ifdef WIN64
        popd    rcx
%else
        popd    rdi
%endif
        xcall   os_file_status
        or      rax, rax
        jnz      .1
        pushd   rax
        pushd   rax
        next
.1:
        _zero
        _lit -1
        next
endcode

; ### path-is-directory?
code path_is_directory?, 'path-is-directory?' ; string -- flag
        _ verify_string
        _ string_data
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_file_is_directory
        test    rax, rax
        jz      .1
        mov     rax, -1
.1:
        mov     rbx, rax
        next
endcode

; ### path-file-exists?
code path_file_exists?, 'path-file-exists?' ; string -- ?
        _ string_from
        _ file_status
        _nip
        _zeq
        _tag_boolean
        next
endcode

; ### reposition-file
code reposition_file, 'reposition-file' ; ud fileid -- ior
; We ignore the upper 64 bits of the 128-bit offset.
%ifdef WIN64
        mov     rcx, rbx                        ; fileid in RCX
        mov     rdx, [rbp + BYTES_PER_CELL]     ; 64-bit offset in RDX
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%else
        mov     rdi, rbx                        ; fileid
        mov     rsi, [rbp + BYTES_PER_CELL]     ; 64-bit offset
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endif
        xcall   os_reposition_file
        test    rax, rax
        js      .1
        xor     rbx, rbx                ; success
        next
.1:
        mov     rbx, -1                 ; error
        next
endcode

; ### resize-file
code resize_file, 'resize-file'         ; ud fileid -- ior
; We ignore the upper 64 bits of the 128-bit offset.
%ifdef WIN64
        mov     rcx, rbx                        ; fileid in RCX
        mov     rdx, [rbp + BYTES_PER_CELL]     ; 64-bit offset in RDX
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%else
        mov     rdi, rbx                        ; fileid
        mov     rsi, [rbp + BYTES_PER_CELL]     ; 64-bit offset
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endif
        xcall   os_resize_file
        or      rax, rax
        js      .1
        xor     rbx, rbx                ; success
        next
.1:
        mov     rbx, -1                 ; error
        next
endcode

; ### delete-file
code delete_file, 'delete-file'         ; c-addr u -- ior
        _ as_c_string
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_delete_file
        mov     ebx, eax
        next
endcode

; ### rename-file
code rename_file, 'rename-file'         ; c-addr1 u1 c-addr2 u2 -- ior
        ; -- old new
        _ as_c_string                   ; new name
        _ rrot
        _ as_c_string                   ; old name
        ; -- new old
%ifdef WIN64
        popd    rcx                     ; old name
        popd    rdx                     ; new name
%else
        popd    rdi                     ; old name
        popd    rsi                     ; new name
%endif
        xcall   os_rename_file
        pushrbx
        mov     rbx, rax
        next
endcode

; ### flush-file
code flush_file, 'flush-file'           ; fileid -- ior
; FILE EXT
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_flush_file
        mov     rbx, rax
        next
endcode

; ### ms
code ms, 'ms'
; FACILITY EXT
%ifdef WIN64
        popd    rcx
%else
        popd    rdi
%endif
        xcall   os_ms
        next
endcode

; ### system
code system_, 'system'                  ; c-addr u --
        _ as_c_string
%ifdef WIN64
        popd    rcx
%else
        popd    rdi
%endif
        xcall   os_system
        next
endcode

; ### get-environment-variable
code get_environment_variable, 'get-environment-variable' ; name -- value
        _ string_data
%ifdef WIN64
        popd    rcx
%else
        popd    rdi
%endif
        xcall   os_getenv
        pushd   rbx
        mov     rbx, rax
        pushd   rbx
        test    rbx, rbx
        jz      .1
        _ zstrlen
        jmp     .2
.1:
        xor     ebx, ebx
.2:
        _ copy_to_string
        next
endcode

; ### get-current-directory
code get_current_directory, 'get-current-directory' ; c-addr u -- c-addr
%ifdef WIN64
        popd    rdx
        popd    rcx
%else
        popd    rsi
        popd    rdi
%endif
        xcall   os_getcwd
        pushd   rax
        next
endcode

; ### current-directory
code current_directory, 'current-directory' ; -- string
        _lit 1024
        _ feline_allocate_untagged
        _lit 1024
        _ get_current_directory
        _dup
        _ zcount
        _ copy_to_string
        _swap
        _ feline_free
        next
endcode

; ### set-current-directory
code set_current_directory, 'set-current-directory' ; string -- flag
; Return true on success, 0 on failure.
        _ verify_string
        _ string_data
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_chdir
        mov     rbx, rax
        next
endcode

; ### canonical-path
code canonical_path, 'canonical-path'   ; string1 -- string2
        _ string_data                   ; -- zaddr1
%ifdef WIN64
        popd    rcx
%else
        popd    rdi
%endif
        xcall   os_realpath
        pushd   rax                     ; -- zaddr2
        _dup
        _ zcount
        _ copy_to_string                ; -- string2
        _ swap
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_free
        poprbx
        next
endcode

; ### errno-to-string
code errno_to_string, 'errno-to-string' ; n -- string
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_strerror
        mov     rbx, rax
        _ zcount
        _ copy_to_string
        next
endcode
