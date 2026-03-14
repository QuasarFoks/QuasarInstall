#include <iostream>
#include <cstdlib>
#include <string>
#include <fstream>
#include <ncurses.h>
#include <sys/wait.h>
#include <libintl.h>
#include <filesystem>
#include <vector>
#include <cstdio>
#include <memory>
#include <array>


using namespace std;
void prepart()
{
    using namespace std;
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

bool check_efi()
{
    namespace fs = std::filesystem;
    if (fs::exists("/sys/firmware/efi")) {
        return true;
    } else {
        return false;
    }
}
using namespace std;
namespace fs = std::filesystem;

// ============================================================================
// ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ (Должны быть объявлены до использования)
// ============================================================================

// 1. Получить устройство точки монтирования (findmnt)
string get_mount_source(const string& mountpoint) {
    array<char, 256> buffer;
    string result;
    string cmd = "findmnt -n -o SOURCE " + mountpoint + " 2>/dev/null";

    unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd.c_str(), "r"), pclose);
    if (!pipe) return "";

    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
        result += buffer.data();
    }
    if (!result.empty() && result.back() == '\n') result.pop_back();
    return result;
}

// 2. Получить родительский диск (lsblk)
string get_parent_disk(const string& partition) {
    array<char, 256> buffer;
    string result;
    string cmd = "lsblk -no PKNAME " + partition + " 2>/dev/null";

    unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd.c_str(), "r"), pclose);
    if (!pipe) return "";

    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
        result += buffer.data();
    }
    if (!result.empty() && result.back() == '\n') result.pop_back();

    if (!result.empty()) return "/dev/" + result;
    return "";
}

// 3. Получить UUID (blkid)
string get_root_uuid(const string& root_device) {
    array<char, 128> buffer;
    string result;
    string cmd = "blkid -s UUID -o value " + root_device + " 2>/dev/null";

    unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd.c_str(), "r"), pclose);
    if (!pipe) return "";

    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
        result += buffer.data();
    }
    if (!result.empty() && result.back() == '\n') result.pop_back();
    return result;
}

// 4. Найти ядро
string find_kernel() {
    const string boot_path = "/mnt/boot";
    if (!fs::exists(boot_path)) return "";

    for (const auto& entry : fs::directory_iterator(boot_path)) {
        string filename = entry.path().filename().string();
        if (filename.find("vmlinuz-") == 0) {
            return filename.substr(8);
        }
    }
    return "";
}



//=============================================================================
//                      Настройка Grub общая
//=============================================================================


// 5. Настройка GRUB_DISTRIBUTOR
void configure_grub_distributor() {
    const string path = "/mnt/etc/default/grub";
    const string target_var = "GRUB_DISTRIBUTOR=";
    const string new_value = "GRUB_DISTRIBUTOR=\"QuasarLinux\"";

    if (!fs::exists(path)) {
        ofstream out(path);
        if (out.is_open()) { out << new_value << endl; out.close(); }
        return;
    }

    ifstream in(path);
    vector<string> lines;
    string line;
    bool found = false;

    while (getline(in, line)) {
        if (line.find(target_var) == 0) {
            lines.push_back(new_value);
            found = true;
        } else {
            lines.push_back(line);
        }
    }
    in.close();

    if (!found) lines.push_back(new_value);

    ofstream out(path);
    if (out.is_open()) {
        for (const auto& l : lines) out << l << "\n";
        out.close();
    }
}


//=======================================================================================================
//                                    efi настройка
//=======================================================================================================



