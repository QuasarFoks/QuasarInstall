#include <string>
#include <iostream>
#include "basepack.hpp"

void log(std::string level, std::string message) {
    if (level == "debug") {
        std::cerr << BOLD_BRIGHT_WHITE << "DEBUG: " << RESET << _(message.c_str()) <<  std::endl;
    }
    if (level == "error") {
         std::cerr << RED << "ERR: " << RESET << _(message.c_str()) <<  std::endl;
    }
    if (level == "warning") {
         std::cerr << YELLOW << "WAR: " << RESET << _(message.c_str()) <<  std::endl;
    }
    if (level == "fixme") {
         std::cerr << MAGENTA << "FIXME: " << RESET << _(message.c_str()) <<  std::endl;
    }
}
void prepart()
{
    if (mount("/dev", "/mnt/dev", NULL, MS_BIND, NULL) == -1) {
        perror("mount bind");
    }
    if (mount("/proc", "/mnt/proc", NULL, MS_BIND, NULL) == -1) {
        perror("mount bind");
    }
    if (mount("/sys", "/mnt/sys", NULL, MS_BIND, NULL) == -1) {
        perror("mount bind");
    }
    if (mount("/run", "/mnt/run", NULL, MS_BIND, NULL) == -1) {
        perror("mount bind");
    }
}
int main(int argc, char *argv[]) {
    using namespace std;
    setlocale(LC_ALL, "");
    bindtextdomain("installer", "/usr/local/sdk/global/locale");
    textdomain("installer");
    prepart();

    // Проверка количества аргументов
    if (argc < 5 && argc > 1) {
        cout << "Error: not enough arguments!" << endl;
        cout << "Usage: " << argv[0] << " [init] [kernel] [zram]" << endl;
        return 1;
    }

    // Help
    if (argc < 5 && argc != 2) {  // 2 аргумента — это --help
    cout << "Error: not enough arguments!" << endl;
    return 1;
    }

    
    string revision = argv[1];
    string init = argv[2];
    string kernel = argv[3];
    string zram_flag = argv[4];
    // basepack REV openrc linux zram_on
    log("debug", "Starting setup: init=" + init + " kernel=" + kernel + " zram=" + zram_flag);

    if (init == "openrc") {
        openrc_base_system(kernel);
        config_system_openrc();
        enable_services_openrc();
        if (zram_flag == "zram_on") {
            zram_enable_openrc();
        }
        config_openrc_two();
    } 
    else if (init == "systemd") {
        systemd_base_system(kernel);
        systemd_enable_service();
        if (zram_flag == "zram_on") {
            zram_enable_systemd();
        }
    } 
    else {
        log("error", "Unknown init system: " + init);
        return 1;
    }

    log("info", "Setup completed!");
    return 0;
}
