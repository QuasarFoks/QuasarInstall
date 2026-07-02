#include <cstdio>
#include <iostream>
#include <locale.h>
#include <sched.h>
#include <libintl.h> 
#include <string>
#include <sys/wait.h>
#include <sys/unistd.h>
#include <unistd.h>

using namespace std;
int main() {
    setlocale(LC_ALL, "");
    bindtextdomain("installer", "/usr/local/sdk/global/locale");
    textdomain("installer");
    pid_t pid = fork();
    if (pid == 0) {
        execlp("/usr/bin/paste", "/installer/wiki.qr/github-wiki", "/installer/wiki.qr/gitverse-mirror-wiki", NULL);
    } else if (pid == -1) {
        perror("fork");
    } else {
        wait(NULL);
    }
    return 0;
}
