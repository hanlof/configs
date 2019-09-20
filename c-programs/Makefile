all: dumptags insdirs2 insdirs xseticon prefix

CFLAGS_WARNINGS=-Wmaybe-uninitialized -Wuninitialized -Wall
CFLAGS_LIBX11=-L/usr/X11R6/lib -lX11
CFLAGS=${CFLAGS_WARNINGS}

dumptags: dumptags.c readtags.h Makefile
	$(CC) -I. $(DEFS) $(CFLAGS) $(LDFLAGS) -o $@ dumptags.c

insdirs: insdirs.c
	$(CC) -O4 ${CFLAGS_WARNINGS} -g -o insdirs insdirs.c

insdirs2: insdirs2.c Makefile
	$(CC) -O4 ${CFLAGS_WARNINGS} -g -o insdirs2 insdirs2.c

prefix: prefix.c Makefile
	$(CC) -O4 ${CFLAGS_WARNINGS} -g -o prefix prefix.c

xseticon: xseticon.c Makefile
	$(CC) -O4 ${CFLAGS_WARNINGS} -g -o xseticon xseticon.c ${CFLAGS_LIBX11}
