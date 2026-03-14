#include <iostream>
#include <cstdlib>
#include <string>
#include <fstream>
#include <ncurses.h>
#include <vector>
#include <sys/wait.h>
#include <libintl.h>
#include <locale.h>


using namespace std;

void prepart()
{
    system("mount --bind /dev /mnt/dev");
    system("mount --bind /proc /mnt/proc");
    system("mount --bind /sys /mnt/sys");
    system("mount --bind /run /mnt/run");
}



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

void install_base_openrc()
{
    cout << ("Installe base system openrc") << endl;
    system("basestrap /mnt terminus-font iptables-nft base base-devel mkinitcpio openrc dbus dbus-openrc elogind-openrc linux-firmware dialog acpid flatpak acpid-openrc chrony-openrc dash chrony  linux-api-headers rsync lib32-udev networkmanager networkmanager-openrc ");
    cerr << ("base system install complete") << endl;
    system("fstabgen -U /mnt >> /mnt/etc/fstab");
    cerr << ("INFO: fstab generate complete") << endl;
    system("fast-chroot /mnt flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo");
    cerr << ("INFO: flatpak install complete") << endl;

}



int show_kernel_menu() {
    const char* options[] = {
        "Linux Zen (Performance)",
        "Linux LTS (Stability)",
        "Linux Vanilla (Standard)"
    };
    int highlight = 0;
    int choice = -1;
    int c;

    while (true) {
        clear();
        mvprintw(0, 0, "=== Select Kernel ===");

        for (int i = 0; i < 3; i++) {
            if (i == highlight) {
                attron(A_REVERSE); // Выделение инверсией
                mvprintw(2 + i, 2, "> %s", options[i]);
                attroff(A_REVERSE);
            } else {
                mvprintw(2 + i, 4, "%s", options[i]);
            }
        }

        refresh();
        c = getch();

        if (c == KEY_UP) {
            if (highlight > 0) highlight--;
        } else if (c == KEY_DOWN) {
            if (highlight < 2) highlight++;
        } else if (c == 10 || c == KEY_ENTER) { // Enter
            choice = highlight + 1; // Возврат 1, 2 или 3
            break;
        }
    }
    return choice;
}

void system_settings() {
    const char* path = "/mnt/etc/os-release";
    system("ln -sf /usr/lib/os-release /mnt/etc/os-release");
    ofstream out(path);
    if (out.is_open()) {
        out << "NAME=\"Quasar Linux\"\n";
        out << "ID=quasar\n";
        out << "PRETTY_NAME=\"Quasar Linux SE-REV V0.1\"\n";
        out << "BUILD_ID=SE/REV-0.1\n";
        out << "ANSI_COLOR=\"38;2;23;147;209\"\n";
        out << "HOME_URL=\"https://quasarfoks.github.io/QuasarLinux\"\n";
        out << "LOGO=quasarlogo\n";
        out.close();
    } else {
        cerr << "Ошибка: Не удалось открыть файл " << path << "\n";
        cerr << "Причина: Скорее всего нет прав (нужен sudo) или нет папки.\n";
    }

    const char* path_rc = "/mnt/etc/rc.conf";
    ofstream out_rc(path_rc);
    if (out_rc.is_open()) {
        out_rc << "rc_parallel=\"YES\"\n";
        out_rc << "rc_parallel_rcwait=\"NO\"\n";
        out_rc << "rc_logger=\"YES\"\n";
        out_rc << "rc_verbose=\"NO\"\n";
        out_rc << "unicode=\"YES\"\n";
        out_rc << "rc_cgroup_mode=\"legacy\"\n";
        out_rc << "rc_timeout_stopsec=\"10\"\n";
        out_rc.close();
    } else {
        cerr << "Ошибка: Не удалось открыть файл " << path_rc << "\n";
        cerr << "Причина: Скорее всего нет прав (нужен sudo) или нет папки.\n";
    }
     //"en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
     //"ru_RU.UTF-8 UTF-8" >> /mnt/etc/locale.gen
    const char* locale_path = "/mnt/etc/locale.gen";
    ofstream out_locale(locale_path);
    if (out_locale.is_open()) {
        out_locale << "en_US.UTF-8 UTF-8\n";
        out_locale << "ru_RU.UTF-8 UTF-8\n";
        out_locale.close();
    } else {
        cerr << "Не известная ошибка";
    }


}

