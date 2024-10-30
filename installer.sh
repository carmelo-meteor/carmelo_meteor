#!/bin/bash


echo
echo "                    CARMELO installer version 0.11 - 24/01/2024                     "
echo
echo
echo "  The script will install the latest Carmelo version with its dependencies"
echo "  Works with Raspberry v. 3 and up"
echo 

## SYSTEM UDATE

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
sudo apt-get update
echo
sudo apt-get full-upgrade

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
sudo apt-get install python3-pip libatlas-base-dev python3-gpiozero -y
echo
sudo apt-get install  python3-scipy python3-paho-mqtt -y
echo
sudo apt-get install libusb-1.0-0.dev git cmake build-essential bc -y
echo
pip3 install pyrtlsdr --break-system-packages
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
cd rtl-sdr/
mkdir build
cd build
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

echo "[Unit] " | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo "Description= Carmelo program " | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo "[Service]" | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo "Type=simple" | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo "User=pi" | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo "WorkingDirectory=/home/pi" | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo "ExecStart=python3 carmelo.py" | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo "Restart=always" | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo "[Install]" | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo "WantedBy=multi-user.target" | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null


### 1b. carmelo.timer

echo "[Unit] " | sudo tee -a  /etc/systemd/system/carmelo.timer > /dev/null
echo "Description= Carmelo program timer" | sudo tee -a  /etc/systemd/system/carmelo.timer > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/carmelo.timer > /dev/null
echo "[Timer]" | sudo tee -a  /etc/systemd/system/carmelo.timer > /dev/null
echo "OnBootSec=1min" | sudo tee -a  /etc/systemd/system/carmelo.timer > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/carmelo.timer > /dev/null
echo "[Install]" | sudo tee -a  /etc/systemd/system/carmelo.timer > /dev/null
echo "WantedBy=timers.target" | sudo tee -a  /etc/systemd/system/carmelo.timer > /dev/null

### 2. spedisci.service

echo "[Unit]" | sudo tee -a  /etc/systemd/system/spedisci.service > /dev/null
echo "Description= Spedisci file python script" | sudo tee -a  /etc/systemd/system/spedisci.service > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/spedisci.service > /dev/null
echo "[Service]" | sudo tee -a  /etc/systemd/system/spedisci.service > /dev/null
echo "Type=simple" | sudo tee -a  /etc/systemd/system/spedisci.service > /dev/null
echo "User=pi" | sudo tee -a  /etc/systemd/system/spedisci.service > /dev/null
echo "ExecStart=/usr/bin/python3 /home/pi/spedisci.py" | sudo tee -a  /etc/systemd/system/spedisci.service > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/spedisci.service > /dev/null
echo "[Install]" | sudo tee -a  /etc/systemd/system/spedisci.service > /dev/null
echo "WantedBy=multi-user.target" | sudo tee -a  /etc/systemd/system/spedisci.service > /dev/null

### 3. spedisci.timer

echo "[Unit]" | sudo tee -a  /etc/systemd/system/spedisci.timer > /dev/null
echo "Description= Spedisci file python script" | sudo tee -a  /etc/systemd/system/spedisci.timer > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/spedisci.timer > /dev/null
echo "[Timer]" | sudo tee -a  /etc/systemd/system/spedisci.timer > /dev/null
echo "OnCalendar=*:0/5" | sudo tee -a  /etc/systemd/system/spedisci.timer > /dev/null
echo "RandomizedDelaySec=59" | sudo tee -a  /etc/systemd/system/spedisci.timer > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/spedisci.timer > /dev/null
echo "[Install]" | sudo tee -a  /etc/systemd/system/spedisci.timer > /dev/null
echo "WantedBy=timers.target" | sudo tee -a  /etc/systemd/system/spedisci.timer > /dev/null

### 4. update.service
echo "[Unit]" | sudo tee -a  /etc/systemd/system/update.service > /dev/null
echo "Description= Update local git repository" | sudo tee -a  /etc/systemd/system/update.service > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/update.service > /dev/null
echo "[Service]" | sudo tee -a  /etc/systemd/system/update.service > /dev/null
echo "Type=simple" | sudo tee -a  /etc/systemd/system/update.service > /dev/null
echo "User=pi" | sudo tee -a  /etc/systemd/system/update.service > /dev/null
echo "ExecStart=/home/pi/update.sh" | sudo tee -a  /etc/systemd/system/update.service > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/update.service > /dev/null
echo "[Install]" | sudo tee -a  /etc/systemd/system/update.service > /dev/null
echo "WantedBy=multi-user.target" | sudo tee -a  /etc/systemd/system/update.service > /dev/null

