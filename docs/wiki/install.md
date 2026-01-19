# Документация по установке QuasarLinux SE / REV

QuasarLinux — это дистрибутив Linux, основанный на Artix Linux и использующий систему инициализации OpenRC. Дистрибутив делится на редакции **PRO**, **SE** и **REV**. Каждая редакция имеет свои особенности, но их объединяет одно — использование установщика **QuasarInstall**.

> **QuasarLinux SE (Second Edition)** — это монолитная операционная система, построенная на базе редакции REV.

---

## Что такое QuasarInstall

**QuasarInstall** — это модульный установщик для QuasarLinux и операционных систем семейства QuasarFoks.

> Текущая версия QuasarInstall: **2.9-from-3.0**

---

## Возможности и отличия от сторонних установщиков

Основные отличия QuasarInstall от Calamares:

| Критерий | QuasarInstall | Calamares |
|--------|---------------|-----------|
| Модульность | Да | Да |
| Автоматическая установка | Есть | Нет |
| Сложность | Низкая | Высокая |
| Порог входа | Высокий | Низкий |

---

## Профили и автоматическая установка

Ключевая особенность QuasarInstall — **профили установки**. Профили представляют собой обычные `sh`-скрипты. Ранее использовалась post-установка, но позже она была полностью заменена профилями.

### Профили по умолчанию

- **AI**
- **Gaming**
- **Default**
- **Custom**

---

## Профиль AI

Профиль предназначен для задач машинного обучения, вычислений и работы с ИИ.

**Базовые пакеты:**
```
mesa vulkan-icd-loader xf86-video-vesa xf86-video-fbdev
```

**AMD:**
```
xf86-video-amdgpu rocm-hip-sdk rocm-opencl-sdk rocm-ml-sdk
vulkan-radeon libva-mesa-driver mesa-vdpau mesa
```

**NVIDIA:**
```
nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings
cuda cudnn python-pytorch-cuda tensorflow-cuda
```

**Intel:**
```
xf86-video-intel vulkan-intel lib32-vulkan-intel
intel-media-driver libva-intel-driver intel-compute-runtime
```

**Дополнительные пакеты:**
```
python python-pip python-virtualenv python-numpy python-scipy
python-matplotlib python-pandas cmake ninja openblas lapack fftw
```

> **Важно:** профиль AI **не поддерживает виртуальные видеодрайверы** (VirtIO, VMware и аналоги).

---

## Профиль Gaming

Профиль ориентирован на игры и низкую латентность.

**Драйверы:**
- AMD — RADV (Open Source Vulkan-драйвер)
- NVIDIA — официальный проприетарный драйвер
- Intel — vulkan-intel

### Системные оптимизации

`/etc/sysctl.d/99-gaming.conf`
```
vm.max_map_count = 16777216
fs.file-max = 524288
kernel.pid_max = 4194303
fs.inotify.max_user_watches = 524288

net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.tcp_congestion_control = bbr
```

`/etc/conf.d/cpupower`
```
governor="ondemand"
min_freq="0"
max_freq="0"
```

**Пакеты:**
```
plasma pipewire onlyoffice firefox portproton
```

> Решение по поводу `onlyoffice` и `firefox` не окончательное и может быть изменено.

---

## Профиль Default

Стандартная сборка QuasarLinux. Аналогична Gaming-профилю, но **без изменения системных конфигураций**.

**Драйверы:**
- AMD — RADV
- NVIDIA — официальный драйвер
- Intel — vulkan-intel

**Пакеты:**
```
plasma pipewire onlyoffice firefox portproton
```

---

## Профиль Custom

Профиль с полной ручной настройкой компонентов.

### Драйверы

**AMD:**
- RADV — высокопроизводительный Open Source драйвер (рекомендуется для игр)
- AMDVLK — официальный драйвер от AMD
- 2D Driver — только 2D-графика (GUI / консоль)
- ROMc — ML/AI-ориентированная подсистема (обычно с 2D-драйвером)

**NVIDIA:**
- Официальный проприетарный драйвер

**Intel:**
- Open Source драйвер

**VM:**
- Драйверы от производителя или сообщества виртуальной машины

### Компоненты

**DE:** Plasma, Xfce, LXDE, LXQt, GNOME (нестабильно)

**WM:** Sway, Hyprland, i3wm

---

## Аудиосистемы

- **PipeWire** — современный мультимедийный сервер (по умолчанию)
- **PulseAudio** — классический звуковой сервер
- **JACK** — профессиональный сервер с низкой задержкой (может работать совместно с PipeWire)

---

# Установка QuasarLinux REV

QuasarInstall в редакции REV полностью модульный (в SE используется фиксированный порядок модулей).

## Этапы установки

1. Системные требования и подготовка
2. Загрузка с носителя
3. Работа в LiveCD
4. Запуск установщика
5. Пошаговая установка (Custom-профиль)
6. Создание пользователя
7. Установка загрузчика
8. Первичная настройка системы (опционально)

---

## Системные требования

| Компонент | Минимальные | Рекомендуемые |
|---------|-------------|---------------|
| Процессор | x86_64 | x86_64 + SSE4.1 |
| ОЗУ | 1 ГБ | 6 ГБ |
| Видеокарта | 1366x768 | Vulkan-совместимая |
| Хранилище | 20 ГБ | 40 ГБ |

> Рекомендуемые требования рассчитаны на комфортную работу с графикой, играми и тяжёлыми задачами.

---

## Подготовка

### Определение типа прошивки

```
ls /sys/firmware/efi
```

- Каталог существует — **UEFI**
- Каталога нет — **Legacy BIOS**

### Рекомендации

**UEFI:**
- Отключить Secure Boot
- Отключить Fast Boot

**Legacy BIOS:**
- Изменения не требуются

---

## Запись ISO

ISO можно скачать:
- с официального сайта QuasarLinux
- из GitHub Releases

Рекомендуемые утилиты записи:
- Rufus
- balenaEtcher
- Ventoy (возможны ошибки)

---

## Загрузка с носителя

В меню загрузчика выберите:
```
From ISO/CD/DVD QuasarLinux x86_64
```

---

## LiveCD и ISO-SDK

После выбора языка запускается **ISO-SDK** — инструмент для:
- входа в chroot
- установки системы
- восстановления (в разработке)
- запуска Live-среды

---

## Установка (Install OS)

### Parted-модуль

Автоматическая или ручная разметка диска через `cfdisk`.

**UEFI:**
- ESP: 256–512 МБ (EFI Partition)
- root: остальное пространство (Linux filesystem)

**Legacy BIOS:**
- boot: 256–512 МБ
- root: остальное пространство

---

## BasePack

Установка базовой системы и ядра:
- **lts** — долгосрочная поддержка
- **zen** — производительность
- **vanilla** — стандартное ядро

---

## Профили установки

Выбор одного из профилей:
- Custom
- Default
- AI
- Gaming

---

## Создание пользователя

- Создание пользователя
- Установка пароля пользователя
- Установка пароля root

---

## Установка загрузчика

**UEFI:**
- GRUB
- EFISTUB
- rEFInd

**Legacy BIOS:**
- GRUB
- Syslinux

---

## Завершение установки

1. Выход из установщика
2. Перезагрузка системы
3. Извлечение установочного носителя

---

Документация завершена и готова к использованию.