int zram_config()
{

    const char* options[] = {
        "yes",
        "no",
    };
    int count = 2;
    int highlight = 0;
    int zram = -1;
    int c;

    while (true) {
        clear();
        mvprintw(0, 0, "=== Config zram ===");

        for (int i = 0; i < 2; i++) {
            if (i == highlight) {
                attron(A_REVERSE); // Выделение инверсией
                mvprintw(2 + i, 2, "> %s", options[i]);
                attroff(A_REVERSE);
            } else {
                mvprintw(2 + i, 4, "%s", options[i]);
            }
        }

        refresh();
        c = getch();

        if (c == KEY_UP) {
            if (highlight > 0) highlight--;
        } else if (c == KEY_DOWN) {
            if (highlight < count - 1) highlight++; // Защита от выхода за границы
        } else if (c == 10 || c == KEY_ENTER) {
            zram = highlight + 1;
            break;
        }
    }

    if (zram == 1) {
        const char* init_path = "/mnt/etc/init.d/zram";
        ofstream out_zram(init_path);
        if (out_zram.is_open()) {
            out_zram << "#!/sbin/openrc-run\n";
            out_zram << "start() {\n";
            out_zram << "    ebegin \"Starting zram\"\n";
            out_zram << "    modprobe zram num_devices=1\n";
            out_zram << "    echo lz4 > /sys/block/zram0/comp_algorithm\n";
            out_zram << "    echo $(( $(grep MemTotal /proc/meminfo | awk '{print $2}') * 3 / 4 ))K > /sys/block/zram0/disksize\n";
            out_zram << "    mkswap /dev/zram0\n";
            out_zram << "    swapon /dev/zram0 -p 100\n";
            out_zram << "    eendzram_config(); $?\n";
            out_zram << "}\n";
            out_zram.close();
        } else {
            cerr << "ERR: zram init error";
        }
        system("chmod +x /mnt/etc/init.d/zram");
        system("chroot /mnt rc-update add zram sysinit");
        cerr << ("INFO: zram is add Autostart") << endl;
    } else {
        cerr << "INFO: zram off" << endl;
    }
    return 0;
}

void enable_services_openrc() {
    vector<pair<string, string>> services = {
        {"udev", "sysinit"},
        {"dbus", "boot"},
        {"elogind", "boot"},
        {"acpid", "default"},
        {"NetworkManager", "default"},
        {"chrony", "default"}
    };
    for (const auto& [name, level] : services) { // C++17 Structured Binding (красота!)
        string cmd = "chroot /mnt rc-update add " + name + " " + level + " 2>/dev/null";
        if (system(cmd.c_str()) != 0) {
            cerr << "[WARN] Failed: " << name << " (" << level << ")" << endl;
        }
    }
}



int main() {
    system("clear");
    bindtextdomain("quasarinstall", "/usr/local/sdk/global/locale");
    textdomain("quasarinstall");
    setlocale(LC_ALL, "");

    cout << ("Install base system") << endl;
    setup_ncurses();

    install_base_openrc();
    show_kernel_menu();
    int kernel_id = show_kernel_menu();

    cleanup_ncurses();

    // Дальше логика установки
    if (kernel_id == 1) {
        system("basestrap /mnt linux-zen linux-zen-headers");
    } else if (kernel_id == 2) {
        system("basestrap /mnt linux-lts linux-lts-headers");
    } else if (kernel_id == 3) {
        system("basestrap /mnt linux linux-headers");
    } else {
        cerr << ("ERR: Kernel is not found");
    }

    prepart();
    setup_ncurses();
    zram_config();

    system_settings();
    enable_services_openrc();
    cleanup_ncurses();


    string url = "https://github.com/QuasarFoks/QuasarLinux/releases/download/REV-1.2-image/SYSTEM.zip";
    string output_file = "QuasarLinux.tar.bz2";
    string cmd = "wget -O \"" + output_file + "\" \"" + url + "\"";
    int status = system(cmd.c_str());
    if (status != 0) {
        cerr << "CRITICAL ERR: Failed to download image! (Code: " << status << ")" << endl;
        // Тут можно добавить удаление битого файла
        remove(output_file.c_str());
    }
    system("bsdunzip x SYSTEM.zip -C /mnt");


    cerr << ">>> Install base system complete." << endl;


    return 0;

}
