import os
import gettext
import subprocess
RESET = "\033[0m"
RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
BLUE = "\033[34m"
MAGENTA = "\033[35m"
CYAN = "\033[36m"
BOLD_BRIGHT_WHITE = "\033[1;97m"
src = "/installer/backend"
gettext.bindtextdomain('installer', '/usr/local/sdk/global/locale')
gettext.textdomain('installer')
_ = gettext.gettext

UEFI_MODE = 0
if os.path.isdir('/sys/firmware/efi'):
    UEFI_MODE = 1
LUKS_MODE = 0

# Создание пользователя
def UserAdd:
    os.system("clear")
    ptint(_("Create root password"))
    subprocess.run(["chroot", "/mnt","passwd"])
    print(_("Create new user? [y/n] "))
    x = input()
    if x == "y" or x == "Y":
        username = input("username: ")
        if username == "root"
            print(_("You cannot create a user named root"))
        subprocess.run([src + "userscfg", username])
    else:
        print(_("skip"))
    """
    path = /mnt/old.os/linux/home/
    if os.path.isdir(path):
        ptint(_("Transfer the data of a previous user? [Y/n]: "))
        x = input()
        if x == "Y" or x == "y":
            subprocess.run(["rsync", "/mnt/old.os/linux/home/", "/mnt/home"])
        else:
            print(_(("skip")))
    """

def AudioInstall():

def WineInstall():

def WebBrouser():

def RegionSet():

def OfficeSet():

def PartManager():
    os.system("clear")
    os.system("lsblk -d -n -o NAME,SIZE,MODEL")
    print(_("Select disk for partitioning [sda/vda]: "))
    DISK_NAME = input(": ")
    DISK = "/dev/" + DISK_NAME

    menu_disk = [
        "1", _( "Auto Mode"),
        "2", _( "Manual Mode"),
        "3", _( "OS Change (Linux-only)"),
        "4", _( "Exit")
        ]
    cmd = [
        "dialog", "--title", _("Partitioning"), "--menu",  _("Select mode:"), "15", "60", "4"
        ] + menu_disk
    result = subprocess.run(cmd, stderr=subprocess.PIPE, text=True)
    if result.returncode == 0:
        choice = result.stderr.strip()
        if choice == 1:
            result = subprocess.run(["fdisk", "-l", DISK], capture_output=True, text=True)
            lines = result.stdout.split('\n')

            # Найти строку с диском
            for line in lines:
                if f"Disk {DISK}:" in line:
                    # Пример: "Disk /dev/sda: 238.5 GiB, 256060514304 bytes, 500118192 sectors"
                    parts = line.split()
                    size_str = parts[2]  # "238.5"
                    size_unit = parts[3]  # "GiB"
                    DISK_SIZE = int(float(size_str))  # 238
                    break

            if DISK_SIZE < 10:
                print(_("Disk is small"))

            subprocess.run(["sgdisk", "-Z", DISK, "2>/dev/null", "||", "dd", "if=/dev/zero", "of=" + DISK, "bs=1M", "count=100"])

            if UEFI_MODE == 1:
                subprocess.run(["parted", "-s", DISK, "mklabel", "gpt"])
                subprocess.run(["parted", "-s", DISK, "mkpart", "primary", "fat32", "1MiB", "513MiB"])
                subprocess.run(["parted", "-s", DISK, "set", "1", "esp", "on"])
                BOOT_PART = f"{DISK}1"
                BOOT_DIR = "/mnt/boot/efi"
            else:
                subprocess.run(["parted", "-s", DISK, "mklabel", "msdos"])
                subprocess.run(["parted", "-s", DISK, "mkpart", "primary", "1MiB", "513MiB"])
                subprocess.run(["parted", capture_output=True"-s", DISK, "set", "1", "boot", "on"])
                BOOT_PART = f"{DISK}1"
                BOOT_DIR = "/mnt/boot"
            subprocess.run(["parted", "-s", DISK, "mkpart", "primary", "513MiB", "4.5GiB"])
            SWAP_PART = f"{DISK}2"

            subprocess.run(["mkswap", SWAP_PART])
            subprocess.run(["swapon", SWAP_PART])


            subprocess.run(["parted", "-s", DISK, "mkpart", "primary", "4.5GiB", "100%"])
            ROOT_PART = f"{DISK}3"
            subprocess.run(["mkfs.ext4", "-F", ROOT_PART])


            ### Монтирование систем
            subprocess.run(["mount", ROOT_PART, "/mnt"])
            subprocess.run(["mkdir", "-p", BOOT_DIR])
            subprocess.run(["mount", BOOT_PART, BOOT_DIR])
    elif choice == 2:
        # 1. Запуск cfdisk
        subprocess.run(["cfdisk", DISK])
        # 2. Запрос root-раздела (после ручной разметки)
        root_part = input(_("Enter ROOT partition: "))
        root_part = f"/dev/{root_part}"

        # 3. Шифрование root (опционально через dialog)
        luks_cmd = [
            "dialog", "--title", _("Encryption"),
            "--menu", _("Encrypt root?"), "15", "60", "2",
            "1", _("Yes"), "2", _("No")
        ]
        result = subprocess.run(luks_cmd, stderr=subprocess.PIPE, text=True)
        luks = result.stderr.strip()

        if luks == "1":
            subprocess.run(["cryptsetup", "luksFormat", "--type", "luks2", root_part])
            subprocess.run(["cryptsetup", "luksOpen", root_part, "QuasarRoot"])
            root_part_final = "/dev/mapper/QuasarRoot"
            LUKS_MODE = 1
        else:
            root_part_final = root_part
            LUKS_MODE = 0

        # 4. Выбор файловой системы
        fs_cmd = [
            "dialog", "--title", _("Filesystem"),
            "--menu", _("Choose FS:"), "15", "60", "3",
            "1", "EXT4", "2", "BTRFS", "3", "XFS"
        ]
        result = subprocess.run(fs_cmd, stderr=subprocess.PIPE, text=True)
        fs = result.stderr.strip()

        if fs == "1":
            subprocess.run(["mkfs.ext4", "-F", root_part_final])
        elif fs == "2":
            subprocess.run(["mkfs.btrfs", "-f", root_part_final])
        elif fs == "3":
            subprocess.run(["mkfs.xfs", "-f", root_part_final])

        # 5. Монтирование root
        os.makedirs("/mnt", exist_ok=True)
        subprocess.run(["mount", root_part_final, "/mnt"])

        # 6. Загрузочный раздел в зависимости от UEFI
        if UEFI_MODE == 1:
            boot_part = input(_("Enter EFI partition: "))
            boot_part = f"/dev/{boot_part}"
            os.makedirs("/mnt/boot/efi", exist_ok=True)
            subprocess.run(["mkfs.fat", "-F32", boot_part])
            subprocess.run(["mount", boot_part, "/mnt/boot/efi"])
        else:
            boot_part = input(_("Enter BOOT partition: "))
            boot_part = f"/dev/{boot_part}"
            os.makedirs("/mnt/boot", exist_ok=True)
            subprocess.run(["mkfs.ext2", "-F", boot_part])
            subprocess.run(["mount", boot_part, "/mnt/boot"])
    elif choice == "3":
        print(_("Using partmanager"))
        subprocess.run([src + "partmanager", "auto", "switch-os", "Linux"])



