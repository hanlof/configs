#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <time.h>

fd_set rfds;
struct timeval tv;
char buf[1024];
char * buffer;
int main(int argc, char * argv[])
{
  int bufpos = 0;
  int ret = 0;

  struct timeval timeval;
  char timestr[100];
  time_t t;
  struct tm *tmp;

  setbuf(stdin, NULL);
  while (1) {
    // XXX ninja does not output the line break until one step is finished
    // thus fscanf does not display the activity until after it is complete.
    // thats unacceptable!
    // we need to read the stream continuously and split lines if theres a too long delay

    ret = fscanf(stdin, "%m[^\n]\n", &buffer);
    if (ret < 0) { perror("fscanf"); return 0; }
    t = time(NULL);
    tmp = localtime(&t);
    strftime(&timestr[0], 10, "%H:%M:%S > ", tmp);
    //printf("\e[2K\e[1`");
    printf(timestr);
    printf("%1.200s", buffer);
    ret = sscanf(buffer, "[%[^]]", &buf[0]);
    if (ret == 1) {
	    printf("\e]0;%s\a", buf);
    } else {
	    //printf("\n");
    }
	    printf("\n");
    fflush(stdout);
    free(buffer);
  }

  return 0;
}
