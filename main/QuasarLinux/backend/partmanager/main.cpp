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