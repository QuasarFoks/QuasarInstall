############################
#   Generate config files  #
############################

import os
import subprosses
import shutil


def write_os_release_file(variables):
    """
    Записывает или обновляет файл /mnt/etc/os-release

    Args:
        variables (dict): Словарь с переменными для записи
    """
    file_path = '/mnt/etc/os-release'

    # 1. Проверяем существование директории
    directory = os.path.dirname(file_path)
    if not os.path.exists(directory):
        try:
            os.makedirs(directory, exist_ok=True)
            print(f'Создана директория: {directory}')
        except PermissionError:
            print(f'Ошибка: нет прав на создание директории {directory}')
            return False
        except Exception as e:
            print(f'Ошибка при создании директории: {e}')
            return False

    # 2. Удаляем существующий файл (если есть)
    try:
        if os.path.exists(file_path):
            os.remove(file_path)
            print(f'Удален существующий файл: {file_path}')
    except PermissionError:
        print(f'Ошибка: нет прав на удаление файла {file_path}')
        return False
    except Exception as e:
        print(f'Ошибка при удалении файла: {e}')
        return False

    # 3. Записываем новый файл
    try:
        # Используем UTF-8 вместо ASCII для поддержки любых символов
        with open(file_path, 'w', encoding='ASCII') as file:
            for key, value in variables.items():
                # Экранируем специальные символы
                if isinstance(value, str):
                    # Убираем кавычки, если они есть
                    value = value.strip('"\'')
                    # Экранируем кавычки внутри строки
                    value = value.replace('"', '\\"')
                    file.write(f'{key}="{value}"\n')
                else:
                    file.write(f'{key}={value}\n')

        print(f'Файл успешно создан: {file_path}')

        # 4. Проверяем, что файл записался корректно
        if os.path.exists(file_path):
            with open(file_path, 'r', encoding='ASCII') as file:
                content = file.read()
                print(f'Размер файла: {len(content)} символов')
                # Можно добавить проверку содержимого
                # if 'NAME=' in content:
                #     print('Файл содержит ожидаемые данные')

        return True

    except PermissionError:
        print(f'Ошибка: нет прав на запись в файл {file_path}')
        return False
    except Exception as e:
        print(f'Ошибка при записи файла: {e}')
        return False

# Пример использования
if __name__ == "__main__":
    # Определяем переменные
    os_variables = {
        'NAME': 'QuasarLinux',
        'PRETTY_NAME': 'QuasarLinux v0.1 Second Edition',
        'ID': 'quasar',
        'BUILD_ID': 'image',
        'HOME_URL': 'https://quasarfoks.gitgub.io/QuasarLinux',
        'DOCUMENTATION_URL': 'https://github.com/quasarfoks/QuasarLinux/wiki',
        'SUPPORT_URL': '#',
        'BUG_REPORT_URL': 'https://github.com/quasarfoks/QuasarLinux/issues',
        'PRIVACY_POLICY_URL': 'https://quasarfoks.github.io/policy',
        'LOGO': 'quasarlogo'
    }

    # Записываем файл
    success = write_os_release_file(os_variables)

    if success:
        print('Файл os-release успешно создан/обновлен')
    else:
        print('Не удалось создать файл os-release')