void install_efistub(const string& disk, int efi_part_num, const string& root_dev) {
    cout << ">>> Installing EFISTUB Bootloader..." << endl;

    string kernel = find_kernel();
    if (kernel.empty()) {
        cerr << "CRITICAL: Kernel not found!" << endl;
        return;
    }
    cout << "[OK] Kernel: " << kernel << endl;

    string vmlinuz_src = "/mnt/boot/vmlinuz-" + kernel;
    string initrd_src  = "/mnt/boot/initramfs-" + kernel + ".img";
    if (!fs::exists(initrd_src)) initrd_src = "/mnt/boot/initrd-" + kernel + ".img";

    string esp_path = "/mnt/boot/efi";
    if (!fs::exists(esp_path)) {
        cerr << "CRITICAL: ESP not mounted at /mnt/boot/efi" << endl;
        return;
    }

    string vmlinuz_dst = esp_path + "/vmlinuz-" + kernel + ".efi";
    string initrd_dst  = esp_path + "/initramfs-" + kernel + ".img";

    try {
        fs::copy_file(vmlinuz_src, vmlinuz_dst, fs::copy_options::overwrite_existing);
        if (fs::exists(initrd_src)) {
            fs::copy_file(initrd_src, initrd_dst, fs::copy_options::overwrite_existing);
        }
        cout << "[OK] Files copied to ESP." << endl;
    } catch (const exception& e) {
        cerr << "CRITICAL: Copy failed: " << e.what() << endl;
        return;
    }

    string uuid = get_root_uuid(root_dev);
    if (uuid.empty()) {
        cerr << "CRITICAL: Cannot get UUID for " << root_dev << endl;
        return;
    }

    string loader = "\\vmlinuz-" + kernel + ".efi";
    string initrd_name = "initramfs-" + kernel + ".img";
    string cmdline = "root=UUID=" + uuid + " rw initrd=\\\\" + initrd_name;

    // Номер раздела (efi_part_num) уже передан извне
    string cmd = "chroot /mnt efibootmgr -c -d " + disk +
    " -p " + to_string(efi_part_num) +
    " -L \"QuasarLinux\" " +
    " -l \"" + loader + "\" " +
    " -u \"" + cmdline + "\"";

    cout << ">>> Executing: " << cmd << endl;

    if (system(cmd.c_str()) != 0) {
        cerr << "WARN: efibootmgr returned error code." << endl;
    } else {
        cout << "[OK] EFISTUB entry created successfully." << endl;
    }
}


void efi_bootloader_install()
{
    const char* options[] = {
        "grub",
        "efistub",
        "refind",
    };
    int count = 3;
    int highlight = 0;
    int bootloader = -1;
    int c;

    while (true) {
        clear();
        mvprintw(0, 0, "=== Config bootloader ===");

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
            if (highlight < count - 1) highlight++; // Защита от выхода за границы
        } else if (c == 10 || c == KEY_ENTER) {
            bootloader = highlight + 1;
            break;
        }
    }
    if (bootloader == 1) {
        system("fast-chroot /mnt pacman -S grub os-prober efibootmgr --noconfirm");
        system("fast-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --removable --recheck");
        configure_grub_distributor();
        system("fast-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg");
    } else if (bootloader == 2) {
        system("chroot /mnt pacman -S efibootmgr --noconfirm");
        // ПЕРЕДАЕМ все нужные данные в функцию
        string root_dev = get_mount_source("/mnt");
        string disk_dev = get_parent_disk(root_dev);
        int efi_part_num = 1;
        install_efistub(disk_dev, efi_part_num, root_dev);
    } else if (bootloader == 3) {
        // --- rEFInd ---
        cout << ">>> Installing rEFInd..." << endl;
        system("chroot /mnt pacman -S refind efibootmgr --noconfirm");
        system("chroot /mnt refind-install");
        cout << "[INFO] rEFInd installed." << endl;
        // Примечание: rEFInd обычно сам находит ядра, но можно добавить настройку
    } else {
        cerr << "ERR: Invalid choice." << endl;
    }


}
//==========================================================================================
//                          Legacy настройка
//==========================================================================================

