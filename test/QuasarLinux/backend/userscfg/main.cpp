#include "usercfg.hpp"
using namespace std;

void log(string level, string message) {
    if (level == "debug") {
        cerr << BOLD_BRIGHT_WHITE << "DEBUG: " << RESET << _(message.c_str()) << endl;
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
    string username = argv[1];
    create_user(username);
}