#include <iostream>
#include <cstdlib>
#include <filesystem>
#include <ncurses.h>
#include <vector>
using namespace std;
namespace fs = std::filesystem;
void setup_ncurses() {
    initscr();              // Старт экрана
    cbreak();               // Отключить буферизацию ввода (сразу по нажатию)
    noecho();               // Не дублировать ввод на экран
    keypad(stdscr, TRUE);   // Включить стрелки и спецклавиши
    curs_set(0);            // Скрыть курсор (для красоты)
}

void cleanup_ncurses() {
    endwin();               // Восстановить терминал
}

bool check_efi()
{
    namespace fs = std::filesystem;
    if (fs::exists("/sys/firmware/efi")) {
        return true;
    } else {
        return false;
    }
}

string disk_check() {
    vector<std::string> disks;
    const std::string sys_block_path = "/sys/block";

    if (!fs::exists(sys_block_path)) return disks;

    for (const auto& entry : fs::directory_iterator(sys_block_path)) {
        if (entry.is_directory()) {
            disks.push_back(entry.path().filename().string());
        }
    }
    return disks;
}


void make_ext4(part_root)
{
    string cmd = "/usr/bin/mkfs.ext4 -F %s ", part_root;
    system("cmd");
}
void make_btrfs(part_root)
{
    string cmd = "/usr/bin/mkfs.ext4 -F %s ", part_root;
    system("cmd");
}
void var() {
    system("lsblk");


}
void auto_part(disk) {
    bool var_efi = (check_efi());
    if (var_efi == true) {

    }


}
int main() {
    bool var_efi = (check_efi())
    setup_ncurses();



}