void install_syslinux(const string& disk_dev, const string& root_uuid) {
    cout << ">>> Setting up Syslinux..." << endl;

    // 1. Поиск ядра
    string kernel = find_kernel();
    if (kernel.empty()) {
        cerr << "CRITICAL: Kernel not found!" << endl;
        return;
    }
    cout << "[OK] Kernel: " << kernel << endl;

    // 2. Определение загрузочного раздела и его номера
    // Аналог: BOOT_PART=$(findmnt -n -o SOURCE /mnt/boot ...)
    string boot_part = get_mount_source("/mnt/boot");
    if (boot_part.empty()) {
        boot_part = get_mount_source("/mnt"); // Fallback к корню
    }

    if (boot_part.empty()) {
        cerr << "CRITICAL: Cannot determine boot partition!" << endl;
        return;
    }

    // Извлекаем номер раздела (аналог sed 's/.*[^0-9]\([0-9]\+\)$/\1/')
    // Ищем последнюю цифру в строке (например, /dev/sda1 -> 1)
    string boot_number = "";
    for (auto it = boot_part.rbegin(); it != boot_part.rend(); ++it) {
        if (isdigit(*it)) {
            boot_number = *it + boot_number;
        } else {
            break;
        }
    }

    if (boot_number.empty()) {
        cerr << "CRITICAL: Cannot parse partition number from " << boot_part << endl;
        return;
    }
    cout << "[OK] Boot Partition: " << boot_part << " (Number: " << boot_number << ")" << endl;

    // 3. Включаем флаг boot через parted
    string parted_cmd = "parted " + disk_dev + " set " + boot_number + " boot on";
    system(parted_cmd.c_str());

    // 4. Установка пакета
    cout << ">>> Installing syslinux package..." << endl;
    if (system("chroot /mnt pacman -S syslinux --noconfirm") != 0) {
        cerr << "ERROR: Failed to install syslinux!" << endl;
        return;
    }

    // 5. Подготовка директории и установка загрузчика
    system("mkdir -p /mnt/boot/syslinux");
    if (system("chroot /mnt extlinux --install /boot/syslinux") != 0) {
        cerr << "ERROR: extlinux --install failed!" << endl;
        return;
    }

    // 6. Копирование модулей .c32
    system("cp /mnt/usr/lib/syslinux/bios/*.c32 /mnt/boot/syslinux/");

    // 7. Запись MBR (dd)
    string mbr_cmd = "dd if=/mnt/usr/lib/syslinux/bios/mbr.bin of=" + disk_dev + " bs=440 count=1 conv=notrunc";
    cout << ">>> Writing MBR to " << disk_dev << "..." << endl;
    if (system(mbr_cmd.c_str()) != 0) {
        cerr << "ERROR: Failed to write MBR!" << endl;
        return;
    }

    // 8. Генерация syslinux.cfg
    string cfg_path = "/mnt/boot/syslinux/syslinux.cfg";
    ofstream cfg(cfg_path);

    if (cfg.is_open()) {
        cfg << "DEFAULT QuasarLinux\n";
        cfg << "PROMPT 0\n";
        cfg << "TIMEOUT 50\n\n";
        cfg << "LABEL QuasarLinux\n";
        cfg << "    KERNEL /vmlinuz-" << kernel << "\n";
        cfg << "    APPEND root=UUID=" << root_uuid << " rw\n";
        cfg << "    INITRD /initramfs-" << kernel << ".img\n";
        cfg.close();
        cout << "[OK] Syslinux configuration created." << endl;
    } else {
        cerr << "CRITICAL: Cannot create syslinux.cfg!" << endl;
    }

    cout << ">>> Syslinux installation complete." << endl;
}

void legacy_bootloader_install()
{
    const char* options[] = {
        "grub",
        "efistub",
        "refind",
    };
    int count = 2;
    int highlight = 0;
    int bootloader = -1;
    int c;

    while (true) {
        clear();
        mvprintw(0, 0, "=== Config bootloader ===");

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
            bootloader = highlight + 1;
            break;
        }
    }
    if (bootloader == 1 ) {
        system("fast-chroot /mnt pacman -S grub os-prober efibootmgr --noconfirm");
        cout << ">>> Installing BIOS Bootloader..." << endl;

        // 1. Получаем диск (аналог твоего $DISK)
        string root_dev = get_mount_source("/mnt");
        string disk_dev = get_parent_disk(root_dev); // Вернет "/dev/sda" или "/dev/nvme0n1"

        if (disk_dev.empty()) {
            cerr << "CRITICAL: Cannot detect disk for BIOS install!" << endl;
            return;
        }

        cout << "[OK] Target Disk: " << disk_dev << endl;

        // 2. Установка GRUB для BIOS
        // Команда: fast-chroot /mnt grub-install --target=i386-pc --boot-directory=/boot --recheck "${DISK}"
        string cmd = "fast-chroot /mnt grub-install --target=i386-pc "
        "--boot-directory=/boot --recheck \"" + disk_dev + "\"";

        if (system(cmd.c_str()) != 0) {
            cerr << "ERROR: BIOS GRUB installation failed!" << endl;
            return;
        }

        configure_grub_distributor(); // она общая
        system("fast-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg");
        cout << "[OK] GRUB BIOS installed on " << disk_dev << endl;
    } else if (bootloader == 2) {
        string root_dev = get_mount_source("/mnt");
        string disk_dev = get_parent_disk(root_dev);
        string root_uuid = get_root_uuid(root_dev);

        install_syslinux(disk_dev, root_uuid);
    } else {
        cerr << ("ERR: uncknow choise\n") << endl;
    }
}

int main()
{
    prepart();
    setup_ncurses();
    bool efi_checker = check_efi();
    if ( efi_checker == true ) {
        efi_bootloader_install();
    }
    else {
        legacy_bootloader_install();
    }

    return 0;

}
