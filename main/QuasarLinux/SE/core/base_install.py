import subprocess
import os
from pathlib import Path
#
#   QuasarLinux-SE
#   Installer 3.0
#
def installbase():
    # Создаем целевую директорию
    target_dir = Path("/installer/img")
    target_dir.mkdir(parents=True, exist_ok=True)

    # Меняем рабочую директорию
    os.chdir(target_dir)

    baseurls = [
        'https://sourceforge.net/projects/quasarlinux/files/Second-Edition/0.1/core.tar.xz/download',
        'https://sourceforge.net/projects/quasarlinux/files/Second-Edition/0.1/lib.tar.xz/download',
        'https://sourceforge.net/projects/quasarlinux/files/Second-Edition/0.1/core-data.tar.xz/download'
    ]

    print(f"Downloading files to: {target_dir.absolute()}")

    for url in baseurls:
        try:
            print(f"Downloading: {url}")
            subprocess.run(["wget", url], check=True)
            print(f"Successfully downloaded: {url}")
        except subprocess.CalledProcessError as e:
            print(f"Error downloading {url}: {e}")
        except FileNotFoundError:
            print("Error: wget not found. Please install wget or use requests module instead.")
            break
def unpack():
    os.chdir(target_dir)
    base_tar = [
            'core.tar.xz'
            'lib.tar.xz'
            'core-data.tar.xz'
    ]
    for archive in base_tar:
        print(f"unpack: {archive}")
        subprocess.run(["tar", "-xf" archive, "/mnt"], chek=true)
        break


if __name__ == "__main__":
    installbase()
    unpack()
