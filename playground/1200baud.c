#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <termios.h>
#include <sys/ioctl.h>

int main(int argc, char * argv[])
{
	int fd = openat(AT_FDCWD, "/dev/ttyACM0", O_RDWR|O_NOCTTY|O_NONBLOCK);
	printf("openat() = %d\n", fd);

	struct termios t;

	tcgetattr(fd, &t);
	t.c_iflag=0x0;
	tcsetattr(fd, 0, &t);

	tcgetattr(fd, &t);
	t.c_cflag=0x8b9;
	tcsetattr(fd, 0, &t);

	fcntl(fd, 0x3, NULL);
	fcntl(fd, 0x4, 0x8002);

	char slask[10];
	ioctl(fd, 0x540c, &slask[0]);
	ioctl(fd, 0x5415, &slask[0]);
	slask[0] = 0x24;
	ioctl(fd, 0x5418, &slask[0]);
	ioctl(fd, 0x540d, &slask[0]);
	close(fd);

	return 0;
}
/*

openat(-100  AT_FDCWD , "/dev/ttyACM0", 0x902  O_RDWR|O_NOCTTY|O_NONBLOCK ) = 7</dev/ttyACM0<char 166:0>>

ioctl(7, 0x5401 TCGETS, {c_iflags=0x1, c_oflags=0, c_cflags=0x18b2, c_lflags=0, c_line=0, c_cc[VMIN]=1, c_cc[VTIME]=0, c_cc="\x03\x1c[...]\x00\x00\x00"}) = 0
ioctl(7, 0x5402 TCSETS, {c_iflags=0,   c_oflags=0, c_cflags=0x18b2, c_lflags=0, c_line=0, c_cc[VMIN]=1, c_cc[VTIME]=0, c_cc="\x03\x1c[...]\x00\x00\x00"}) = 0

ioctl(7, 0x5401 TCGETS, {c_iflags=0, c_oflags=0, c_cflags=0x18b2, c_lflags=0, c_line=0, c_cc[VMIN]=1, c_cc[VTIME]=0, c_cc="\x03\x1c[...]\x00\x00\x00"}) = 0
ioctl(7, 0x5402 TCSETS, {c_iflags=0, c_oflags=0, c_cflags=0x8b9,  c_lflags=0, c_line=0, c_cc[VMIN]=1, c_cc[VTIME]=0, c_cc="\x03\x1c[...]\x00\x00\x00"}) = 0

fcntl(7, 0x3  F_GETFL ) = 0x8802 (flags O_RDWR|O_NONBLOCK|O_LARGEFILE)
fcntl(7, 0x4  F_SETFL , 0x8002  O_RDWR|O_LARGEFILE ) = 0
ioctl(7, 0x540c  TIOCEXCL ) = 0
pipe([826660]>]) = 0
ioctl(7, 0x5415  TIOCMGET , [0x26  TIOCM_DTR|TIOCM_RTS|TIOCM_CTS ]) = 0
ioctl(7, 0x5418  TIOCMSET , [0x24  TIOCM_RTS|TIOCM_CTS ]) = 0
ioctl(7, 0x540d  TIOCNXCL ) = 0
close(7) = 0



*/


