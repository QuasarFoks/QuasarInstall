#include "region.hpp"
using namespace std;
void log(string level, string message) {
    if (level == "debug") {
        cerr << BOLD_BRIGHT_WHITE << "DEBUG: " << RESET << _(message.c_str()) << endl;
    }
    if (level == "info") {
        cerr << BLUE << "INFO: " << RESET << _(message.c_str()) << endl;
    }
    if (level == "error") {
        cerr << RED << "ERR: " << RESET << _(message.c_str()) << endl;
    }
    if (level == "warning") {
        cerr << YELLOW << "WAR: " << RESET << _(message.c_str()) << endl;
    }
    if (level == "fixme") {
        cerr << MAGENTA << "FIXME: " << RESET << _(message.c_str()) << endl;
    }
}
int main(int argc, char* argv[]) {
    std::string REGION_ST = argv[1];
    std::string REGION = argv[2];
    std::string Mirror = argv[3];
    if (REGION.empty()) {
        log("error", "region is not found");
        exit(1);
    } else {
        RegionSet(REGION, REGION_ST);
    }

    if (Mirror.empty()) {
        log("warring", "mirror is not found, skip");
    }else if (Mirror == "mirror_on") {
        MirrorList(REGION);
    }
    return 0;
}
// region Europa Moscow 
