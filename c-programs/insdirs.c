#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char * compare_path(char * p, char * c)
{
  p -= 2;
  c -= 2;

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

int main(int argc, int * argv[]) {
  char * buf_start = malloc(ALLOCSIZE);

  buf_start[0] = buf_start[1] = '\n';
  buf_start += 2;
  char * cur_line_start = buf_start;
  char * cur_line_end = buf_start;
  char * prev_line_end = buf_start;
  char * buf_end;
  int i;
  i = read(0, buf_start, 4096);
  cur_line_start = buf_start;
  cur_line_end = buf_start;
  buf_end = buf_start + i;
  while (1) {
    if (i == 0) {
      break;
    }
    while (cur_line_end < buf_end) {
      while ('\n' != *cur_line_end++) {
        if (cur_line_end == buf_end) {
          i = read(0, buf_end, 4096);
          if (i == 0) {
            exit(0);
          }
          buf_end += i;
        }
      }
      char * r = compare_path(prev_line_end, cur_line_end); // r becomes a pointer to the last slash
      if (r > cur_line_start) {
        char lf = '\n';
        write(1, cur_line_start, (int)(r - cur_line_start)+1);
        write(1, &lf, 1);
      }
      write(1, cur_line_start, (cur_line_end - cur_line_start));
      prev_line_end = cur_line_end;
      cur_line_start = cur_line_end;
    }
    i = read(0, buf_end, 4096);
    buf_end += i;

  }
}
