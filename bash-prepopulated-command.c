#include <strings.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>
#include <stdio.h>
#include <unistd.h>

main()
{
    char buf[] = "date";
    int i;
    struct termios oldtio,newtio;
    int fd=0;

    tcgetattr(fd,&oldtio); /* save current serial port settings */
    bzero(&newtio, sizeof(newtio)); /* clear struct for new port settings */

    memcpy(&newtio, &oldtio, sizeof(oldtio) );
    newtio.c_lflag &= ~ECHO;

    tcflush(fd, TCIFLUSH);
    tcsetattr(fd,TCSANOW,&newtio);

    for (i = 0; i < sizeof buf - 1; i++)
      ioctl(fd, TIOCSTI, &buf[i]);

    tcsetattr(fd,TCSANOW,&oldtio);
    return 0;
}
