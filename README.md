<!-- markdownlint-disable first-line-h1 -->
<!-- markdownlint-disable html -->
<!-- markdownlint-disable no-duplicate-header -->

<div align="center">

# Quasar-install 3.0

![Static Badge](https://img.shields.io/badge/Статус-Активная_разработка-brightgreen)
![Static Badge](https://img.shields.io/badge/version-3.0-blue)
![Static Badge](https://img.shields.io/badge/Архитектура-x86__64-orange)



</div>

## Быстрые ссылки

[![Документация](https://img.shields.io/badge/📚-Инструкция_и_Wiki-2D2B55)](https://github.com/b-e-n-z1342/QuasarLinux-install/wiki)
[![Исходный код](https://img.shields.io/badge/💻-Исходный_код-FF6C37)](https://gitlab.com/users/Quasar_benz/projects)

## О проекте

## О проекте

**QuasarInstall** - это установщик для QuasarLinux, QuasarOS, QuasarXOS. Для каждой операционной системы он разный.

### QuasarLinux ( REV, SE )
**QuasarLinux** делится на REV и SE, у REV установщик модульный и поддерживает кастомные профили настройки пользовательского пространства. У SE, наоборот, частично модульная архитектура.

#### Философия (Версия QuasarLinux REV)
**Модульность + Независимость = Гибкость**  
Каждый модуль работает автономно. используйте только то, что нужно вам. 

#### Архитектура установщика (Версия QuasarLinux REV)

#### Основные модули (Версия QuasarLinux REV)

| Модуль | Назначение | Статус |
|--------|------------|--------|
| `basepack` | Установка базовых пакетов и выбор ядра | Стабильный |
| `bootloader` | Установка загрузчика (GRUB/Efistub/SysLinux) | Стабильный |
| `parted` | Разметка диска и создание разделов | Стабильный |
| `users` | Настройка пользователя | Стабильный |
| `install` | Основной скрипт для управления модулями | Стабильный |
| `inst_pack`| Модуль сканирования профиля и настройки по нему. | стабильный |

#### Модули для работы по профилю (Версия QuasarLinux REV)

| Модуль | Назначение | Статус |
|--------|------------|--------|
| `de_install` | Установка окружений рабочего стола | Стабильный |
| `wm_install` | Установка оконных менеджеров | Стабильный |
| `audio_install` | Установка звукового сервера | Стабильный |
| `audio_config` | настройка звукового сервера | Стабильный |
| `browser_install` | Установка браузеров | Стабильный |
| `android_install` | Установка Android-совместимости | В разработке* |
* - требует ядро с binder и другими устройствами Android.

### QuasarOS
**В разработке**
### QuasarXOS
**В разработке**

```
# Клонируйте репозиторий
git clone https://github.com/QuasarFoks/QuasarInstall.git

# Перейдите в директорию
cd QuasarInstall

# Дайте права на выполнение и запустите
chmod +x make && ./make

# Выберите нужный дистрибутив 
# и в папке build/ будет готовый установщик

# Запуск установщика
build/run
```
