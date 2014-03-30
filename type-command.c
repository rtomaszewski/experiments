#include <strings.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

const char *TYPE_CMD_ENABLED = "TYPE_CMD_ENABLED";
const char *TYPE_CMD_TYPE = "TYPE_CMD_TYPE";

const char *PROGRAM_NAME = "type-command";


int main(void) {
    struct termios oldtio,newtio;
    int fd=0;
    int i;

    char *is_enabled;
    char *command;

    // read the bash variables
    is_enabled = getenv(TYPE_CMD_ENABLED);
    command = getenv(TYPE_CMD_TYPE);

    // is the var defined at all
    if ( ! is_enabled ) {
        printf("%s: the variable %s is not set, set it to 'no' to surpress this message; set the %s for the command to type\n", 
                PROGRAM_NAME, TYPE_CMD_ENABLED, TYPE_CMD_TYPE);
        printf("\n Example: export %s=yes; export %s=date\n", TYPE_CMD_ENABLED, TYPE_CMD_TYPE);

        return 0;

    // has the variable value different than 'yes'
    } else if ( strcmp(is_enabled, "yes") ) {
        return 0;
    }

    if ( ! command ) {
        return 0;
    }

    tcgetattr(fd,&oldtio);                      // save current terminal  settings
    bzero(&newtio, sizeof(newtio));             // clear struct for new port settings

    memcpy(&newtio, &oldtio, sizeof(oldtio) );
    newtio.c_lflag &= ~ECHO;                    // do not echo the input chars

    tcflush(fd, TCIFLUSH);                      // set the new terminal settings
    tcsetattr(fd,TCSANOW,&newtio);

    for (i = 0; i < strlen(command); i++)
      ioctl(fd, TIOCSTI, &command[i]);

    tcsetattr(fd,TCSANOW,&oldtio);
    return 0;
}

