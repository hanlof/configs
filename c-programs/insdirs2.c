#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>
#include <ctype.h>

// do sanity check on input params
// - alloc size > PATH_MAX
// - alloc size > 4 * read_size or something like that
// experiment: compare buffer cycling to just reallocing
// experiment: compare this approach (allocate several megabytes) with a really small buffer and constantly wrapping pointers
// interesting: frequent read():ing and buffer cycling does not seem to impact performance much when readsize >= pagesize
//   maybe we can get away with using really little memory
//   also why do we read at readsize bytes before the end of buffer? it means we never use the last readsize bytes in the buffer
//   we do add a newline character at one byte ahead of ptr so we need to be careful to always make sure ptr stays one byte away from the end of the buffer or change the implementation of outputting newline? maybe its already safe

int compare_path(char * p, char * c)
{
	while (*p == *c) {
		if (*c == '\n') {
			return 0;
		}
		p--;
		c--;
	}
	return 1;
}

struct params {
	int allocsize;
	int readsize;
};

int get_multiplier(char * t, char * optarg) {
	if ('\0' != t[1]) {
		printf("bad number: %s\n", optarg);
		exit(1); // TODO: print help
	} else {
		switch (tolower(t[0])) {
			case 'p': { // pagesize
				return getpagesize();
				break;
			}
			case 'k': { // kilobyte
				return 1024;
				break;
			}
			case 'm': {
				return 1024 * 1024;
				break;
			}
			default: {
				printf("bad suffix: %s\n", optarg);
				exit(1); // TODO: print help
			}
		}
	}
}

void parse_args(int argc, char * argv[], struct params * par)
{
	int o;
	int i;
	char * t;
	while (-1 != (o = getopt(argc, argv, "r:a:"))) {
		int * whatopt = NULL;
		if ('a' == o) {
			whatopt = &par->allocsize;
		} else if ('r' == o) {
			whatopt = &par->readsize;
		} else {
			// We dont need to print the bad option. getopt() does it automatically
			exit(1); // TODO: print help
		}
		if (NULL != whatopt) {
			i = strtol(optarg, &t, 0);
			if ('\0' != *t) {
				i *= get_multiplier(t, optarg);
			}
	//		printf("optarg: %s / %i\n", optarg, i);
			*whatopt = i;
		}
	}
}

void check_args(struct params * par)
{
	// readsize and allocsize are only used to measure performance and tune those values.
	// they will not be very useful in practice.
	// we will stay on the safe side with the checking. dont make it too complicated
	// alloc size must be at least 4 PATH_MAX plus read size
	// why? we copy 2 * PATH_MAX using memcpy and memcpy cant have overlapping regions
	if (par->allocsize < 4 * PATH_MAX + par->readsize) {
		printf("allocsize must be four times PATH_MAX(%d) plus readsize bytes. (%d bytes in total)\n", PATH_MAX, 4 * PATH_MAX + par->readsize);
		printf("readsize:%d allocsize:%d\n", par->readsize, par->allocsize);
		exit(1);
	}
}

#define MAX(a, b) ( (a > b) ? (a) : (b) )
int main(int argc, char * argv[])
{
	struct params params = {
		.readsize = getpagesize(),
		.allocsize = 8 * MAX(PATH_MAX, getpagesize()),
	};
	parse_args(argc, argv, &params);
	check_args(&params);

	char * alloc_ptr = malloc(params.allocsize);
	char * cycle_marker = alloc_ptr + params.allocsize - params.readsize; // marks where to wrap around (cycle) the buffer
	char * read_ptr = alloc_ptr; // marks where next read should happen (we have not read data past this point)
	*read_ptr++ = '\n'; // put EOL marker at start of buffer to simplify compare_path() implementation
	char * write_ptr = read_ptr; // marks what we have written to stdout so far/what we should write next
	char * start_of_line = read_ptr; // marks the start of last line of input
	char * last_slash = read_ptr;	 // marks the last '/' found so far
	char * prev_last_slash = read_ptr; // marks the last slash in previous line
	int tmp; // temp integer for syscall return values and other stuff
	char c; // temp storage for when we temporarily insert '\n' into buffer and need to save original character
	char * ptr = read_ptr; // current position in the buffer

	while (1) {
		if (ptr == read_ptr) {
			if (read_ptr >= cycle_marker) {
				// first output to stdout so that write_ptr is not too far behind
				tmp = write(STDOUT_FILENO, write_ptr, start_of_line - write_ptr);
				write_ptr = start_of_line;
				// copy stuff to beginning of buffer. why 2 * PATH_MAX?
				// because last_slash may be PATH_MAX behind ptr
				// and prev_last_slash may be PATH_MAX behind that
				memcpy(alloc_ptr, read_ptr - 2 * PATH_MAX, 2 * PATH_MAX);
				// fixup all the pointers
				read_ptr = alloc_ptr + 2 * PATH_MAX;
				tmp = ptr - read_ptr;
				write_ptr -= tmp;
				start_of_line -= tmp;
				last_slash -= tmp;
				prev_last_slash -= tmp;
				ptr -= tmp;
				printf("read_ptr:%p ptr:%p\n", read_ptr, ptr);
			}
			tmp = read(STDIN_FILENO, read_ptr, params.readsize);
			// XXX take care of negative return value
			if (0 == tmp) {
				break;
			}
			read_ptr += tmp;
		}
		if (*ptr == '\n') {
			if (compare_path(prev_last_slash, last_slash)) {
				c = last_slash[1]; // last_slash[1] is always inside the allocated space because we cycle way before the end
				last_slash[1] = '\n';
				tmp = write(STDOUT_FILENO, write_ptr, (int)(last_slash - write_ptr + 2));
				last_slash[1] = c;
				// FIXME: handle write() returning less than wanted number of bytes
				write_ptr = start_of_line;
			}
			prev_last_slash = last_slash;
			start_of_line = ptr + 1;
		} else if (*ptr == '/') {
			last_slash = ptr;
		}
		ptr++;
	}
	tmp = write(STDOUT_FILENO, write_ptr, (int)(ptr - write_ptr));
	return 0;
}
