#!/usr/bin/env python3
import json
import subprocess
import sys
import os

CONFIG_PATH = "/usr/local/sdk/configs/generic/default.json"
DEBUG_ENABLED = False  # "работает всегда, но не применяется (пока что)"

def log(level: str, module: str, msg: str):
    if level == "DEBUG" and not DEBUG_ENABLED:
        return
    print(f"{level}::{module}::{msg}")

def load_config(path: str) -> dict:
    try:
        with open(path, "r", encoding="utf-8") as f:
            raw = json.load(f)

        # Нормализация: чистим пробелы в ключах и строковых значениях
        def strip_obj(obj):
            if isinstance(obj, dict):
                return {k.strip(): strip_obj(v) for k, v in obj.items()}
            elif isinstance(obj, list):
                return [strip_obj(i) for i in obj]
            elif isinstance(obj, str):
                return obj.strip()
            return obj

        log("INFO", "parser", "Config loaded and normalized")
        return strip_obj(raw)
    except Exception as e:
        log("ERR", "parser", f"Failed to load config: {e}")
        sys.exit(1)

def run_module(cmd: list, module_name: str):
    log("DEBUG", module_name, f"CMD: {' '.join(map(str, cmd))}")
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        log("INFO", module_name, "Completed successfully")
        if result.stderr.strip():
            log("WARN", module_name, result.stderr.strip())
        return True
    except subprocess.CalledProcessError as e:
        log("ERR", module_name, f"Exit {e.returncode}. {e.stderr.strip()}")
        return False
    except FileNotFoundError:
        log("ERR", module_name, f"Binary not found: {cmd[0]}")
        return False

def main():
    cfg = load_config(CONFIG_PATH)

    # 1. Basepack
    revision = cfg.get("revision", "REV")
    init = cfg.get("init", "openrc")
    kernel = cfg.get("kernel", "linux")
    zram_flag = "zram-on" if cfg.get("zram") else "zram-off"
    run_module(["basepack", revision, init, kernel, zram_flag], "basepack")

    # 2. Partmanager
    type_part = cfg.get("type_part", "auto")
    disk = cfg.get("disk", "/dev/sdX")
    firm = cfg.get("firm", "uefi")

    if type_part in ("auto", "replacement"):
        run_module(["partmgr", "auto", disk], "partmanager")
    elif type_part == "custom":
        preset = cfg.get("part_preset", [{}])[0]
        boot = preset.get("boot", "/dev/sdX1")
        root = preset.get("root", "/dev/sdX2")
        rootfs = preset.get("rootfs", "ext4")
        swap_flag = "swap-on" if preset.get("swap") else "swap-off"
        luks_flag = "luks-on" if preset.get("luks") else "luks-off"
        run_module(["partmgr", "custom", disk, boot, root, rootfs, swap_flag, firm, luks_flag], "partmanager")
    else:
        log("ERR", "partmanager", f"Unknown type_part: {type_part}")

    # 3. Bootloader
    bootloader = cfg.get("bootloader", "grub")
    firm_lower = firm.lower()
    if firm_lower in ("legacy", "bios"):
        run_module(["bootloader", "legacy", bootloader, disk], "bootloader")
    else:
        run_module(["bootloader", firm_lower, bootloader], "bootloader")

    # 4. Userscfg
    username = cfg.get("username", "tester")
    sudo_flag = "sudo-on" if cfg.get("sudo_support") else "sudo-off"
    run_module(["usercfg", username, sudo_flag], "userscfg")

    # 5. Region
    region = cfg.get("region", "Moscow")
    run_module(["region", region], "region")

    # 6. Userland (DE, Audio, Browser, Wine, Office)
    userland_map = {
        "de_install": cfg.get("desktop"),
        "audio_install": cfg.get("audio"),
        "browser_install": cfg.get("browser"),
        "wine_install": cfg.get("wine"),
        "office_install": cfg.get("office")
    }
    for script, value in userland_map.items():
        if value and str(value).lower() != "none":
            run_module([script, value], "userland")

    if cfg.get("android_support"):
        run_module(["android_install"], "userland")

    log("INFO", "parser", "Pipeline finished.")

if __name__ == "__main__":
    main()