### 5. update.timer

echo "[Unit]" | sudo tee -a  /etc/systemd/system/update.timer > /dev/null
echo "Description=  Update local git repository" | sudo tee -a  /etc/systemd/system/update.timer > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/update.timer > /dev/null
echo "[Timer]" | sudo tee -a  /etc/systemd/system/update.timer > /dev/null
echo "OnCalendar=*-*-* 19:02:30" | sudo tee -a  /etc/systemd/system/update.timer > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/update.timer > /dev/null
echo "[Install]" | sudo tee -a  /etc/systemd/system/update.timer > /dev/null
echo "WantedBy=timers.target" | sudo tee -a  /etc/systemd/system/update.timer > /dev/null

### 6. receiving_station_data.txt

segno=("asterisk" "circle" "circle_cross" "circle_dot" "circle_x" "circle_y" "cross" "dash" "diamond" "diamond_cross" "diamond_dot" "dot" "hex" "hex_dot" "inverted_triangle" "plus" "square" "square_cross" "square_dot" "square_pin" "square_x" "star" "star_dot" "triangle" "triangle_dot" "triangle_pin" "x" "y")
colori=("green" "red" "salmon" "gold" "orange" "black" "brown" "purple" "blue")

echo
echo -n "Enter your location here. You could write Municipality - County and State in parenteses eg: Budrio - BO (ITA): "
read NAME

echo "$NAME" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null

while :; do
    echo -n "Enter your latitude in degrees (eg. 44.4567):  "
    read LAT
    [[ $LAT =~ ^[+-]?[0-9]+\.?[0-9]*$ ]] || { echo "Use point instead of common"; continue; } 
    [[ $(bc <<< "$LAT > -90 && $LAT <= 90") == 1 ]] || { echo "error: value out of range"; continue; } 
    echo "$LAT" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null
    break  
done

while :; do
    echo -n "Enter your longitude in degrees (eg. 11.0909):  "
    read LNG
    [[ $LNG =~ ^[+-]?[0-9]+\.?[0-9]*$ ]] || { echo "Use point instead of common"; continue; } 
    [[ $(bc <<< "$LNG > 0 && $LNG < 361") == 1 ]] || { echo "error: value out of range"; continue; } 
    echo "$LNG" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null
    break  
done

echo -n "Enter your antenna type eg.: Yagi, Ground Plane, Discone ecc….: "
read ANTENNA
echo "$ANTENNA" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null

while :; do
    echo -n "Enter the carrier frequency of the transmitter you want to tune to (in herz) eg.: 143.05e6 : "
    read FREQ
    [[ $FREQ =~ ^[+-]?[0-9]+\.?[0-9]+\e?[0-9]*$ ]] || { echo "Use point instead of common"; continue; } 
    echo "$FREQ" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null
    break
done


while :; do
    echo -n "Enter the angle of view of the antenna in degrees eg.: 360 or less if there are obstacles: "
    read VIEW
    [[ $VIEW =~ ^[+-]?[0-9]*$ ]] || { echo "Use integer"; continue; } 
    [[ $(bc <<< "$VIEW > 0 && $VIEW < 361") == 1 ]] || { echo "error: value out of range"; continue; } 
    echo "$VIEW" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null
    break  
done

while :; do
    echo -n "Enter the symbol with which you want to appear in the overall representation of Carmelo choosing between: asterisk circle circle_cross circle_dot circle_x circle_y cross dash diamond diamond_cross diamond_dot dot hex hex_dot inverted_triangle plus square square_cross square_dot square_pin square_x star star_dot triangle triangle_dot triangle_pin x y : "
    read SIMBOLO
    [[ " ${segno[*]} " == *" $SIMBOLO "* ]] || { echo "Error: enter a correct simbol"; continue; } 
    echo "$SIMBOLO" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null
    break  	
done

while :; do
    echo -n "Enter the symbol with which you want to appear in the overall representation of Carmelo choosing between: green red salmon gold orange black brown purple blue : "
    read COLOR
    [[ " ${colori[*]} " == *" $COLOR "* ]] || { echo "Error: enter a correct color name"; continue; } 
    echo "$COLOR" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null
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
