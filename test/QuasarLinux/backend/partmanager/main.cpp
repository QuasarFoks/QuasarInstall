#include "partmanager.hpp"


void log(std::string level, std::string message) {
    if (level == "debug") {
        std::cerr << BOLD_BRIGHT_WHITE << "DEBUG::partmanager:: " << RESET << _(message.c_str()) <<  std::endl;
    }
    if (level == "info") {
        std::cerr << BLUE << "INFO::partmanager:: "  << RESET << _(message.c_str()) <<  std::endl;
    }
    if (level == "error") {
         std::cerr << RED << "ERR::partmanager:: " << RESET << _(message.c_str()) <<  std::endl;
    }
    if (level == "warning") {
         std::cerr << YELLOW << "WAR::partmanager:: " << RESET << _(message.c_str()) <<  std::endl;
    }
    if (level == "fixme") {
         std::cerr << MAGENTA << "FIXME::partmanager:: " << RESET << _(message.c_str()) <<  std::endl;
    }
}
int main(int argc, char* argv[]) {
//    "partmgr", "custom", disk, boot, root, rootfs, swap_flag, firm, luks_flag
    std::string type = argv[1];
    std::string disk = argv[2];
    std::string boot = argv[3];
    std::string root = argv[4];
    std::string rootfs = argv[5];
    std::string swap_flag = argv[6];
    std::string firrm = argv[7];
    std::string lucks_flag = argv[8];

    return 0;
}