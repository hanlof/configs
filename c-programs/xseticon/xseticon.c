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
  printf("usage: %s [options] path/to/icon.png\n", program_name);
  printf("options:\n");
  printf("  -name <text>    : apply icon to the window of the name supplied\n");
  printf("  -id <windowid>  : apply icon to the window id supplied\n");
  printf("\n");
  printf("Sets the window icon to the specified .png image. The image is loaded from\n");
  printf("the file at runtime and sent to the X server; thereafter the file does not\n");
  printf("need to exist, and can be deleted/renamed/modified without the X server or\n");
  printf("window manager noticing.\n");
  printf("If no window selection option is specified, the window can be interactively\n");
  printf("selected using the cursor.\n");
  printf("\n");
  printf("Hints:\n");
  printf("  %s -id \"$WINDOWID\" path/to/icon.png\n", program_name);
  printf("Will set the icon for an xterm.\n");
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

Window Window_With_Name(Display* dpy, Window top, char* name)
{
  Window *children, dummy;
  unsigned int nchildren;
  int i;
  Window w = 0;
  char *window_name;

  if (XFetchName(dpy, top, &window_name) && !strcmp(window_name, name))
    return(top);

  if (!XQueryTree(dpy, top, &dummy, &dummy, &children, &nchildren))
    return(0);

  for (i=0; i<nchildren; i++) {
          w = Window_With_Name(dpy, children[i], name);
          if (w)
            break;
  }
  if (children) XFree ((char *)children);
  return(w);
}

Window Select_Window_Args(Display* dpy, int screen, int* rargc, char* argv[])
{
  int nargc = 1;
  int argc;
  char **nargv;
  Window w = 0;

#define ARGC (*rargc)
  nargv = argv+1; argc = ARGC;
#define OPTION argv[0]
#define NXTOPTP ++argv, --argc>0
#define NXTOPT if (++argv, --argc==0) usage(1)
#define COPYOPT nargv++[0]=OPTION, nargc++

  while (NXTOPTP) {
    if (!strcmp(OPTION, "-")) {
      COPYOPT;
      while (NXTOPTP)
        COPYOPT;
      break;
    }
    if (!strcmp(OPTION, "-name")) {
      NXTOPT;
      if (verbose)
        printf("Selecting window by name %s\n", OPTION);
      w = Window_With_Name(dpy, RootWindow(dpy, screen),
                           OPTION);
      if (!w)
        Fatal_Error("No window with name %s exists!",OPTION);
      continue;
    }
    if (!strcmp(OPTION, "-id")) {
      NXTOPT;
      if (verbose)
        printf("Selecting window by ID %s\n", OPTION);
      w=0;
      sscanf(OPTION, "0x%lx", &w);
      if (!w)
        sscanf(OPTION, "%ld", &w);
      if (!w)
        Fatal_Error("Invalid window id format: %s.", OPTION);
      continue;
    }
    COPYOPT;
  }
  ARGC = nargc;
  
  return(w);
}


// END FROM

void abortprog(char * fname)
{
  fprintf(stderr, "Aborted at function %s\n", fname);
  exit(1);
}

void load_icon(int* ndata, CARD32** data)
{


  int width, height;

  width = 16;
  height = 16;

  if (verbose)
    printf("Loaded a %dx%d icon\n", width, height);

  (*ndata) = (width * height) + 2;

  //(*data) = g_new0(CARD32, (*ndata));
  (*data) = malloc(1024 * 128);

  int i = 0;
  (*data)[i++] = width;
  (*data)[i++] = height;

  int x, y;

  for(y = 0; y < height; y++) {
    for(x = 0; x < width; x++) {
      // data is RGBA
      // We'll do some horrible data-munging here
      unsigned char * cols = (unsigned char *)&((*data)[i++]);

      cols[0] = x * 15;
      cols[1] = y * 15;
      cols[2] = (x + y) * 7;

      /* Alpha is more difficult */
      int alpha;
      
      // Scale it up to 0 to 255; remembering that 2*127 should be max
      if (alpha == 127)
        alpha = 255;
      else
        alpha *= 2;

      alpha = 255;
      
      cols[3] = alpha;
    }
  }
}

// convert /usr/share/icons/Humanity/apps/128/bash.svg -resize 64x64 -background none -gravity center -extent 64x64 ~/xterm.xpm
/* Note:
 *  dispite the fact this routine specifically loads 32bit data, it needs to
 *  load it into an unsigned long int array, not a guint32 array. The
 *  XChangeProperty() call wants to see a native size array when format == 32,
 *  not necessarily a 32bit one.
 */

int main(int argc, char* argv[])
{
  if (argc < 2 ||
      !strcmp(argv[1], "-h") ||
      !strcmp(argv[1], "--help"))
    usage(0);

  if (!argv[1])
    usage(1);

  int argindex = 1;
  if (!strcmp(argv[argindex], "-v")) {
    verbose = 1;
    argindex++;
  }

  Display* display = XOpenDisplay(NULL);

  if (!display)
    abortprog("XOpenDisplay");

  XSynchronize(display, 1);

  int screen = DefaultScreen(display);

  Window window = Select_Window_Args(display, screen, &(argc), argv);

  if (!window) {
    abortprog("supply window!\n");
  }


  Atom property = XInternAtom(display, "_NET_WM_ICON", 0);

  if (!property)
    abortprog("XInternAtom(property)");

  int nelements;
  CARD32* data;

  load_icon(&nelements, &data);

  int result = XChangeProperty(display, window, property, XA_CARDINAL, 32, PropModeReplace,
      (char*)data, nelements);

  if(!result)
    abortprog("XChangeProperty");

  result = XFlush(display);

  if(!result)
    abortprog("XFlush");

  XCloseDisplay(display);
}

