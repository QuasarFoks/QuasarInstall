#include "basepack.hpp"

void openrc_base_system(string kernel) {
    log("debug", "Installe base system openrc");

    string cmd = "basestrap /mnt terminus-font iptables-nft base base-devel mkinitcpio openrc "
             "dbus dbus-openrc elogind-openrc linux-firmware dialog acpid flatpak "
             "acpid-openrc chrony-openrc dash chrony linux-api-headers rsync lib32-udev "
             "networkmanager networkmanager-openrc " + kernel + " " + kernel + "-headers";    
    system(cmd.c_str());
    log("debug", "base system install complete");

    system("fstabgen -U /mnt >> /mnt/etc/fstab");
    log("debug", "fstab generate complete");

    system("chroot /mnt flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo");
    log("debug", "flatpak install complete");
}
void config_system_openrc() {
    const char* path_rc = "/mnt/etc/rc.conf";
    std::ofstream out_rc(path_rc);
    if (out_rc.is_open()) {
        out_rc << "rc_parallel=\"YES\"\n";
        out_rc << "rc_parallel_rcwait=\"NO\"\n";
        out_rc << "rc_logger=\"YES\"\n";
        out_rc << "rc_verbose=\"NO\"\n";
        out_rc << "unicode=\"YES\"\n";
        out_rc << "rc_cgroup_mode=\"legacy\"\n";
        out_rc << "rc_timeout_stopsec=\"10\"\n";
        out_rc.close();
    } else {
        std::string err = ("Failed to open file /mnt/etc/rc.conf");
        log("fixme", err.c_str());
    }
}
void enable_services_openrc() {
    std::vector<std::pair<std::string, std::string>> services = {
        {"udev", "sysinit"},
        {"dbus", "boot"},
        {"elogind", "boot"},
        {"acpid", "default"},
        {"NetworkManager", "default"},
        {"chrony", "default"}
    };
    for (const auto& [name, level] : services) { // C++17 Structured Binding (красота!)
        std::string cmd = "chroot /mnt rc-update add " + name + " " + level + " 2>/dev/null";
        if (system(cmd.c_str()) != 0) {
            std::string err = ("[WARN] Failed: " + name + " (" + level + ")");
            log("fixme", err.c_str());
        }
    }
}
void config_openrc_two() {
    std::string url = "https://github.com/QuasarFoks/QuasarLinux/releases/download/REV-1.2-image/SYSTEM.zip";
    std::string output_file = "QuasarLinux.tar.bz2";
    std::string cmd = "wget -O \"" + output_file + "\" \"" + url + "\"";
    int status = system(cmd.c_str());
    if (status != 0) {
        std::string err = "Failed to download image! Status: " + std::to_string(status);
        log("fixme", err.c_str());
        // Тут можно добавить удаление битого файла
        remove(output_file.c_str());
    }
    system("bsdunzip x SYSTEM.zip -C /mnt");


    std::cerr << ">>> Install base system complete." << std::endl;
    system("tar -zstd -xvf /installer/packages/kresd-x86_64.tar.zst  -C /mnt");


    system("chmod +x /mnt/etc/init.d/kresd");
    system("chroot /mnt rc-update add kresd default");
    log("debug", "kresd is add Autostart");
}
