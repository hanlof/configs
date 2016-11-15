all: dumptags

dumptags: dumptags.c readtags.h
	$(CC) -I. $(DEFS) $(CFLAGS) $(LDFLAGS) -o $@ dumptags.c

insdirs: insdirs.c
	$(CC) -g -o insdirs insdirs.c

insdirs2: insdirs2.c Makefile
	$(CC) -O4 -Wmaybe-uninitialized -Wuninitialized -Wall -g -o insdirs2 insdirs2.c
