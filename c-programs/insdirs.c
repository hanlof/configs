#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char * compare_path(char * p, char * c)
{
//  printf("%x %x\n", p, c);
//  printf(">>%10s<<\n", p);
  p--;
  c--;
  p--;
  c--;
  while (*p != '/' && *p != '\n') {
    p--;
  }
  while (*c != '/' && *c != '\n') {
    c--;
  }
//  printf("%x %x\n", p, c);
//  printf(">>%10s<<\n", p);
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

int main(int argc, int * argv[]) {
  int allocsize = 0x800000;
  char * alloc_ptr = malloc(allocsize);
  *alloc_ptr = '\n'; // put newline as a mark at the beginning of the buffer. it will simplify the compare function.
  *(alloc_ptr + 1) = '\n'; // put newline as a mark at the beginning of the buffer. it will simplify the compare function.
  char * buf_start = alloc_ptr + 2;
  char * cur_line_start = buf_start;
  char * cur_line_end = buf_start;
  char * prev_line_end = buf_start;
  char * buf_end;
  int i, j;
  int tot = 0;
  i = read(0, buf_start, 4096);
  cur_line_start = buf_start;
  cur_line_end = buf_start;
  buf_end = buf_start + i;
  while (1) {
    if (i == 0) {
      break;
    }
    //printf("%i %i %i\n", buf_end, buf_start, i);
    while (cur_line_end < buf_end) {
      while ('\n' != *cur_line_end++) {
        if (cur_line_end == buf_end) {
          i = read(0, buf_end, 4096);
          char * dbg = "\e[32mXXX\e[0m";
     //     write(1, dbg, strlen(dbg));
     //     write(1, buf_end, (5));
     //     write(1, dbg, strlen(dbg));
     //     write(1, cur_line_end, (5));
     //     write(1, dbg, strlen(dbg));
     //     fprintf(stderr, "%i\n", i);
          if (i == 0) {
            exit(0);
          }
          buf_end += i;
        }
      }
      char * r = compare_path(prev_line_end, cur_line_end); // r becomes a pointer to the last slash
      if (r > cur_line_start) {
        char lf = '\n';
        //char * red = "\e[31m";
        //char * normal = "\e[0m";

   //     write(1, red, 5);
        write(1, cur_line_start, (int)(r - cur_line_start)+1);
   //     write(1, normal, 4);
        write(1, &lf, 1);
   //     printf(">>%i,%x<<\n", r-cur_line_start,r);
      }
      write(1, cur_line_start, (cur_line_end - cur_line_start));
      prev_line_end = cur_line_end;
      cur_line_start = cur_line_end;
     // printf("%x %x\n", cur_line_end, buf_end);
    }
    i = read(0, buf_end, 4096);
    buf_end += i;

//    printf("\n\n<<<<<<<<<<<<<<<<<<< %i\n\n", tot);
  }
 // printf("%i\n", tot);
}
