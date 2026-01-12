import os

def install_plasma():
    url_plasma = "https://sourceforge.net/.."
    url_plasma_gpg = "https://sourceforge.net/.."
    plasma_pkg = "plasma.tar.zst"
    new_system = "/mnt"
    os.system(f"wget {url_plasma}")
    os.system(f"wget {url_plasma_gpg}")
    os.system(f"tar -xf {plasma_pkg} {new_system}")

install_plasma()
