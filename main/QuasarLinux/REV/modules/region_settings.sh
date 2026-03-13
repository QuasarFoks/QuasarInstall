#!/usr/bin/env bash

# --- Инициализация локализации ---
export TEXTDOMAIN="installer"
export TEXTDOMAINDIR="/usr/local/sdk/global/locale"

_() {
	gettext -s "$1"
}

clear

echo "$(_ "Select continent/region:")"
echo "--------------------------"


options=(
	"North America (US)"
	"Europe"
	"Asia"
	"Africa"
	"Antarctica"
	"Arctic"
	"Atlantic"
	"Australia"
	"Brazil"
	"Canada"
	"Etc"
)


for i in "${!options[@]}"; do
	printf "%2d) %s\n" $((i+1)) "$(_ "${options[$i]}")"
	done

	echo ""

	read -p "$(_ "Enter choice [1-11]: ")" choice


	case $choice in
	1)  region="US" ;;
	2)  region="Europe" ;;
	3)  region="Asia" ;;
	4)  region="Africa" ;;
	5)  region="Antarctica" ;;
	6)  region="Arctic" ;;
	7)  region="Atlantic" ;;
	8)  region="Australia" ;;
	9)  region="Brazil" ;;
	10) region="Canada" ;;
	11) region="Etc" ;;
	*)

	echo "$(_ "Invalid input!")"
	exit 1
	;;
	esac

	if [ -f "./region" ]; then
		chmod +x ./region
		./region "$region"
		else
			# Ошибка запуска
			printf "$(_ "Error executing region script: %v\n")" "file ./region not found"
			exit 1
			fi
