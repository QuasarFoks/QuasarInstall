# Документация по установки QuasarLinux SE/REV

QuasarLinux это дистрибутив Linux основанный на Artix, имеет систему инициализации OpenRC. Он делится на редакции: PRO, SE, REV, каждая из них выделяется своими особенностями, но их объединяет одно -- это использованние QuasarInstall.

# Что такое QuasarInstall ?

QuasarInstall -- это модульный установщик для QuasarLinux и операционных систем QuasarFoks.

> на данный момент версия QuasarInstall: 2.9-from-3.0

# Что он может и почему сторонние не подходят?

Отличительные особенности QuasarInstall в отличиие от того же Calamares: 

|   Критерии    | Quasarinstall | Calamares |
|---------------|---------------|-----------|
|  Модульный    |    да         |   да      |
|Авто установка |   есть        |   нет     |
| Сложность     |  Простой      | Сложный   | 
|  Порог входа  |  Высокий      | Низкий    |

# Профили и автоустановка 

Отличимая черта это профили, которые являются простыми sh скриптами, раньше была post-установка, но в скоре её заминили профили. 

## Базовые профили и их отчия

Профили по умолчанию: `` AI, Gaming, Default, Custom``

### AI 

Профиль для ИИ тянет такие пакеты: 
базовые: ``  mesa vulkan-icd-loader  xf86-video-vesa xf86-video-fbdev ``

AMD: ``xf86-video-amdgpu rocm-hip-sdk rocm-opencl-sdk rocm-ml-sdk vulkan-radeon libva-mesa-driver mesa-vdpau mesa``

Nvidia: ``nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings cuda cudnn python-pytorch-cuda tensorflow-cuda``
Intel: ``xf86-video-intel vulkan-intel lib32-vulkan-intel intel-media-driver libva-intel-driver intel-compute-runtime``

Второстепенные: ``python python-pip python-virtualenv python-numpy python-scipy python-matplotlib python-pandas cmake ninja openblas lapack fftw ``

!!! **Важно: в данном профиле нет поддержки виртуальных видео адаптеров типа Virtio и VMware** !!!


## Gaming 

- Игровой профиль уже тянет производительные драйвера,
- AMD: ravd (OpenSource Radeon Vulkan Driver)
- Nvidia: Nvidia-driver
- Intel: vulkan-intel 

Так же он меняет следующие параметры: 
/etc/sysctl.d/99-gaming.conf:
```
vm.max_map_count = 16777216
fs.file-max = 524288
kernel.pid_max = 4194303
fs.inotify.max_user_watches = 524288

# Уменьшение латентности сети
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.tcp_congestion_control = bbr
```
/etc/conf.d/cpupower
```
governor="ondemand"
min_freq="0"
max_freq="0"
```
Пакеты: plasma pipewire  onlyoffice  firefox portproton
**!!! Важно: решение по поводу onlyoffice и firefox не однозначны и возможно будут изменены !!!**


## Default 

Данный профиль ставит стандуртную сборку QuasarLinux, она похожа на Gaming, но без изменение конфигуврационных файлов.

- Драйвера: 
- AMD: ravd (OpenSource Radeon Vulkan Driver)
- Nvidia: Nvidia-driver
- Intel: vulkan-intel 
- Пакеты: plasma pipewire  onlyoffice  firefox portproton.

## Custom 

Данный профиль интересен тем что в нем всё настраивается, от драйверов до пакетов. Так что на нем мы и заострим внимания.

#### Драйвера

AMD: на выбор:
- Ravd -- Высокопроизводительный OpenSource драйвер, отлично подходящий для игр.
- Amdvlk -- Оффициальный драйвер от Amd, он может быть менее производительным.
- 2D Driver -- 2D драйвер, хорошо подходит для легкого GUI или консоли, крайне не рекомендуется для игр и сложных графических задач, а не вычислений.
- ROMc -- Система ROMc сделаная для ML/AI, в основном поставляется с 2D драйвером.

Nvidia: Стандартный оффициальный драйвер.
Intel: OpenSource драйвер.
VM: Драйвера оф от производителя/сообщества вм 

#### Компоненты 

- DE: на выбор Plasma, Xfce, Lxde, Lxqt, Gnome (Не стабильно) 
- WM: sway, Hyprland, i3wm 

- Plasma -- близкая по виду на Windows 10, очень удобная, но может быть тяжелой
- Xfce -- Очень легкая DE, чем-то напоминает Gnome/MacOS, но очень простая.
- Lxde -- Очень легчайшая, но функционал слабый. 
- Lxqt -- Легкая DE, базируется на QT
- Gnome -- Похож на MacOS, красивый и мимолистичный в некоторых местах, может тяжелее Plasma.

- sway, Hyprland -- Легкие оконные менаджеры работающие на Wayland
- i3wm -- Повторяет sway, но на X11.









