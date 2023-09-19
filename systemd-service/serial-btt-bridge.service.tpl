[Unit]
Description=Bridge BTT Touchscreen wired with UART to virtual Klipper console
After=klipper.service
Wants=klipper.service

[Install]
WantedBy=multi-user.target

[Service]
Type=simple
User=_USER_
RemainAfterExit=yes
ExecStart=_SOCATBIN_ -d /dev/_SERIAL_,b115200 /home/_USER_/printer_data/comms/klippy.serial,b115200
Restart=always
RestartSec=15
