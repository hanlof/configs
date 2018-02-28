#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>
#include <ctype.h>

struct params {
	int allocsize;
	int readsize;
};

int get_multiplier(char * t, char * optarg)
{
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
        // also we cycle as soon as we are less than readsize bytes from the end of buffer.
        //   why? no good reason!!
	if (par->allocsize < 4 * PATH_MAX + par->readsize) {
		printf("allocsize must be four times PATH_MAX(%d) plus readsize bytes. (%d bytes in total)\n", PATH_MAX, 4 * PATH_MAX + par->readsize);
		printf("readsize:%d allocsize:%d\n", par->readsize, par->allocsize);
		exit(1);
	}
}

#define MAX(a, b) ( (a > b) ? (a) : (b) )
int main(int argc, char * argv[]) {
	struct params params = {
		.readsize = getpagesize(),
		.allocsize = 8 * MAX(PATH_MAX, getpagesize()),
	};
	parse_args(argc, argv, &params);
	check_args(&params);

	int ps = getpagesize();
	char prefix[] = "PREFIX/";
	char * outbuf = malloc(2 * ps);
	char * inbuf = malloc(2 * ps);


	char * outptr = outbuf;
	char * inptr = inbuf;
	char * pptr = &prefix[0];
	char n;
	int tmp;

	tmp = read(STDIN_FILENO, inbuf, ps);

	while (1) {
		pptr = &prefix[0];
		while (*pptr != '\0') {
			*outptr++ = *pptr++;
			if (outptr >= outbuf + ps) {
				tmp = write(STDOUT_FILENO, outbuf, ps);
				outptr = outbuf;
			}
		}
		do {
			n = *inptr;
			*outptr++ = n;
			if (inptr >= inbuf + ps) {
				tmp = read(STDIN_FILENO, inbuf, ps);
				if (tmp <= 0) goto out;
				inptr = inbuf;
			}
			if (outptr >= outbuf + ps) {
				tmp = write(STDOUT_FILENO, outbuf, ps);
				outptr = outbuf;
			}
			inptr++;
		} while (n != '\n');
		continue;
	}
out:

	return 0;
}
