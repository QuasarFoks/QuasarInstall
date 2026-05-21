#ifndef REGIONMGR
#define REGIONMGR

#include <iostream>
#include <cstdlib>
#include <string>

#include <unistd.h>
#include <sys/wait.h>
#include <libintl.h>

#define _(STRING) gettext(STRING)
#define RESET   "\033[0m"
#define RED     "\033[31m"
#define GREEN   "\033[32m"
#define YELLOW  "\033[33m"
#define BLUE    "\033[34m"
#define MAGENTA "\033[35m"
#define CYAN    "\033[36m"
#define BOLD_BRIGHT_WHITE "\033[1;97m"

void RegionSet(std::string REGION, std::string REGION_ST);
void MirrorList(std::string REGION);
void log(std::string level, std::string message);

#endif
