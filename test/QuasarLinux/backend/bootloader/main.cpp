#include "Setbootloader.hpp"

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


int main(int argc, char* argv[]) {
    setlocale(LC_ALL, "");
    bindtextdomain("installer", "/usr/local/sdk/global/locale");
    textdomain("installer");
    // bootinstall legacy grub /dev/sda 
    // legacy bootloader disk
    
    // 1 == grub
    // 2 == syslinux/efistub
    // 3 == refind

    std::string efi = argv[1];
    std::string bootloader = argv[2];
    std::string DISK = argv[3];
    std::string kernel = argv[4];
    std::string ESPBoot = argv[5];
    if (efi.empty()) {
        log("error", "Cannot detect firmware!");
        exit(1);
    }
    if (bootloader.empty()) {
        log("error", "Cannot detect bootloader!");
        exit(1);
    }
    if (DISK.empty()) {
        log("error", "Cannot detect disk!");
        exit(1);
    }
    if (kernel.empty() || kernel == "NULL") {
        log("warring", "the kernel is not selected, efistab and syslinux cannot be installed, only grub");
    }
    if (ESPBoot.empty() || ESPBoot == "NULL") {
        log("warring", "no ESP section is specified, only grub");
    }

    
    if ( efi == "legacy" ) {
        if (bootloader == "grub") {
            InstallGrubLegacy(DISK);
        } else if ( bootloader == "syslinux") {
            if (kernel.empty() || kernel == "NULL") {
                log("error", "the kernel is not selected, efistab and syslinux cannot be installed, only grub");
                exit(1);
            }
            InstallSyslinux(DISK, kernel);
        } else {
            log("fixme", "unknow bootloader");
        }
    } else if ( efi == "UEFI" || efi == "uefi") {
        if (bootloader == "grub") {
            InstallGrubUEFI();
        } else if (bootloader == "efistub") {
            if (kernel.empty() || kernel == "NULL") {
                log("error", "the kernel is not selected, efistab and syslinux cannot be installed, only grub");
                exit(1);
            }
            EfistubInstall(DISK, ESPBoot, kernel);
        } else if (bootloader == "refind") {
            RefindInstall(DISK, ESPBoot);
        } else {
            log("fixme", "unknow bootloader");
        }
    } else {
            log("fixme", "unknow firmware");
    }
    
}
