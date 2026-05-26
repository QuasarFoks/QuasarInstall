#include <string>
#include <iostream>
#include "basepack.hpp"

void log(std::string level, std::string message) {
    if (level == "debug") {
        std::cerr << BOLD_BRIGHT_WHITE << "DEBUG::basepack:: " << RESET << _(message.c_str()) <<  std::endl;
    }
    if (level == "info") {
        std::cerr << BLUE << "INFO::basepack:: "  << RESET << _(message.c_str()) <<  std::endl;
    }
    if (level == "error") {
         std::cerr << RED << "ERR::basepack:: " << RESET << _(message.c_str()) <<  std::endl;
    }
    if (level == "warning") {
         std::cerr << YELLOW << "WAR::basepack:: " << RESET << _(message.c_str()) <<  std::endl;
    }
    if (level == "fixme") {
         std::cerr << MAGENTA << "FIXME::basepack:: " << RESET << _(message.c_str()) <<  std::endl;
    }
}

void save_progress(const std::string& module, const std::string& action, bool success) {
    std::string save_path = "/mnt/save.json";
    Json::Value root;
    std::ifstream file(save_path);
    
    if (file.is_open()) {
        file >> root;
        file.close();
    }
    
    root[module] = success;
    root["last_action"] = action;
    
    std::ofstream out(save_path);
    if (out.is_open()) {
        Json::StreamWriterBuilder builder;
        out << Json::writeString(builder, root);
        out.close();
        log("debug", "Saved progress: " + module + " = " + (success ? "true" : "false"));
    } else {
        log("error", "Failed to save progress to " + save_path);
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
        std::cout << "  init: openrc (default), systemd (beta)" << std::endl;
        std::cout << "  kernel: linux-lts (default), linux, linux-zen" << std::endl;
        std::cout << "  zram: zram_on (default: no zram)" << std::endl;
        std::cout << "Example: " << argv[0] << " openrc linux-zen zram_on" << std::endl;
        return 0;
    }

    if (argc < 5) {
        log("error", "Not enough arguments!");
        return 1;
    }

    std::string revision = argv[1];
    std::string init = argv[2];
    std::string kernel = argv[3];
    std::string zram_flag = argv[4];

    // basepack REV openrc linux zram_on
    log("debug", "Starting setup: init=" + init + " kernel=" + kernel + " zram=" + zram_flag);
    save_progress("basepack", "started", true);

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
        save_progress("basepack", "failed", false);
        return 1;
    }

    log("info", "Setup completed!");
    save_progress("basepack", "completed", true);
    return 0;
}
