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

    // Help
    if (argc > 1 && (std::string(argv[1]) == "--help" || std::string(argv[1]) == "-h")) {
        std::cout << "Usage: " << argv[0] << " [init] [kernel] [zram]" << std::endl;
        std::cout << "  init: openrc (default), systemd" << std::endl;
        std::cout << "  kernel: linux-lts (default), linux, linux-zen" << std::endl;
        std::cout << "  zram: zram_on (default: no zram)" << std::endl;
        std::cout << "Example: " << argv[0] << " openrc linux-zen zram_on" << std::endl;
        return 0;
    }

    std::string init = argc > 1 ? argv[1] : "openrc";
    std::string kernel = argc > 2 ? argv[2] : "linux-lts";
    std::string zram = argc > 3 ? argv[3] : "no";
    
    log("debug", "Starting setup: init=" + init + " kernel=" + kernel + " zram=" + zram);

    if (init == "openrc") {
        openrc_base_system(kernel);
        config_system_openrc();
        enable_services_openrc();
        if (zram == "zram_on") {
            zram_enable_openrc();
        }
        config_openrc_two();
    } 
    else if (init == "systemd") {
        systemd_base_system(kernel);
        systemd_enable_service();
        if (zram == "zram_on") {
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
