#!/bin/bash

# Логирование выполнения скрипта
LOG_FILE="/var/log/faytech_touchscreen_setup.log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "Начало настройки сенсорного экрана faytech 8\" Touch Monitor (FT0080TM) на Raspberry Pi OS"
echo "Дата: $(date)"

# Проверка, запущен ли скрипт с правами root
if [[ $EUID -ne 0 ]]; then
   echo "Ошибка: Скрипт должен быть запущен с правами root (sudo)."
   exit 1
fi

# Проверка подключения сенсорного экрана (idVendor: 0eef для eGalax)
echo "Проверка подключения сенсорного экрана..."
if ! lsusb | grep -q "0eef"; then
    echo "Ошибка: Сенсорный экран faytech (idVendor: 0eef) не обнаружен. Убедитесь, что устройство подключено."
    exit 1
fi

# Запрос подтверждения у пользователя
read -p "Вы хотите настроить сенсорный экран faytech FT0080TM? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Установка отменена."
    exit 0
fi

# Обновление системы
echo "Обновление системы..."
apt update || { echo "Ошибка при обновлении системы"; exit 1; }

# Установка необходимых пакетов
echo "Установка пакетов xinput, evtest и xinput-calibrator..."
apt install -y xinput evtest xinput-calibrator || { echo "Ошибка при установке пакетов"; exit 1; }

# Создание директории для конфигурации X11
echo "Создание директории /etc/X11/xorg.conf.d..."
mkdir -p /etc/X11/xorg.conf.d || { echo "Ошибка при создании директории"; exit 1; }

# Создание файла конфигурации для сенсорного экрана
echo "Создание файла конфигурации 99-calibration.conf..."
cat > /etc/X11/xorg.conf.d/99-calibration.conf << EOL
Section "InputClass"
    Identifier "eGalax Touchscreen"
    MatchProduct "eGalax Inc. USB TouchController Touchscreen"
    Driver "evdev"
    Option "Calibration" "0 4095 0 4095"
    Option "SwapAxes" "0"
    Option "EmulateThirdButton" "false"
    Option "SendCoreEvents" "true"
EndSection
EOL
if [[ $? -ne 0 ]]; then
    echo "Ошибка при создании файла конфигурации"
    exit 1
fi

# Создание правил udev для сенсорного экрана
echo "Создание файла правил udev 99-touchscreen.rules..."
cat > /etc/udev/rules.d/99-touchscreen.rules << EOL
ACTION=="add", SUBSYSTEM=="input", ATTRS{idVendor}=="0eef", ATTRS{idProduct}=="0001", ENV{ID_INPUT}="1", ENV{ID_INPUT_TOUCHSCREEN}="1"
EOL
if [[ $? -ne 0 ]]; then
    echo "Ошибка при создании файла правил udev"
    exit 1
fi

# Перезагрузка правил udev
echo "Перезагрузка правил udev..."
udevadm control --reload-rules && udevadm trigger || { echo "Ошибка при перезагрузке правил udev"; exit 1; }

# Проверка работы сенсорного экрана с помощью evtest
echo "Проверка сенсорного экрана..."
if evtest --query /dev/input/event4 2>/dev/null; then
    echo "Сенсорный экран обнаружен и отвечает."
else
    echo "Внимание: Сенсорный экран не отвечает. Попробуйте перезагрузить систему или проверить подключение."
fi

# Предложение калибровки
read -p "Хотите запустить калибровку сенсорного экрана сейчас? (y/n): " calibrate
if [[ "$calibrate" == "y" || "$calibrate" == "Y" ]]; then
    echo "Запуск калибровки сенсорного экрана..."
    xinput_calibrator
    echo "Следуйте инструкциям на экране для калибровки."
fi

echo "Настройка сенсорного экрана faytech FT0080TM завершена!"
echo "Лог выполнения сохранен в $LOG_FILE"
echo "Пожалуйста, перезагрузите систему для применения настроек."
echo "Для перезагрузки выполните: sudo reboot"