# klipper-serial-btt

A project to enable serial connected BigTreeTech-TouchScreens

## Prepare PI

Create systemd service

```sh
sudo nano /etc/systemd/system/uart-bridge.service
```

Copy following content into that file

```ini
[Unit]
Description=Bridge BTT Touchscreen to Klipper UART
Requires=network-online.target
After=network-online.target

[Install]
WantedBy=multi-user.target

[Service]
Type=simple
User=pi
RemainAfterExit=yes
ExecStart=socat -d /dev/ttyAMA0,b115200 /home/pi/printer_data/comms/klippy.serial,b115200
Restart=always
RestartSec=15
```

Reload services, start and enable the serial bridge

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now uart-bridge.service
```
