#include "basepack.hpp"
void systemd_base_system(string kernel) {
    log("debug", "Installe base system openrc");
    string cmd = "basestrap /mnt terminus-font iptables-nft base base-devel mkinitcpio "
             " dbus linux-firmware dialog acpid flatpak "
             " dash chrony linux-api-headers rsync lib32-udev "
             " networkmanager " + kernel + " " + kernel + "-headers";  
    system(cmd.c_str());
    log("debug", "base system install complete");

    system("fstabgen -U /mnt >> /mnt/etc/fstab");
    log("debug", "fstab generate complete");

    system("chroot /mnt flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo");
    log("debug", "flatpak install complete");
}
void systemd_config() {
    // нет
}
void systemd_enable_service() {
    std::string services[] = {"NetworkManager", "chrony", "acpid"};
    for (const std::string& ser : services) {
        std::string cmd = "chroot /mnt systemctl enable " + ser;
        system(cmd.c_str());
    }
}