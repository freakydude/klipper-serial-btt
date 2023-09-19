#!/bin/bash -e
function echo_ok {
   echo -e "\033[0;32m${1}\033[0m"
}
function echo_nok {
   echo -e "\033[0;31m${1}\033[0m"
}
function print_ {
   printf "\033[0;33m${1}\033[0m"
}

print_ "\nFirst sudo check: "
[[ `sudo -l` > /dev/null ]] && echo_ok "OK" || { echo_nok "FAILED"; exit 2; }

print_ "Determine MCU: "
case "$USER" in
  "pim")
    MCU="RPi"
    echo_ok "OK. Seems to be a Raspberry Pi"
    ;;
  "biqu")
    MCU="CB1"
    echo_ok "OK. Seems to be a CB1"
    ;;
  *)
    echo_nok "NOK\n"
    #exit 2
    print_ ">> You're running neither a common Raspberry nor a CB1 board or under a different user.\n"
    print_ "Please specify your user name ($USER): "
    read USER
    [[ -z $USER ]] && { echo_nok "You did not specify a user name"; exit 2; }
    print_ "Please specify your serial port name (ttyS0, ttyAMA0, ...): "
    read SERIAL
    [[ -z $SERIAL ]] && { echo_nok "You did not specify a serial port name"; exit 2; }
    print_ "Are these correct? User: $USER / Serial: $SERIAL  -> Press any key to continue or CTRL-C to abort:"
    read
esac

print_ "Checking user is in group dialout: "
if [[ ! `id -Gn $USER |grep dialout` >/dev/null ]]; then
  sudo gpasswd -a $USER dialout
  echo_ok "added"
else
  echo_ok "OK"
fi

print_ "Checking socat binary: "
SOCATBIN=`which socat`
if [[ -z $SOCATBIN ]]; then
  echo_nok "socat missing. Installing package..."
  sudo apt -y install socat
else
  echo_ok "OK. Present"
fi

print_ "Create serial-btt-bridge service: "
case $MCU in
  "RPi")
    SERIAL="ttyAMA0"
    ;;
  "CB1")
    SERIAL="ttyS0"
    ;;
esac
sed -e "s|_USER_|$USER|g;s|_SOCATBIN_|$SOCATBIN|g;s|_SERIAL_|$SERIAL|g" systemd-service/serial-btt-bridge.service.tpl > /tmp/serial-btt-bridge.service
sudo mv /tmp/serial-btt-bridge.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now serial-btt-bridge.service
echo_ok "OK"

print_ "Checking if service runs: "
sleep 3
systemctl is-active --quiet serial-btt-bridge && echo_ok "OK" || { echo_nok "FAILED. Check 'journalctl -xe'"; exit 2; }

print_ "Linking config into printer_data: "
{ ln -sf ~/klipper-serial-btt/fd-macros ~/printer_data/config/; ln -sf ~/klipper-serial-btt/fd-macros-example.cfg ~/printer_data/config/; } && echo_ok "OK" || echo_nok "FAILED"

print_ "Adding update manager: "
if [[ `grep -R "\[update_manager klipper-serial-btt\]" ~/printer_data/config/*` ]]; then
  echo_ok "OK. Already present"
else
  cat <<EOF >> ~/printer_data/config/moonraker.conf
[update_manager klipper-serial-btt]
type: git_repo
primary_branch: main
path: ~/klipper-serial-btt
origin: https://github.com/freakydude/klipper-serial-btt.git
managed_services: klipper
EOF
  echo_ok "OK"
fi
