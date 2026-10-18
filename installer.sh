#!/bin/bash

# ─── Esecuzione come root ──────────────────────────────────────
# Se lo script non e' gia' eseguito come root, si rilancia da solo
# con sudo chiedendo la password una sola volta all'inizio. Da qui
# in avanti tutto (incluse le richieste polkit di hostnamectl e
# systemctl) gira gia' come root, senza ulteriori richieste.
if [ "$(id -u)" -ne 0 ]; then
    exec sudo bash "$0" "$@"
fi
# ──────────────────────────────────────────────────────────────

# ─── Configurazione Tailscale ─────────────────────────────────
# Inserire qui la propria auth key di Tailscale (Settings → Keys)
# Usare una "reusable auth key" per non doverla cambiare ogni volta
TAILSCALE_AUTHKEY="tskey-auth-kPb1KzKxZR11CNTRL-KtCgmxSUgWHhJZ9FjvYuVHinMBFnUPdXP"
# ──────────────────────────────────────────────────────────────

echo
echo "                    CARMELO installer version 0.2 - 04/10/2026                    "
echo
echo
echo "  The script will install the latest Carmelo version with its dependencies"
echo "  Works with Raspberry v. 3 and up"
echo

## SYSTEM UPDATE

echo
echo "  ################################################################################"
echo
echo "    The script will update the system."
echo "    If it is necessary accept by clic Enter"
echo
echo "  ################################################################################"
echo
sleep 10s
echo
sudo apt update
sudo apt-get update
echo
sudo apt upgrade -y
sudo apt-get upgrade -y

## PYTHON LIBRARIES INSTALLATION
echo
echo "  ################################################################################"
echo
echo "    The script will install the necessary libraries. "
echo "    The process could take a long time."
echo
echo "  ################################################################################"
echo
sleep 10s
sudo apt install python3-pip python3-setuptools python3-gpiozero -y
echo
sudo apt install python3-scipy python3-paho-mqtt -y
echo
sudo apt-get install libusb-1.0-0.dev git cmake build-essential bc -y
echo
pip3 install pyrtlsdr==0.3.0 --break-system-packages
echo

## OSMOCOM RTLSDR LIBRARY INSTALLATION
echo
echo "  ################################################################################"
echo
echo "    The script will install the OSMOCOM library for the SDR device. "
echo "    If it is necessary accept by clic Enter"
echo
echo "  ################################################################################"
echo
sleep 10s
git clone https://gitea.osmocom.org/sdr/rtl-sdr.git
cd rtl-sdr/ || exit 1
mkdir build
cd build || exit 1
cmake ../ -DINSTALL_UDEV_RULES=ON
make
sudo make install
sudo ldconfig

echo "blacklist dvb_usb_rtl28xxu" | sudo tee -a /etc/modprobe.d/blacklist-rtl.conf > /dev/null
echo "blacklist rtl2832" | sudo tee -a /etc/modprobe.d/blacklist-rtl.conf > /dev/null
echo "blacklist rtl2830" | sudo tee -a /etc/modprobe.d/blacklist-rtl.conf > /dev/null
echo



## WRITING FILE SERVICE AND TIMER
echo
echo "  ################################################################################"
echo
echo "    The script loads the files to make the CARMELO program automatic "
echo "    and to send the dates. "
echo
echo "  ################################################################################"
echo
sleep 10s

### 1a. carmelo.service

sudo tee /etc/systemd/system/carmelo.service > /dev/null << 'EOF'
[Unit]
Description=Carmelo program

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi
ExecStart=python3 carmelo.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

### 1b. carmelo.timer

sudo tee /etc/systemd/system/carmelo.timer > /dev/null << 'EOF'
[Unit]
Description=Carmelo program timer

[Timer]
OnBootSec=1min

[Install]
WantedBy=timers.target
EOF

### 2. spedisci.service

sudo tee /etc/systemd/system/spedisci.service > /dev/null << 'EOF'
[Unit]
Description=Spedisci file python script

[Service]
Type=simple
User=pi
ExecStart=/usr/bin/python3 /home/pi/spedisci.py

[Install]
WantedBy=multi-user.target
EOF

### 3. spedisci.timer

sudo tee /etc/systemd/system/spedisci.timer > /dev/null << 'EOF'
[Unit]
Description=Spedisci file python script

[Timer]
OnCalendar=*:0/5
RandomizedDelaySec=59

[Install]
WantedBy=timers.target
EOF

### 4. update.service

sudo tee /etc/systemd/system/update.service > /dev/null << 'EOF'
[Unit]
Description=Update local git repository

[Service]
Type=simple
User=pi
ExecStart=/home/pi/update.sh

[Install]
WantedBy=multi-user.target
EOF

### 5. update.timer

sudo tee /etc/systemd/system/update.timer > /dev/null << 'EOF'
[Unit]
Description=Update local git repository

[Timer]
OnCalendar=*-*-* 19:02:30

[Install]
WantedBy=timers.target
EOF

### 6. receiving_station_data.txt

segno=("asterisk" "circle" "circle_cross" "circle_dot" "circle_x" "circle_y" "cross" "dash" "diamond" "diamond_cross" "diamond_dot" "dot" "hex" "hex_dot" "inverted_triangle" "plus" "square" "square_cross" "square_dot" "square_pin" "square_x" "star" "star_dot" "triangle" "triangle_dot" "triangle_pin" "x" "y")
colori=("green" "red" "salmon" "gold" "orange" "black" "brown" "purple" "blue")

echo
echo -n "Enter your location here. You could write Municipality - County and State in parenteses eg: Budrio - BO (ITA): "
read -r NAME

