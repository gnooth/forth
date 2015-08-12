// Copyright (C) 2012-2015 Peter Graves <gnooth@gmail.com>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#include <stdio.h>
#include <stdlib.h>
#ifdef WIN64
#include <windows.h>
#else
#include <termios.h>
#include <sys/ioctl.h>
#endif

#include "forth.h"

extern Cell echo_data;
extern Cell line_input_data;

#ifdef WIN64
static HANDLE console_input_handle = INVALID_HANDLE_VALUE;
#else
static int tty;
static struct termios otio;
static int terminal_prepped = 0;
#endif

void prep_terminal ()
{
#ifdef WIN64
  DWORD mode;
  console_input_handle = GetStdHandle (STD_INPUT_HANDLE);
  if (GetConsoleMode (console_input_handle, &mode))
    {
      mode = (mode & ~ENABLE_ECHO_INPUT & ~ENABLE_LINE_INPUT & ~ENABLE_PROCESSED_INPUT);
      SetConsoleMode(console_input_handle, mode);
      line_input_data = 0;
    }
  else
    {
      console_input_handle = INVALID_HANDLE_VALUE;
      line_input_data = -1;
    }
#else
  // Linux.
  tty = fileno (stdin);
  struct termios tio;
  char *term;
  if (!isatty (tty))
    return;
  term = getenv("TERM");
  if (term == NULL || !strcmp(term, "dumb"))
    return;
  tcgetattr (tty, &tio);
  otio = tio;
  tio.c_lflag &= ~(ICANON | ECHO);
  tcsetattr (tty, TCSADRAIN, &tio);
  setvbuf(stdin, NULL, _IONBF, 0);
  line_input_data = 0;
  terminal_prepped = 1;
#endif
}

void deprep_terminal ()
{
#ifndef WIN64
  if (terminal_prepped)
    tcsetattr (tty, TCSANOW, &otio);
#endif
}

Cell os_key_avail()
{
#ifdef WIN64
  return _kbhit() ? (Cell)-1 : 0;
#else
  // Linux
  int chars_avail = 0;
  int tty = fileno (stdin);
  if (ioctl (tty, FIONREAD, &chars_avail) == 0)
    return chars_avail ? (Cell)-1 : 0;
  return 0;
#endif
}

int os_key()
{
#ifdef WIN64
  if (console_input_handle != INVALID_HANDLE_VALUE)
    return _getch();
  else
    return fgetc(stdin);
#else
  return fgetc(stdin);
#endif
}
