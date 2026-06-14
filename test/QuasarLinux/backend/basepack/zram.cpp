#include "basepack.hpp"
using namespace std;
void zram_enable_openrc() {
    
    const char* init_path = "/mnt/etc/init.d/zram";
    ofstream out_zram(init_path);
    if (out_zram.is_open()) {
        out_zram << "#!/sbin/openrc-run\n";
        out_zram << "start() {\n";
        out_zram << "\tebegin \"Starting zram\"\n";
        out_zram << "\tmodprobe zram num_devices=1\n";
        out_zram << "\techo lz4 > /sys/block/zram0/comp_algorithm\n";
        out_zram << "\techo $(( $(grep MemTotal /proc/meminfo | awk '{print $2}') * 3 / 4 ))K > /sys/block/zram0/disksize\n";
        out_zram << "\tmkswap /dev/zram0\n";
        out_zram << "\tswapon /dev/zram0 -p 100\n";
        out_zram << "\teendzram_config(); $?\n";
        out_zram << "}\n";
        out_zram.close();
    } else {
        log("fixme", "zram init error");
    }
    system("chmod +x /mnt/etc/init.d/zram");
    system("chroot /mnt rc-update add zram sysinit");
    log("debug", "zram is add Autostart");
}
void zram_enable_systemd() {
    const char* zram_systemd_path = "/mnt/etc/systemd/zram-generator.conf";
    ofstream out_zram(zram_systemd_path);
    if (out_zram.is_open()) {
        out_zram << "[zram0]";
        out_zram << "zram-size = ram / 2 ";
        out_zram << "compression-algorithm = zstd";
        out_zram.close();
    } else {
        log("fixme", "zram init error");
    }
    system("chroot /mnt systemctl daemon-reload");
    system("chroot /mnt systemctl enable systemd-zram-setup@zram0.service");
}