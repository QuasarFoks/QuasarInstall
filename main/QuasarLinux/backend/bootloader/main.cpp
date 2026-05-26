#include "Setbootloader.hpp"

void log(std::string level, std::string message) {
    if (level == "debug") {
        std::cerr << BOLD_BRIGHT_WHITE << "DEBUG::bootloader:: " << RESET << _(message.c_str()) <<  std::endl;
    }
    if (level == "info") {
        std::cerr << BLUE << "INFO::bootloader:: "  << RESET << _(message.c_str()) <<  std::endl;
    }
    if (level == "error") {
         std::cerr << RED << "ERR::bootloader:: " << RESET << _(message.c_str()) <<  std::endl;
    }
    if (level == "warning") {
         std::cerr << YELLOW << "WAR::bootloader:: " << RESET << _(message.c_str()) <<  std::endl;
    }
    if (level == "fixme") {
         std::cerr << MAGENTA << "FIXME::bootloader:: " << RESET << _(message.c_str()) <<  std::endl;
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


int main(int argc, char* argv[]) {
    setlocale(LC_ALL, "");
    bindtextdomain("installer", "/usr/local/sdk/global/locale");
    textdomain("installer");

    if (argc < 6) {
        log("error", "Not enough arguments!");
        return 1;
    }

    std::string efi = argv[1];
    std::string bootloader = argv[2];
    std::string DISK = argv[3];
    std::string kernel = argv[4];
    std::string ESPBoot = argv[5];
    if (efi.empty()) {
        log("error", "Cannot detect firmware!");
        return 1;
    }
    if (bootloader.empty()) {
        log("error", "Cannot detect bootloader!");
        return 1;
    }
    if (DISK.empty()) {
        log("error", "Cannot detect disk!");
        return 1;
    }
    if (kernel.empty() || kernel == "NULL") {
        log("warning", "the kernel is not selected, efistab and syslinux cannot be installed, only grub");
    }
    if (ESPBoot.empty() || ESPBoot == "NULL") {
        log("warning", "no ESP section is specified, only grub");
    }

    log("info", "Starting bootloader installation");
    save_progress("bootloader", "started", true);

    if ( efi == "legacy" ) {
        if (bootloader == "grub") {
            InstallGrubLegacy(DISK);
        } else if ( bootloader == "syslinux") {
            if (kernel.empty() || kernel == "NULL") {
                log("error", "the kernel is not selected, efistab and syslinux cannot be installed, only grub");
                save_progress("bootloader", "failed", false);
                return 1;
            }
            InstallSyslinux(DISK, kernel);
        } else {
            log("fixme", "unknow bootloader");
            save_progress("bootloader", "failed", false);
            return 1;
        }
    } else if ( efi == "UEFI" || efi == "uefi") {
        if (bootloader == "grub") {
            InstallGrubUEFI();
        } else if (bootloader == "efistub") {
            if (kernel.empty() || kernel == "NULL") {
                log("error", "the kernel is not selected, efistab and syslinux cannot be installed, only grub");
                save_progress("bootloader", "failed", false);
                return 1;
            }
            EfistubInstall(DISK, ESPBoot, kernel);
        } else if (bootloader == "refind") {
            RefindInstall(DISK, ESPBoot);
        } else {
            log("fixme", "unknow bootloader");
            save_progress("bootloader", "failed", false);
            return 1;
        }
    } else {
            log("fixme", "unknow firmware");
            save_progress("bootloader", "failed", false);
            return 1;
    }

    log("info", "Bootloader installation completed");
    save_progress("bootloader", "completed", true);
    return 0;
}
