#!/usr/bin/env python3
import os
import sys
import json
import subprocess
import re
import pwd
import gettext

# --- i18n ---
gettext.bindtextdomain('installer', '/usr/local/sdk/global/locale')
gettext.textdomain('installer')
_ = gettext.gettext

CONFIG_PATH = "/usr/local/sdk/configs/generic/default.json"

# --- Dialog Helpers ---
def dialog_std(args: list, h="10", w="60"):
    """Run dialog, return stdout stripped or None on cancel."""
    cmd = ["dialog", "--stdout", "--title", "QuasarInstall", "--backtitle", "v3.0"] + args + [h, w]
    proc = subprocess.run(cmd, text=True, capture_output=True)
    return proc.stdout.strip() if proc.returncode == 0 else None

def dialog_password(prompt: str, h="10", w="50"):
    """Return password from stderr or None."""
    cmd = ["dialog", "--insecure", "--passwordbox", "--title", "QuasarInstall", prompt, h, w]
    proc = subprocess.run(cmd, text=True, capture_output=True)
    return proc.stderr.strip() if proc.returncode == 0 else None

# --- Collectors ---
def get_edition():
    return dialog_std(["--menu", _("Select Edition:"), "10", "50", "4",
                       "1", _("REV (Custom)"), "2", _("SE (Stable)"), "3", _("PRO (Enterprise)"), "4", _("NOVA (v4)")])

def get_init():
    return dialog_std(["--menu", _("Init System:"), "10", "50", "2", "1", "openrc", "2", "systemd"])

def get_kernel():
    return dialog_std(["--menu", _("Kernel:"), "10", "50", "3", "1", "linux", "2", "linux-lts", "3", "linux-zen"])

def get_zram():
    return dialog_std(["--yesno", _("Enable zram?"), "6", "40"]) == "0"

