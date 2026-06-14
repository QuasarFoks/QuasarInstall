#ifndef USERCFG
#define USERCFG

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
#include <cstring>

#define _(STRING) gettext(STRING)
#define RESET   "\033[0m"
#define RED     "\033[31m"
#define GREEN   "\033[32m"
#define YELLOW  "\033[33m"
#define BLUE    "\033[34m"
#define MAGENTA "\033[35m"
#define CYAN    "\033[36m"
#define BOLD_BRIGHT_WHITE "\033[1;97m"
int execute(initializer_list<const char*> args);
void log(std::string level, std::string message);
void create_user(std::string username);


#endif