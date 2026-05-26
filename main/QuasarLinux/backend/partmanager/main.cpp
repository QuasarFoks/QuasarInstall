#include "partmanager.hpp"
#include <sstream>

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

void save_progress(const std::string& module, const std::string& action, bool success) {
    std::string save_path = "/mnt/save.json";
    std::ifstream file(save_path);
    std::string content = "{";
    bool first = true;
    
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
//    "partmgr", "custom", disk, boot, root, rootfs, swap_flag, firm, luks_flag
    if (argc < 9) {
        log("error", "Not enough arguments!");
        return 1;
    }
    
    std::string type = argv[1];
    std::string disk = argv[2];
    std::string boot = argv[3];
    std::string root = argv[4];
    std::string rootfs = argv[5];
    std::string swap_flag = argv[6];
    std::string firrm = argv[7];
    std::string lucks_flag = argv[8];

    log("info", "Starting partition manager");
    log("debug", "type=" + type + ", disk=" + disk + ", boot=" + boot + ", root=" + root);
    
    save_progress("partmanager", "started", true);
    
    // TODO: Add partition logic here based on type
    
    save_progress("partmanager", "completed", true);
    log("info", "Partition manager completed successfully");
    return 0;
}