#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define ALLOCSIZE 0x800000
#define READSIZE 0x0e

char * compare_path(char * p, char * c)
{
  char * tmp = c;

  while (*p == *c) {
    if (*c == '\n') {
      return 0;
    }
    p--;
    c--;

  }
  return tmp;
}

int main(int argc, char * argv[]) {
	char * read_ptr = malloc(ALLOCSIZE);

	*read_ptr++ = '\n';
	char * last_slash = read_ptr;
	char * prev_last_slash = read_ptr;
	char * eol = read_ptr;
	char * sol = read_ptr;

	char * ptr = read_ptr;
	char * write_ptr = read_ptr;
	int i;
	while (1) {
		if (ptr == read_ptr) {
			i = read(0, read_ptr, READSIZE);
			if (0 == i) {
				break;
			}
			read_ptr += i;
		}

		if (*ptr == '\n') {
			if (compare_path(prev_last_slash, last_slash)) {
				i = write(1, write_ptr, (int)(eol - write_ptr + 1));
				write(1, sol, last_slash - sol + 1);
				write(1, "\n", 1);
				// FIXME: handle write() returning less than wanted number of bytes
				write_ptr = eol + 1;
			}
			prev_last_slash = last_slash;
			sol = ptr + 1;
			eol = ptr;
		} else if (*ptr == '/') {
			last_slash = ptr;
		}

		ptr++;
	}

	i = write(1, write_ptr, (int)(ptr - write_ptr));

	return 0;
}
