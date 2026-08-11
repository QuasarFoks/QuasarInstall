#!/bin/bash
for po in $(find . -name "installer.po"); do
    echo "Компилирую: $po"
    msgfmt "$po" -o "${po%.po}.mo"
done
echo "Готово! Все .mo созданы."
