#include "region.hpp"
void RegionSet(std::string REGION, std::string REGION_ST) {
    std::string CMD = "ln -sf /usr/share/zoneinfo/" + REGION_ST + REGION + " /etc/localtime";
    system(CMD.c_str());
    log("info", "Region is past");
}
