#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>

#define ALLOCSIZE 0x2800000
//#define READSIZE 0x8000

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

int main(int argc, char * argv[]) {
	int READSIZE = getpagesize();
	char * read_ptr = malloc(ALLOCSIZE);
	*read_ptr++ = '\n';
	char * alloc_ptr = read_ptr;
	// XXX do we need readsize plus two pathmax as margin? do proper calculation
	char * watermark = alloc_ptr + ALLOCSIZE - READSIZE - PATH_MAX - PATH_MAX;
	char * last_slash = read_ptr;
	char * prev_last_slash = read_ptr;
	char * start_of_line = read_ptr;
	char * ptr = read_ptr;
	char * write_ptr = read_ptr;
	int i;
	char tmp;
	while (1) {
		if (ptr == read_ptr) {
			if (read_ptr >= watermark) {

			}
			i = read(STDIN_FILENO, read_ptr, READSIZE);
			// XXX take care of negative return value
			if (0 == i) {
				break;
			}
			read_ptr += i;
		}

		if (*ptr == '\n') {
			if (compare_path(prev_last_slash, last_slash)) {
				// XXX can last_slash + 1 be outside the buffer??
				// >>> it depends of how we handle end-of-buffer
				tmp = last_slash[1];
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
