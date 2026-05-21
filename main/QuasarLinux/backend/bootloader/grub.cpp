#include "Setbootloader.hpp"

void InstallGrubLegacy(std::string DISK) {
    system("chroot /mnt pacman -S grub os-prober efibootmgr --noconfirm");
    std::cout << ">>> Installing BIOS Bootloader..." << std::endl;


    if (DISK.empty()) {
        log("error", "Cannot detect disk for BIOS install!");
        return;
    }
    std::cout << "[OK] Target Disk: " << DISK << std::endl;
    std::string cmd = "chroot /mnt grub-install --target=i386-pc "
    "--boot-directory=/boot --recheck \"" + DISK + "\"";

    if (system(cmd.c_str()) != 0) {
        log("error", "BIOS GRUB installation failed!");
        return;
    }
    configure_grub_distributor();
}
void InstallGrubUEFI() {
    system("fast-chroot /mnt pacman -S grub os-prober efibootmgr --noconfirm");
    system("fast-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable --recheck");
    configure_grub_distributor();
    system("fast-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg");
}

void configure_grub_distributor() {
    const std::string path = "/mnt/etc/default/grub";
    const std::string target_var = "GRUB_DISTRIBUTOR=";
    const std::string new_value = "GRUB_DISTRIBUTOR=\"QuasarLinux\"";

    if (!fs::exists(path)) {
        std::ofstream out(path);
        if (out.is_open()) { out << new_value << std::endl; out.close(); }
        return;
    }

    std::ifstream in(path);
    std::vector<std::string> lines;
    std::string line;
    bool found = false;

    while (getline(in, line)) {
        if (line.find(target_var) == 0) {
            lines.push_back(new_value);
            found = true;
        } else {
            lines.push_back(line);
        }
    }
    in.close();

    if (!found) lines.push_back(new_value);

    std::ofstream out(path);
    if (out.is_open()) {
        for (const auto& l : lines) out << l << "\n";
        out.close();
    }
}