def get_disk():
    out = subprocess.run(["lsblk", "-ndpo", "NAME,SIZE,MODEL", "--output", "NAME,SIZE,MODEL"], capture_output=True, text=True).stdout
    items = []
    for line in out.strip().split("\n"):
        if not line or "loop" in line or "sr" in line: continue
        parts = line.split(maxsplit=2)
        items.extend([parts[0], f"{parts[1]} {parts[2]}"])
    return dialog_std(["--menu", _("Select Disk:"), "15", "60", str(len(items)//2)] + items) if items else None

def get_part_type():
    return dialog_std(["--menu", _("Partition Type:"), "10", "50", "3",
                       "1", "auto", "2", "replacement", "3", "custom"])

def get_custom_partition():
    boot = dialog_std(["--inputbox", _("Boot partition (e.g. /dev/sda1):"), "8", "40", "/dev/sdX1"])
    root = dialog_std(["--inputbox", _("Root partition (e.g. /dev/sda2):"), "8", "40", "/dev/sdX2"])
    rootfs = dialog_std(["--menu", _("Root FS:"), "10", "50", "3", "1", "ext4", "2", "btrfs", "3", "xfs"])
    swap = dialog_std(["--yesno", _("Create swap?"), "6", "40"]) == "0"
    luks = dialog_std(["--yesno", _("Enable LUKS?"), "6", "40"]) == "0"
    return {"boot": boot, "root": root, "rootfs": rootfs, "swap": swap, "luks": luks}

def get_bootloader(firm: str):
    if firm == "uefi":
        return dialog_std(["--menu", _("UEFI Bootloader:"), "10", "50", "3", "1", "grub", "2", "efistub", "3", "refind"])
    return dialog_std(["--menu", _("Legacy Bootloader:"), "10", "50", "2", "1", "grub", "2", "syslinux"])

def get_username():
    while True:
        name = dialog_std(["--inputbox", _("Username:"), "8", "40", "user"])
        if not name: return None
        if name.lower() in ["root","admin","daemon","nobody","systemd","bin","sys","adm","sync","shutdown","halt","mail","news","uucp","operator","man","git","www-data","dbus"]:
            dialog_std(["--msgbox", _("Reserved system name!"), "6", "40"])
            continue
        if not re.match(r'^[a-z_][a-z0-9_-]*$', name):
            dialog_std(["--msgbox", _("Invalid characters. Use a-z, 0-9, _, -"), "8", "40"])
            continue
        try:
            pwd.getpwnam(name)
            dialog_std(["--msgbox", _("User already exists!"), "6", "40"])
            continue
        except KeyError:
            pass
        pw1 = dialog_password(_("Password for {}:".format(name)))
        pw2 = dialog_password(_("Confirm password:"))
        if not pw1 or pw1 != pw2:
            dialog_std(["--msgbox", _("Passwords do not match or empty."), "6", "40"])
            continue
        return name, pw1

def get_sudo(username: str):
    return dialog_std(["--yesno", _("Add '{}' to sudo/wheel?".format(username)), "6", "40"]) == "0"

def get_region():
    return dialog_std(["--menu", _("Region/Mirror:"), "12", "50", "4", "1", "Moscow", "2", "London", "3", "NewYork", "4", "Tokyo"])

def get_userland():
    res = {}
    res["desktop"] = dialog_std(["--menu", _("Desktop Environment:"), "10", "50", "3", "1", "plasma", "2", "gnome", "3", "none"]) or "none"
    res["audio"] = dialog_std(["--menu", _("Audio Server:"), "10", "50", "2", "1", "pipewire", "2", "pulseaudio"]) or "pipewire"
    res["browser"] = dialog_std(["--menu", _("Browser:"), "10", "50", "3", "1", "firefox", "2", "chromium", "3", "none"]) or "none"
    res["wine"] = dialog_std(["--menu", _("Wine/Compat:"), "10", "50", "3", "1", "portproton", "2", "wine", "3", "none"]) or "none"
    res["android_support"] = dialog_std(["--yesno", _("Android support (Waydroid)?"), "6", "40"]) == "0"
    res["office"] = dialog_std(["--menu", _("Office Suite:"), "10", "50", "3", "1", "libreoffice", "2", "wps", "3", "none"]) or "none"
    return res

# --- Main ---
def main():
    # Welcome
    dialog_std(["--msgbox", _("Welcome to QuasarInstall v3.0. Prepare to configure."), "8", "50"])

    qr_github = "/installer/qr_cods/github-wiki.txt"
    qr_gitverse = "/installer/qr_cods/gitverse-mirror-wiki.txt"
    qr = ["paste", qr_github, qr_gitverse]
    subprocess.run(qr)
    print("\tGithub wiki\t\t\t\tGitverse mirror wiki")

    os.system("clear")

    # Firmware detection
    firm = "uefi" if os.path.isdir('/sys/firmware/efi') else "legacy"

    # Collect data
    edition_map = {"1": "REV", "2": "SE", "3": "PRO", "4": "NOVA"}
    init_map = {"1": "openrc", "2": "systemd"}
    kernel_map = {"1": "linux", "2": "linux-lts", "3": "linux-zen"}

    edition = edition_map.get(get_edition(), "REV")
    init = init_map.get(get_init(), "openrc")
    kernel = kernel_map.get(get_kernel(), "linux-lts")
    zram = get_zram()
    disk = get_disk() or "/dev/sda"
    part_type_map = {"1": "auto", "2": "replacement", "3": "custom"}
    type_part = part_type_map.get(get_part_type(), "auto")

    part_preset = []
    if type_part == "custom":
        pp = get_custom_partition()
        if pp:
            part_preset.append(pp)

    bootloader = get_bootloader(firm)
    if not bootloader: bootloader = "grub"

    user_data = get_username()
    username = user_data[0] if user_data else "tester"
    sudo_support = get_sudo(username) if user_data else True
    region = get_region() or "Moscow"
    ul = get_userland()

    # Build config
    config = {
        "revision": edition,
        "edition": edition,
        "init": init,
        "kernel": kernel,
        "zram": zram,
        "type_part": type_part,
        "disk": disk,
        "part_preset": part_preset,
        "bootloader": bootloader,
        "firm": firm,
        "username": username,
        "sudo_support": sudo_support,
        "region": region,
        "desktop": ul["desktop"],
        "audio": ul["audio"],
        "browser": ul["browser"],
        "wine": ul["wine"],
        "android_support": ul["android_support"],
        "office": ul["office"],
        "system_preset": [{"systemd_command_support": init == "systemd", "DEBAndRPM_support": False}]
    }

    os.makedirs(os.path.dirname(CONFIG_PATH), exist_ok=True)
    with open(CONFIG_PATH, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=4)

    dialog_std(["--msgbox", _("Config saved to:\n{}").format(CONFIG_PATH), "8", "60"])
    print(f"Config written to {CONFIG_PATH}")
    sys.exit(0)

if __name__ == "__main__":
    main()
