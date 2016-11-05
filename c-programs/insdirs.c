#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char * compare_path(char * p, char * c)
{
  while (*p != '/' && *p != '\n')
    p--;

  while (*c != '/' && *c != '\n')
    c--;

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

#define ALLOCSIZE 0x800000
#define READSIZE 0x10

int main(int argc, int * argv[]) {
  char * buf_start = malloc(ALLOCSIZE);

  *buf_start++ = '\n'; // put newline as a mark at the beginning of the buffer. it will simplify the compare function.

  char * cur_line_start = buf_start;
  char * cur_line_end = buf_start;
  int i;
  i = read(0, buf_start, READSIZE);
  char * buf_end = buf_start + i;
  while (1) {
    if (i == 0) {
      break;
    }
    while (cur_line_end < buf_end) {
      while ('\n' != *++cur_line_end) {
        if (cur_line_end == buf_end) {
          i = read(0, buf_end, READSIZE);
          if (i == 0) {
            exit(0);
          }
          buf_end += i;
        }
      }
      // cur_line_start is pretty much the same as previous line end
      char * r = compare_path(cur_line_start - 1, cur_line_end - 1); // r becomes a pointer to the last slash
      if (r > cur_line_start) {
        write(1, cur_line_start, (int)(r - cur_line_start)+1);
      }
      write(1, cur_line_start, (cur_line_end - cur_line_start));
      cur_line_start = cur_line_end;
    }
    i = read(0, buf_end, READSIZE);
    buf_end += i;
  }
}
