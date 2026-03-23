#include "./main.h"
#include <iostream>
using namespace std;

bool checkInternetPing(const string& host = "quasarfoks.github.io") {
    string cmd = "ping -c 1 -W 2 " + host + " > /dev/null 2>&1";
    int result = system(cmd.c_str());
    return result == 0;
}
void show_logo()
{
    // OS name
    cout << (".####.                                                     ##    ##   .####.    :####:  ") << endl;
    cout << ("######                                                     :##  ##:   ######   :######  ") << endl;
    cout << (":##  ##:                                                     ##  ##   :##  ##:  ##:  :# ") << endl;
    cout << ("##:  :##  ##    ##   :####     :#####.   :####     ##.####   :####:   ##:  :##  ##      ") << endl;
    cout << ("##    ##  ##    ##   ######   ########   ######    #######    ####    ##    ##  ###:    ") << endl;
    cout << ("##    ##  ##    ##   #:  :##  ##:  .:#   #:  :##   ###.       :##:    ##    ##  :#####: ") << endl;
    cout << ("##    ##  ##    ##    :#####  ##### .     :#####   ##         :##:    ##    ##   .#####: ") << endl;
    cout << ("##    ##  ##    ##  .#######  .######:  .#######   ##         ####    ##    ##      :### ") << endl;
    cout << ("##:  :##  ##    ##  ## .  ##     .: ##  ## .  ##   ##        :####:   ##:  :##        ## ") << endl;
    cout << (":##  ##   ##:  ###  ##:  ###  #:.  :##  ##:  ###   ##        ##::##   :##  ##:  #:.  :## ") << endl;
    cout << ("######.   #######  ########  ########  ########   ##       :##  ##:   ######   #######: ") << endl;
    cout << (".#####     ###.##    ###.##  . ####      ###.##   ##       ##    ##   .####.   .#####:  ") << endl;
    cout << (".##:                                                                                 ") << endl;
    cout << (".#                                                                                  ") << endl;
}




int main() {
    if (checkInternetPing()) {
        cerr << ("OK: connect to network.");
    } else {
        cout << "Нет интернета!" << endl;
        cerr << ("ERR: no connect to network.");
        exit(1);
    }
    system("clear");
    show_logo();
    system("/installer/input");
    return 0;

}
