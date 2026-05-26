#include "usercfg.hpp"
using namespace std;

void log(string level, string message) {
    if (level == "debug") {
        cerr << BOLD_BRIGHT_WHITE << "DEBUG::userscfg:: " << RESET << _(message.c_str()) << endl;
    }
    if (level == "info") {
        cerr << BLUE << "INFO::userscfg:: "  << RESET << _(message.c_str()) << endl;
    }
    if (level == "error") {
        cerr << RED << "ERR::userscfg:: " << RESET << _(message.c_str()) << endl;
    }
    if (level == "warning") {
        cerr << YELLOW << "WAR::userscfg:: " << RESET << _(message.c_str()) << endl;
    }
    if (level == "fixme") {
        cerr << MAGENTA << "FIXME::userscfg:: " << RESET << _(message.c_str()) << endl;
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

int main(int argc, char* argv[]) {
    if (argc < 2) {
        log("error", "Not enough arguments!");
        return 1;
    }
    
    string username = argv[1];
    log("info", "Creating user: " + username);
    save_progress("userscfg", "started", true);
    
    create_user(username);
    
    save_progress("userscfg", "completed", true);
    log("info", "User creation completed");
    return 0;
}
