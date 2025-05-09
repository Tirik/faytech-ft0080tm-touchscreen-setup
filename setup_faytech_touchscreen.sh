#!/bin/bash

# Логирование выполнения скрипта
LOG_FILE="/var/log/faytech_touchscreen_setup.log"

# Создание лог-файла с правильными правами
sudo touch "$LOG_FILE"
sudo chmod 666 "$LOG_FILE"  # Временное изменение прав для записи

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

# Проверка версии ОС
OS_VERSION=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d'=' -f2)
if [[ "$OS_VERSION" != "bullseye" && "$OS_VERSION" != "bookworm" ]]; then
    echo "Внимание: Скрипт протестирован на Raspberry Pi OS Bullseye и Bookworm."
fi

# Обновление системы
echo "Обновление системы..."
apt update || { echo "Ошибка при обновлении системы"; exit 1; }

# Установка необходимых пакетов
echo "Установка пакетов xinput, evtest и libinput..."
apt install -y xinput evtest libinput-bin || { echo "Ошибка при установке пакетов"; exit 1; }

# Создание директории для конфигурации X11
echo "Создание директории /etc/X11/xorg.conf.d..."
mkdir -p /etc/X11/xorg.conf.d || { echo "Ошибка при создании директории"; exit 1; }

# Создание файла конфигурации для сенсорного экрана (X11)
echo "Создание файла конфигурации 99-calibration.conf..."
cat > /etc/X11/xorg.conf.d/99-calibration.conf << EOL
Section "InputClass"
    Identifier "eGalax Touchscreen"
    MatchProduct "eGalax Inc. USB TouchController Touchscreen"
    MatchDevicePath "/dev/input/event*"
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

# Автоматическое определение устройства сенсорного экрана
echo "Поиск сенсорного экрана..."
TOUCH_DEVICE=""
for event in /dev/input/event*; do
    if [ -e "$event" ]; then
        DEVICE_NAME=$(cat /sys/class/input/$(basename "$event")/device/name 2>/dev/null)
        if [[ "$DEVICE_NAME" == *"eGalax Inc. USB TouchController Touchscreen"* ]]; then
            TOUCH_DEVICE="$event"
            echo "Сенсорный экран найден: $TOUCH_DEVICE ($DEVICE_NAME)"
            break
        fi
    fi
done

# Проверка активности сенсорного экрана
if [ -n "$TOUCH_DEVICE" ]; then
    echo "Проверка активности сенсорного экрана на $TOUCH_DEVICE..."
    if command -v libinput >/dev/null && libinput list-devices | grep -q "$TOUCH_DEVICE"; then
        echo "Сенсорный экран активен и распознан libinput (Wayland)."
    elif command -v evtest >/dev/null && sudo timeout 1 evtest "$TOUCH_DEVICE" >/dev/null 2>&1; then
        echo "Сенсорный экран активен и отвечает (X11/evdev)."
    else
        echo "Внимание: Сенсорный экран не отвечает на $TOUCH_DEVICE. Попробуйте перезагрузить систему."
    fi
else
    echo "Ошибка: Не удалось найти сенсорный экран. Проверьте подключение или выполните 'evtest' для диагностики."
    exit 1
fi

# Восстановление прав лог-файла
sudo chmod 644 "$LOG_FILE"

echo "Настройка сенсорного экрана faytech FT0080TM завершена!"
echo "Лог выполнения сохранен в $LOG_FILE"
echo "Пожалуйста, перезагрузите систему для применения настроек."
echo "Для перезагрузки выполните: sudo reboot"
