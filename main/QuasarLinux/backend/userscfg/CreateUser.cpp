#include "usercfg.hpp"
void create_user(username) {
    if (username.c_str() == "root") {
        log("error", "The new user cannot be root");
        exit(1);
    } else {
        execlp("/usr/bin/chroot", "/usr/bin/useradd", "-m", "-g", username.c_str(), "-G", "wheel", username.c_str(), NULL);
        execlp("/usr/bin/chroot", "/usr/bin/passwd", username.c_str(), NULL);
        string userfile = "/etc/sudoers.d/" + username;
        ofstream out_sudo(userfile);
        if (out_sudo.is_open()) {
            out_sudo << username + " ALL=(ALL:ALL) ALL";
            out_sudo.close();
        }
        if (execlp("/usr/bin/chroot", "chmod", "440", userfile.c_str(), NULL) !=0) {
            log("fixme", "sudofile not found");
        }
        if (execlp("/usr/bin/sed", "-i", "'s/^#", "%wheel", "ALL=(ALL:ALL)",
                    "ALL/%wheel", "ALL=(ALL:ALL) ALL/'", "/etc/sudoers",
                    NULL) != 0) {
            log("fixme", "sudoers not found");
        }
    }
}