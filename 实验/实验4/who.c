#include <asm/segment.h>
#include <errno.h>
#include <string.h>

char _myname[24];       // 23 characters

int sys_iam(const char* name) {
    char temp[30];
    int i = 0;
    // get string
    for (i = 0; i < 30; i++) {
        temp[i] = get_fs_byte(name + i);
        if (temp[i] == '\0') {
            break;
        }
    }
    int len = strlen(temp);
    if (len > 23) {         // too long
        return -(EINVAL);   // error
    }
    strcpy(_myname, temp);
    return len;
}

int sys_whoami(char* name, unsigned int size) {
    int len = strlen(_myname) + 1;      // \0 at the end of the string

    if (size < len) {
        return -(EINVAL);
    }
    // save string
    int i = 0;
    for (i = 0; i < len; i++) {
        put_fs_byte(_myname[i], (name + i));
    }

    return len - 1;
}

