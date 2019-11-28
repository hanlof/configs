/*
 * Copyright (C) 2012, Paul Evans <leonerd@leonerd.org.uk>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 */


#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdarg.h>
#include <string.h>
#include <fcntl.h>
#include <stdint.h>


#include <X11/Xlib.h>
#include <X11/Xatom.h>


/* We can't use the one defined in Xmd.h because that's an "unsigned int",
 * which comes out as a 32bit type always. We need this to be 64bit on 64bit
 * machines.
 */
typedef unsigned long int CARD32;

char program_name[] = "xseticon";

int verbose = 0;

void usage(int exitcode)
{
  printf("usage: %s -w <winid> -s <size> [-vh] < icon.bgra\n", program_name);
  exit(exitcode);
}

// FROM programs/xlsfonts/dsimple.c

void Fatal_Error(char *msg, ...)
{
  va_list args;
  fflush(stdout);
  fflush(stderr);
  fprintf(stderr, "%s: error: ", program_name);
  va_start(args, msg);
  vfprintf(stderr, msg, args);
  va_end(args);
  fprintf(stderr, "\n");
  exit(1);
}

// END FROM

void abortprog(char * fname)
{
  fprintf(stderr, "Aborted at function %s\n", fname);
  exit(1);
}

void load_icon(unsigned int* ndata, CARD32** data, int width, int height)
{
  if (verbose) {
    printf("Loading a %dx%d icon\n", width, height);
  }

  (*ndata) = (width * height) + 2;
  (*data) = malloc((*ndata) * sizeof(CARD32));

  //int fd = open("out.bgra", O_RDONLY);
  uint32_t * buf = malloc(height * width * 4);
  // XXX malloc error handling
  (void) read(STDIN_FILENO, buf, height*width * 4);
  // XXX read error handling

  (*data)[0] = width;
  (*data)[1] = height;
  int i = 2;
  while (i++ < *ndata) {
      (*data)[i] = buf[i];
  }
}

/* Note:
 *  dispite the fact this routine specifically loads 32bit data, it needs to
 *  load it into an unsigned long int array, not a guint32 array. The
 *  XChangeProperty() call wants to see a native size array when format == 32,
 *  not necessarily a 32bit one.
 */

int main(int argc, char* argv[])
{
  int width = 0, height = 0;
  char windowid_str[1024] = { '\0' };
  Window windowid = 0;
  int o;
  while ((o = getopt(argc, argv, "hvw:s:")) != -1) {
    switch (o) {
      case '?': { usage(1);    break; }
      case ':': { usage(1);    break; }
      case 'h': { usage(0);    break; }
      case 'v': { verbose = 1; break; }
      case 's': {
        if (sscanf(optarg, "%dx%d", &width, &height) != 2) {
          printf("Can't parse size argument '%s'. Expecting 'WIDTHxHEIGHT'\n", optarg);
          exit(1);
        }
        break;
      }
      case 'w': {
        strncpy(windowid_str, optarg, 1023);
        windowid_str[1023] = '\0';
        break;
      }
    }
  }

  if (windowid_str[0] == '\0') {
    // try to get $windowid from environemnt!
  } else {
    sscanf(windowid_str, "0x%lx", &windowid);
    if (!windowid) {
      sscanf(windowid_str, "%ld", &windowid);
    } if (!windowid) {
      Fatal_Error("Invalid window id format: %s.", windowid_str);
    }
  }

  Display* display = XOpenDisplay(NULL);

  if (!display)
    abortprog("XOpenDisplay");

  XSynchronize(display, 1);

  if (!windowid) {
    // XXX rah
    abortprog("supply window!\n");
  }

  Atom property = XInternAtom(display, "_NET_WM_ICON", 0);

  if (!property)
    abortprog("XInternAtom(property)");

  unsigned int nelements;
  CARD32* data;

  load_icon(&nelements, &data, width, height);

  int result = XChangeProperty(display, windowid, property, XA_CARDINAL, 32, PropModeReplace,
      (unsigned char*)data, nelements);

  if(!result)
    abortprog("XChangeProperty");

  result = XFlush(display);

  if(!result)
    abortprog("XFlush");

  XCloseDisplay(display);

  return 0;
}
