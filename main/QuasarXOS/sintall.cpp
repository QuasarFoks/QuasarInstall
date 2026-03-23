#include <iostream>
#include <fstream>
#include <unistd.h>
#include <sys/wait.h>
#include <vector>
#include <cstring>

using namespace std;
void mount_fs()
{
    system("mount -t devfs devfs /mnt/dev");
    system("mount -t procfs procfs /mnt/proc");
    system("mount -t nullfs /var/run /mnt/var/run");
    system("mount -t nullfs /tmp /mnt/tmp");
}

void unmountChrootFreeBSD()
{
    cout << ">>> Unmounting filesystems..." << endl;
    // Важно размонтировать в обратном порядке или аккуратно
    system("umount /mnt/tmp");
    system("umount /mnt/var/run");
    system("umount /mnt/proc");
    system("umount /mnt/dev");
}

int runCmd(const char* cmd, const vector<string>& args) {
    pid_t pid = fork();

    if (pid == -1) {
        cerr << "CRITICAL: Fork failed! (" << strerror(errno) << ")" << endl;
        return -1;
    }

    if (pid == 0) {
        // Дочерний процесс
        // Формируем массив argv для execvp (последний элемент NULL)
        vector<char*> argv;
        argv.push_back((char*)cmd);
        for (const auto& arg : args) {
            argv.push_back((char*)arg.c_str());
        }
        argv.push_back(nullptr);

        // Выполняем команду. Ищем в PATH.
        // Для системных команд на FreeBSD лучше явно указывать путь, если PATH не настроен,
        // но обычно /sbin:/bin:/usr/sbin:/usr/bin есть у рута.
        execvp(cmd, argv.data());

        // Если вернулись - ошибка
        cerr << "EXEC FAILED: " << cmd << " -> " << strerror(errno) << endl;
        _exit(127);
    } else {
        // Родительский процесс
        int status;
        waitpid(pid, &status, 0);

        if (WIFEXITED(status)) {
            return WEXITSTATUS(status);
        }
        return -1;
    }
}
bool checkSha256(const std::string& file, const std::string& expected) {
    std::string cmd = "sha256 -q " + file + " | grep -x " + expected + " > /dev/null 2>&1";
    return std::system(cmd.c_str()) == 0;
}
void downloades_image() {
    string url_world = "https://github.com/QuasarFoks/QuasarXOS/release/v1/world.tar.xz";
    string url_kernel = "https://github.com/QuasarFoks/QuasarXOS/release/v1/kernel.tar.xz";

    string cmd = "fetch -o  /mnt/world.tar.xz " + url_world + "> /dev/null 2>&1";
    system(cmd.c_str());
    if (checkSha256("/mnt/world.tar.xz", "xxxxxxxxxx")) {
        cerr << "[OK]: FIle";
    } else {
        cerr << "[ERR]: File";
    }

    string cmd_2 = "fetch -o  /mnt/kernel.tar.xz " + url_kernel + "> /dev/null 2>&1";
    if (checkSha256("/mnt/kernel.tar.xz", "xxxxxxxxxx")) {
        cerr << "[OK]: FIle";
    } else {
        cerr << "[ERR]: File";
    }

}
void unpacking_image() {
    string kernel = "/mnt/kernel.tar.xz";
    string world = "/mnt/world.tar.xz";
    string cmd_kernel = "tar -xf" + kernel + "-C /mnt";
    string cmd_world = "tar -xf" + world + "-C /mnt";
    system(cmd_kernel.c_str());
    system(cmd_world.c_str());
}

void userset(const string& username, const string& password, bool isRootSetup = false)
{
    cout << ">>> Setting up user: " << username << endl;
    vector<string> addArgs = {"useradd", username, "-m", "-s", "/bin/csh"};
    if (!isRootSetup) {
        addArgs.push_back("-G");
        addArgs.push_back("wheel");
    }

    int res = runCmd("/usr/sbin/pw", addArgs);
    if (res != 0) {
        cerr << "ERR: Failed to create user via pw." << endl;
        return;
    }
    pid_t pid_pass = fork();
    if (pid_pass == 0) {
        // Перенаправляем stdin, чтобы скормить пароль
        // Но проще вызвать шелл: echo "pass\npass" | passwd user
        execl("/bin/sh", "sh", "-c",
              ("echo \"" + password + "\\n" + password + "\" | /usr/bin/passwd " + username).c_str(),
              nullptr);
        _exit(127);
    } else {
        waitpid(pid_pass, nullptr, 0);
    }

    cout << ">>> User " << username << " configured successfully." << endl;

}

void config_system() {
    const char* init_rc = "/mnt/rc.conf";
    ofstream out_rc(init_rc, ios::app);
    if (out_rc.is_open()) {
        out_rc << "hostname=\"quasarxos_desktop\"";
        out_rc.close();
    } else {
        cerr << "ERR: cant open rc.conf." << endl;
    }

    char setuser_add;
    cout << "Create a new user? y/n: ";
    cin >> setuser_add;
    if (setuser_add == 'y') {
        string username;
        string passwd_user;
        cout << "username: ";
        cin >> username;

        cout << "password\n" << endl;
        std::string cmd = "/usr/bin/passwd " + username;
        execl("/sbin/chroot", "chroot", "/mnt", "/bin/sh", "-c", cmd.c_str(), nullptr);
    } else {
        string cmd = "/usr/bin/passwd";
        execl("/sbin/chroot", "chroot", "/mnt", "/bin/sh", "-c", cmd.c_str(), nullptr);
    }

}

int main()
{
    if (geteuid() != 0) {
        cerr << "FATAL: Must run as ROOT!" << endl;
        return 1;
    }
    downloades_image();
    unpacking_image();
    system("mkdir -p /mnt/{dev,var/run,proc,sys,tmp}");
    mount_fs();
    mount_fs();
    config_system();




    return 0;
}
