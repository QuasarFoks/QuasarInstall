#ifndef BASEPACK
#define BASEPACK

#include <iostream>
#include <cstdlib>
#include <string>
#include <fstream>
#include <ncurses.h>
#include <unistd.h>
#include <vector>
#include <sys/wait.h>
#include <libintl.h>
#include <locale.h>
#include <curl/curl.h>
#include <sys/mount.h>
#include <jsoncpp/json/json.h>


#define _(STRING) gettext(STRING)
#define RESET   "\033[0m"
#define RED     "\033[31m"
#define GREEN   "\033[32m"
#define YELLOW  "\033[33m"
#define BLUE    "\033[34m"
#define MAGENTA "\033[35m"
#define CYAN    "\033[36m"
#define BOLD_BRIGHT_WHITE "\033[1;97m"
using namespace std;
void log(std::string level, std::string message);
void save_progress(const std::string& module, const std::string& action, bool success);
void prepart();
void system_settings();



// openrc set
void enable_services_openrc();
void openrc_base_system(string kernel);
void config_openrc_two();
void config_system_openrc();
void zram_enable_openrc();



// systemd set
void systemd_base_system(string kernel);
void systemd_config();
void systemd_enable_service();
void zram_enable_systemd();
#endif
