#!/bin/bash

echo "
++++++++++++++++++
+++ KDE Plasma +++
++++++++++++++++++
"
install_from_modules() {
	/installer/modules/userland/de_install "plasma"
}
main() {
	install_from_modules	
}
main