echo "$NAME" | sudo tee -a /home/pi/receiving_station_data.txt > /dev/null

while :; do
    echo -n "Enter your latitude in degrees (eg. 44.4567):  "
    read -r LAT
    [[ $LAT =~ ^[+-]?[0-9]+\.?[0-9]*$ ]] || { echo "Use point instead of comma"; continue; }
    [[ $(bc <<< "$LAT > -90 && $LAT <= 90") == 1 ]] || { echo "Error: value out of range"; continue; }
    echo "$LAT" | sudo tee -a /home/pi/receiving_station_data.txt > /dev/null
    break
done

while :; do
    echo -n "Enter your longitude in degrees (eg. 11.0909):  "
    read -r LNG
    [[ $LNG =~ ^[+-]?[0-9]+\.?[0-9]*$ ]] || { echo "Use point instead of comma"; continue; }
    [[ $(bc <<< "$LNG > 0 && $LNG < 361") == 1 ]] || { echo "Error: value out of range"; continue; }
    echo "$LNG" | sudo tee -a /home/pi/receiving_station_data.txt > /dev/null
    break
done

echo -n "Enter your antenna type eg.: Yagi, Ground Plane, Discone ecc….: "
read -r ANTENNA
echo "$ANTENNA" | sudo tee -a /home/pi/receiving_station_data.txt > /dev/null

while :; do
    echo -n "Enter the carrier frequency of the transmitter you want to tune to (in herz) eg.: 143.05e6 : "
    read -r FREQ
    [[ $FREQ =~ ^[+-]?[0-9]+(\.[0-9]+)?(e[0-9]+)?$ ]] || { echo "Use point instead of comma"; continue; }
    echo "$FREQ" | sudo tee -a /home/pi/receiving_station_data.txt > /dev/null
    break
done

while :; do
    echo -n "Enter the angle of view of the antenna in degrees eg.: 360 or less if there are obstacles: "
    read -r VIEW
    [[ $VIEW =~ ^[+-]?[0-9]*$ ]] || { echo "Use integer"; continue; }
    [[ $(bc <<< "$VIEW > 0 && $VIEW < 361") == 1 ]] || { echo "Error: value out of range"; continue; }
    echo "$VIEW" | sudo tee -a /home/pi/receiving_station_data.txt > /dev/null
    break
done

while :; do
    echo -n "Enter the symbol with which you want to appear in the overall representation of Carmelo choosing between: asterisk circle circle_cross circle_dot circle_x circle_y cross dash diamond diamond_cross diamond_dot dot hex hex_dot inverted_triangle plus square square_cross square_dot square_pin square_x star star_dot triangle triangle_dot triangle_pin x y : "
    read -r SIMBOLO
    [[ " ${segno[*]} " == *" $SIMBOLO "* ]] || { echo "Error: enter a correct symbol"; continue; }
    echo "$SIMBOLO" | sudo tee -a /home/pi/receiving_station_data.txt > /dev/null
    break
done

while :; do
    echo -n "Enter the color with which you want to appear in the overall representation of Carmelo choosing between: green red salmon gold orange black brown purple blue : "
    read -r COLOR
    [[ " ${colori[*]} " == *" $COLOR "* ]] || { echo "Error: enter a correct color name"; continue; }
    echo "$COLOR" | sudo tee -a /home/pi/receiving_station_data.txt > /dev/null
    break
done

while :; do
    echo -n "Enter the value of pre-gain: "
    read -r GAIN
    [[ "$GAIN" =~ ^[0-9]+$ ]] || { echo "Error: use positive integer"; continue; }
    echo "$GAIN" | sudo tee -a /home/pi/receiving_station_data.txt > /dev/null
    break
done

sudo systemctl daemon-reload
sudo systemctl enable carmelo.timer
sudo systemctl enable spedisci.timer
sudo systemctl enable spedisci.service
sudo systemctl enable update.timer
sudo systemctl enable update.service
sudo systemctl start carmelo.timer
sudo systemctl start spedisci.timer
sudo systemctl start update.timer


## TAILSCALE INSTALLATION (remote SSH access)
echo
echo "  ################################################################################"
echo
echo "    The script will install Tailscale for remote SSH access."
echo
echo "  ################################################################################"
echo
sleep 5s

echo -n "  Enter a short name for this station in Tailscale (eg. Budrio-Ita or Barcellona-Esp): "
read -r TS_HOSTNAME

# Imposta hostname di sistema
hostnamectl set-hostname "$TS_HOSTNAME"
sudo sed -i "s/127.0.1.1.*/127.0.1.1\t$TS_HOSTNAME/" /etc/hosts

# Assicurati che SSH sia attivo
sudo apt-get install -y openssh-server -qq
systemctl enable --now ssh

# Installa Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
systemctl enable --now tailscaled

# Connetti a Tailscale con SSH abilitato
sudo tailscale up --authkey="$TAILSCALE_AUTHKEY" --hostname="$TS_HOSTNAME" --ssh

# Mostra IP Tailscale assegnato
echo
echo "  Tailscale connected. SSH access:"
echo "  ssh pi@$TS_HOSTNAME   or   ssh pi@$(sudo tailscale ip -4 2>/dev/null || echo '<tailscale-ip>')"
echo


## RESTART
echo
echo "  ################################################################################"
echo
echo "    Raspberry will now be shut down. Then CARMELO will be ready to work. "
echo "    Before turning it back on, remember to connect the SDR dongle and the antenna cable to the USB socket."
echo
echo "  ################################################################################"
echo
sleep 20s

sudo /sbin/shutdown -h now
