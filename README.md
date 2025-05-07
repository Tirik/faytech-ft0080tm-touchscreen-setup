faytech 8" Touch Monitor (FT0080TM) Setup for Raspberry Pi OS
Этот репозиторий содержит скрипт для автоматической настройки сенсорного экрана faytech 8" Touch Monitor (FT0080TM) на Raspberry Pi OS.
Установка

Убедитесь, что Raspberry Pi подключен к интернету и монитор faytech FT0080TM подключен через USB и HDMI.
Выполните следующую команду в терминале:

curl -sSL https://raw.githubusercontent.com/<ВАШ_ЛОГИН>/faytech-ft0080tm-touchscreen-setup/main/setup_faytech_touchscreen.sh | bash


Следуйте инструкциям скрипта (подтверждение установки, калибровка).
После завершения перезагрузите систему:

sudo reboot

Требования

Raspberry Pi с установленной Raspberry Pi OS (рекомендуется последняя версия).
Монитор faytech 8" Touch Monitor (FT0080TM).
Подключение к интернету.
Права root для выполнения скрипта.

Логирование
Лог выполнения сохраняется в /var/log/faytech_touchscreen_setup.log.
Примечания

Если сенсорный экран не работает после перезагрузки, запустите калибровку вручную:sudo xinput_calibrator


Для поддержки обратитесь к документации faytech: https://www.faytech.com/downloads/

