#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>

// lets add: configurable alloc size and read size (to simplify performance investigation)
//           given that, we need should have sanity check on allocsize versus readsize
//           so we dont need to cycle the buffer too often
// experiment: compare buffer cycling to just reallocing
// experiment: compare this approach (allocate several megabytes) with a really small buffer and constantly wrapping pointers
// just for fun: investigate malloc time for big and small buffers
// answer: seems to be pretty constant time regardless of buffer size!

#define ALLOCSIZE 0x800000

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
			printf("wtf %i\n", o);
			exit(1);
		}
		if (NULL != whatopt) {
			i = strtol(optarg, &t, 0);
			printf("optarg: %s / %i\n", optarg, i);
			printf("t: %s\n", t);
			printf("whatopt = %08x\n", (void *)whatopt - (void *)par);
		}
	}
}

int main(int argc, char * argv[]) {
	struct params params = {
		.readsize = getpagesize(),
		.allocsize = 0x800000,
	};
	parse_args(argc, argv, &params);

	int readsize = 2 * getpagesize();
	char * alloc_ptr = malloc(ALLOCSIZE);
	char * read_ptr = alloc_ptr; // marks where next read should happen (we have not read data past this point)
	char * write_ptr = read_ptr; // marks what we have written to stdout so far/what we should write next
	char * start_of_line = read_ptr; // marks the start of last line of input
	char * last_slash = read_ptr;    // marks the last '/' found so far
	char * prev_last_slash = read_ptr; // marks the last slash in previous line
	char * ptr = read_ptr; // current position in the buffer
	char * cycle_marker = alloc_ptr + ALLOCSIZE - readsize; // marks where to wrap around (cycle) the buffer
	int i; // temp integer for syscall return values
	char tmp; // temp storage for when we temporarily insert '\n' into buffer and need to save original character

	*read_ptr++ = '\n'; // put EOL marker at start of buffer to simplify compare_path() implementation
	while (1) {
		if (ptr == read_ptr) {
			if (read_ptr >= cycle_marker) {
				// first output to stdout so that write_ptr is not too far behind
				// then copy stuff to beginning of buffer and update pointers
				//  ! prev_last_slash does need to be copied. this means pathmax times two need to be copied

				fprintf(stderr, "%x %x\n", ptr, alloc_ptr + ALLOCSIZE);
			}
			i = read(STDIN_FILENO, read_ptr, readsize);
			// XXX take care of negative return value
			if (0 == i) {
				break;
			}
			read_ptr += i;
		}

		if (*ptr == '\n') {
			if (compare_path(prev_last_slash, last_slash)) {
				tmp = last_slash[1]; // last_slash[1] is always inside the allocated space because we cycle read_size before the end
				last_slash[1] = '\n';
				i = write(STDOUT_FILENO, write_ptr, (int)(last_slash - write_ptr + 2));
				last_slash[1] = tmp;
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

	i = write(STDOUT_FILENO, write_ptr, (int)(ptr - write_ptr));

	return 0;
}
