// Copyright (C) 2015-2017 Peter Graves <gnooth@gmail.com>

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

#include <string.h>             // memset

#include "feline.h"

static cell saved_backtrace_array[16];
static cell saved_backtrace_size;

cell * c_get_saved_backtrace_array()
{
  return saved_backtrace_array;
}

cell c_get_saved_backtrace_size()
{
  return saved_backtrace_size;
}

void c_save_backtrace(cell rip, cell rsp)
{
  memset(saved_backtrace_array, 0, sizeof(saved_backtrace_array));
  saved_backtrace_array[0] = rip;
  int i = 1;
  extern cell *rp0_;
  for (cell * p = (cell *)rsp; p < rp0_; ++p)
    {
      saved_backtrace_array[i++] = *p;
      if (i >= sizeof(saved_backtrace_array) / sizeof(cell))
        break;
    }
  saved_backtrace_size = i;
}
