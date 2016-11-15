#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define ALLOCSIZE 0x800000
#define READSIZE 0x0e

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
	char * read_ptr = malloc(ALLOCSIZE);

	*read_ptr++ = '\n';
	char * last_slash = read_ptr;
	char * prev_last_slash = read_ptr;
	char * sol = read_ptr;

	char * ptr = read_ptr;
	char * write_ptr = read_ptr;
	int i;
	while (1) {
		if (ptr == read_ptr) {
			i = read(STDIN_FILENO, read_ptr, READSIZE);
			// XXX take care of negative return value
			if (0 == i) {
				break;
			}
			read_ptr += i;
		}

		if (*ptr == '\n') {
			if (compare_path(prev_last_slash, last_slash)) {
				i = write(STDOUT_FILENO, write_ptr, (int)(sol - write_ptr));
				char tmp = last_slash[1];
				last_slash[1] = '\n';
				write(STDOUT_FILENO, sol, last_slash - sol + 2);
				last_slash[1] = tmp;
				//write(STDOUT_FILENO, "\n", 1);
				// FIXME: handle write() returning less than wanted number of bytes
				write_ptr = sol;
			}
			prev_last_slash = last_slash;
			sol = ptr + 1;
		} else if (*ptr == '/') {
			last_slash = ptr;
		}

		ptr++;
	}

	i = write(STDOUT_FILENO, write_ptr, (int)(ptr - write_ptr));

	return 0;
}
