# klipper-serial-btt

A project to enable serial connected BigTreeTech-TouchScreens with klipper

## Prepare your Raspberry Pi

### Copy systemd service

Copy systemd-service/uart-bridge.service to /etc/systemd/system/uart-bridge.service

### Alternative: Create service file manually

Create a new file

```bash
sudo nano /etc/systemd/system/uart-bridge.service
```

and copy following content into that file

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

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now uart-bridge.service
```

## Prepare klipper/mainsail

Copy the fd-macros folder to your config folder (where printer.cfg exists). Open `printer.cfg` and include the copied files from fd-macros folder

```ini
[include fd-macros/*.cfg]
```
