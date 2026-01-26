#
#   QuasarInstall 3.0 
#
#   QuasarLinux_SE v0.1
#



import os 
import subprocess
import sys


def parted(*args):
    """Выполняет parted с глобальной переменной DISK."""
    cmd = ["parted", "-s", DISK] + list(args)
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Ошибка parted: {result.stderr}", file=sys.stderr)
        sys.exit(1)


def parted_auto():
    global DISK, PARTITION_TABLE
    
    # --- Выбор диска ---
    disks_raw = subprocess.run(
        ["lsblk", "-d", "-n", "-o", "NAME,TYPE", "--include", "3,8,22"],
        capture_output=True, text=True
    ).stdout.strip().splitlines()

    disks = [f"/dev/{line.split()[0]}" for line in disks_raw if line.split()[1] == "disk"]

    if not disks:
        print("Не найдено подходящих дисков.", file=sys.stderr)
        sys.exit(1)

    print("Доступные диски:")
    for i, d in enumerate(disks, 1):
        size = subprocess.run(["lsblk", "-n", "-o", "SIZE", d], capture_output=True, text=True).stdout.strip()
        print(f"  {i}) {d} ({size})")

    try:
        choice = int(input("\nВыберите номер диска для разметки: ")) - 1
        DISK = disks[choice]
    except (ValueError, IndexError):
        print("Неверный выбор.", file=sys.stderr)
        sys.exit(1)

    # --- Выбор таблицы разделов ---
    while True:
        mode = input("\nВыберите тип таблицы разделов:\n  1) GPT (UEFI)\n  2) MBR (BIOS)\nВаш выбор (1/2): ").strip()
        if mode == "1":
            PARTITION_TABLE = "gpt"
            break
        elif mode == "2":
            PARTITION_TABLE = "msdos"
            break
        else:
            print("Введите 1 или 2.")

    print(f"\n⚠️  ВНИМАНИЕ: весь диск {DISK} будет перезаписан!")
    confirm = input("Подтвердите действие (yes/no): ").strip().lower()
    if confirm != "yes":
        print("Отмена.")
        sys.exit(0)

    if not os.path.exists(DISK):
        print(f"Диск {DISK} не существует", file=sys.stderr)
        sys.exit(1)

    # Очистка
    subprocess.run(["sgdisk", "--zap-all", DISK], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(["dd", "if=/dev/zero", f"of={DISK}", "bs=1M", "count=10"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # Создание таблицы
    parted("mklabel", PARTITION_TABLE)

    if PARTITION_TABLE == "gpt":
        # GPT: EFI + swap + root
        parted("mkpart", "ESP", "fat32", "1MiB", "513MiB")
        parted("set", "1", "esp", "on")
        parted("mkpart", "swap", "linux-swap", "513MiB", "4609MiB")
        parted("mkpart", "root", "ext4", "4609MiB", "100%")
    else:
        # MBR: boot (загрузочный) + swap + root
        parted("mkpart", "primary", "ext4", "1MiB", "513MiB")
        parted("set", "1", "boot", "on")
        parted("mkpart", "primary", "linux-swap", "513MiB", "4609MiB")
        parted("mkpart", "primary", "ext4", "4609MiB", "100%")

    subprocess.run(["partprobe", DISK], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print(f"\n✅ Разметка завершена на {DISK} ({PARTITION_TABLE.upper()})")




def base_install():
    os.system("python /installer/core/base_install.py")

def packs_install():
    package = (
        'ql-utils'
        'systemd-rc'
        'qbox'
        'fastfetch'
        )

