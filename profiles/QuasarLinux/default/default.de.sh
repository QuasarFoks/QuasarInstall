#!/bin/bash

echo "
++++++++++++++++++
+++ KDE Plasma +++
++++++++++++++++++
"
install_from_modules() {
	/installer/modules/userland/de_install "plasma" #2&> /dev/null
}
main() {
	install_from_modules	
}
main