def MainMenu():
    menu_items = [
        "1", _("express"),
        "2", _("partition"),
        "3", _("install base system"),
        "4", _("Install extra package"),
        "5", _("User settings"),
        "6", _("Install bootloader"),
        "7", _("audio"),
        "8", _("wine"),
        "9", _("web browser"),
        "10", _("region"),
        "11", _("office"),
        "12", _("exit")
    ]

    cmd = [
        "dialog", "--title", _("Quasar-install"),
        "--menu", _("Select option"), "15", "70", "7"
    ] + menu_items

    result = subprocess.run(cmd, stderr=subprocess.PIPE, text=True)

    if result.returncode == 0:
        choice = result.stderr.strip()  # "1", "2", "3"...

        if choice == "1":  # express установка

            print(f"{BOLD_BRIGHT_WHITE}DEBUG{RESET} Start install base")
            PartManager()
            subprocess.run([src + "/basepack", "base", "openrc"])

        elif choice == "2":
            PartManager()
        elif choice == "3":
            subprocess.run([src + "/basepack", "openrc"])
        elif choice == "4":
            subprocess.run([src + "/inst_pack"])
        elif choice == "5":
            UserAdd()
        elif choice == "6":
            BootLoader()
        elif choice == "7":
            AudioInstall()
        elif choice == "8":
            WineInstall()
        elif choice == "9":
            WebBrouser()
        elif choice == "10"
            RegionSet()
        elif choice == "11"
            OfficeSet()
        elif choice == "12":
            print(_("Exiting..."))
            sys.exit(0)

if __name__ == "__main__":
    MainMenu()

