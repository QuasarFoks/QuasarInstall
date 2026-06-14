#include "usercfg.hpp"
#include <sys/wait.h>
#include <unistd.h>
#include <vector>

using namespace std;

// Простая обёртка для запуска команды через fork+exec
// Принимает список аргументов, последний должен быть nullptr
int execute(initializer_list<const char*> args) {
    // Превращаем в vector для удобства и гарантируем nullptr в конце
    vector<const char*> argv(args);
    argv.push_back(nullptr);

    pid_t pid = fork();
    if (pid == -1) {
        // fork не удался
        return -1;
    }
    if (pid == 0) {
        // Дочерний процесс
        execvp(argv[0], const_cast<char* const*>(argv.data()));
        // Если execvp вернулся — значит ошибка
        _exit(1);
    }
    // Родительский процесс
    int status;
    waitpid(pid, &status, 0);
    if (WIFEXITED(status))
        return WEXITSTATUS(status);
    return -1;
}

void create_user(string username) {
    if (username == "root") {
        log("error", "The new user cannot be root");
        exit(1);
    } else {

        execute({"/usr/bin/chroot", "/mnt", "/usr/sbin/useradd", "-m", "-g", username.c_str(),
            "-G", "wheel", username.c_str(), nullptr});

        // Установка пароля (запустится только после завершения useradd)
        execute({"/usr/bin/passwd", username.c_str(), nullptr});

        // Запись sudoers-файла
        string userfile = "/mnt/etc/sudoers.d/" + username;
        ofstream out_sudo(userfile);
        if (out_sudo.is_open()) {
            out_sudo << username + " ALL=(ALL:ALL) ALL";
            out_sudo.close();
        }

        // Изменение прав на файл
        if (execute({"/usr/bin/chmod", "440", userfile.c_str(), nullptr}) != 0) {
            log("fixme", "sudofile not found");
        }

        // Правка основного sudoers 
        if (execute({"/usr/bin/sed", "sed", "-i",
            "s/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/",
                    "/mnt/etc/sudoers", nullptr}) != 0) {
            log("fixme", "sudoers not found");
                    }
    }
}
