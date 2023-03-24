# klipper-serial-btt

This is my project to enable serial (UART) connected BigTreeTech-TouchScreens with Klipper by emulating anything they need with macros. I tested it with an Artillery Sidewinder X2 printer. It comes with a relabeled Bigtreetech BTT-TFT28. It's one of the [supported screens](https://github.com/bigtreetech/BIGTREETECH-TouchScreenFirmware#supported-screens) of the open source BigTreeTech TouchScreenFirmware and is original made for Marlin/RepRap firmware.

Just to clarify that, I talk about the popular _TouchMode_ here, not an LCD emulation.

Due limitations of Klipper G-code macros, this project will conflict with the [mainsail-config](https://github.com/mainsail-crew/mainsail-config) project. So I included also basic macros for a full featured Mainsail UI. They are derived and adapted from their recommended macros.

In general this code should work for any of these displays an may need additional changes here - but I cant test that.
Feel free to help us with further improvements. General oriented pull requests are welcome.

See my blog [https://blog.freakydu.de/](https://blog.freakydu.de/) for more details and news.

## Prepare your Raspberry Pi / BTT CB1

### Requirements

- running Klipper and Mainsail installation
- basic printer config

### Get this repository

- Login on your Pi/CB1 (via SSH)

  ```bash
  cd ~
  git clone https://github.com/freakydude/klipper-serial-btt.git
  ```

### Copy systemd service

- Copy systemd-service/serial-btt-bridge.service to /etc/systemd/system/serial-btt-bridge.service

  - For Raspberry Pi 3/4 or CM4

    ```bash
    sudo cp ~/klipper-serial-btt/systemd-service/serial-btt-bridge-rpi.service /etc/systemd/system/  serial-btt-bridge.service
    ```

  - For BigTreeTech CB1

    ```bash
    sudo cp ~/klipper-serial-btt/systemd-service/serial-btt-bridge-cb1.service /etc/systemd/system/  serial-btt-bridge.service
    ```

    In Addition, ensure you have `console=serial` in your `/boot/BoardEnv.txt`

- _Optional:_ If yoy did anything custom: Open the service, adapt to your home directory and your user

  ```bash
  sudo nano /etc/systemd/system/serial-btt-bridge.service
  ```

- Find the following line `ExecStart=socat -d /dev/ttyAMA0,b115200 /home/pi/printer_data/comms/klippy.serial,b115200`. Replace `/home/pi` by your user. On a raspberry it's `/home/pi`, on a CB1 it's `/home/biqu` by default. Replace `/dev/ttyAMA0` with the serial (UART) interface your level-shifter and BigTreeTech-TouchScreen is connected. **Hint**: On the BigTreeTech CB1 it seems like UART serial pins are not enabled by default.

  Optional: You could also replace "b115200" two times by the serial speed listed in your BigTreeTech Touchscreen. The default 115200Bit/sec is the safe an pre-configured speed. Make sure, you select the same speed in your Touchscreen too.

- Reload services, start and enable the serial bridge

  ```bash
  sudo systemctl daemon-reload
  sudo systemctl enable --now serial-btt-bridge.service
  ```

- Double check if you like

  ```bash
  sudo systemctl status serial-btt-bridge.service
  ```

- Optional: Configure your Moonraker update manager.

  - Open your `moonraker.conf`
  - Add a new section

    ```yml
    [update_manager klipper-serial-btt]
    type: git_repo
    primary_branch: main
    path: ~/klipper-serial-btt
    origin: https://github.com/freakydude/klipper-serial-btt.git
    managed_services: klipper
    ```

## Prepare klipper/mainsail

- Link the `fd-macros` folder and the `fd-macros-example.cfg` into your config folder (where `printer.cfg` exists).

  ```bash
  ln -sf ~/klipper-serial-btt/fd-macros ~/printer_data/config/
  ln -sf ~/klipper-serial-btt/fd-macros-example.cfg ~/printer_data/config/
  ```

- Open `printer.cfg` and include the linked files from `fd-macros` folder.

- To start and adapting to your needs, also include (or copy and include) the `fd-macros-example.cfg` file.

  ```ini
  [include fd-macros/*.cfg]
  [include fd-macros-example.cfg]
  ```

The the general idea is, that there is no need to adapt the files in `fd-macros/` folder. But we linked the `fd-macros-example.cfg` and included it beforehand.

If you like or have to adapt anything and if you don't want to break the update manager for this repository, it would be wise to make a copy of these files. Normally it should be only the `fd-macros-example.cfg` because I designed it as a wrapper (as far as possible).

So exclude the linked files and include your adapted copies instead.

Feel free create pull requests if something general is wrong or missing.

## Prepare your slicer

### Prusa slicer settings

Switch to expert mode and configure following properties:

- Printer Settings

  - General
    - Firmware
      - G-code flavor: Marlin (legacy)
      - Supports remaining times: true
    - Advanced
      - Use relative E distances: false
  - Custom G-code

    - Start G-code:

      ```gcode
      M140 S0
      M104 S0

      ;LAYER_COUNT:[total_layer_count]

      ;Support for Mainsail feature
      SET_PRINT_STATS_INFO TOTAL_LAYER=[total_layer_count]

      START_PRINT BED_TEMP=[first_layer_bed_temperature] EXTRUDER_TEMP=[first_layer_temperature]
      ```

    - End G-code:

      ```gcode
      END_PRINT

      ;mainsail
      ; total layers count = [total_layer_count]
      ```

    - Before layer change G-code:

      ```gcode
      ;BEFORE_LAYER_CHANGE
      ;[layer_z]

      ;G92 E0 ;To reset relativ extruder on layer change

      TIMELAPSE_TAKE_FRAME  ; optional, if you configured TIMELAPSE with mainsail
      ```

    - Before layer change G-code:

      ```gcode
      ;AFTER_LAYER_CHANGE
      ;[layer_z]
      ;LAYER:[layer_num]

      SET_PRINT_STATS_INFO CURRENT_LAYER={layer_num+1}
      ```

    - Color Change G-code:

      ```gcode
      M600
      ```

### Other slicers

Will work similar, please adapt accordingly and make a pull request here, if you like to.
