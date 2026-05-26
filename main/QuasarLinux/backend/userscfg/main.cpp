#include "usercfg.hpp"
#include <sstream>
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
    std::ifstream file(save_path);
    std::string content = "{";
    
    if (file.is_open()) {
        std::stringstream buffer;
        buffer << file.rdbuf();
        content = buffer.str();
        file.close();
    }
    
    // Simple manual JSON update without jsoncpp
    std::ofstream out(save_path);
    if (out.is_open()) {
        // Remove closing brace and add new entry
        if (content.length() > 1 && content.back() == '}') {
            content.pop_back();
            if (content.length() > 1) content += ",";
        } else {
            content = "{";
        }
        content += "\"" + module + "\":" + (success ? "true" : "false");
        content += ",\"last_action\":\"" + action + "\"";
        content += "}";
        out << content;
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
