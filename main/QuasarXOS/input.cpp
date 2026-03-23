#include <ncurses.h>
#include <iostream>
#include <cstdlib>
void start_tui()
{
    initscr();              // Запуск ncurses
    cbreak();               // Отключаем буферизацию строк
    noecho();               // Не отображаем вводимые символы
    keypad(stdscr, TRUE);   // Включаем функциональные клавиши
}
void stop_tui() { endwin();}

void langluge()
{
    start_tui();
    char *choices[] = {
        "ru_RU",
        "eu_EU",
        "",
        "Выход"
    };
}
