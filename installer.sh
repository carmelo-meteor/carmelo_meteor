#!/bin/bash


echo
echo "                       CARMELO installer versione 0.3                                "
echo
echo
echo "  Lo script installera' la versione più recente di Carmelo con le relative dipendenze"
echo 

## AGGIORNAMENTO DEL SISTEMA

echo
echo "  ################################################################################"
echo
echo "    Lo script aggiornera' il sistema."
echo "    Se necessario accettare premendo INVIO"
echo
echo "  ################################################################################"
echo
sleep 10s
echo
sudo apt-get update
echo
sudo apt-get upgrade

## INSTALLAZIONE LIBRERIE DI PYTHON
echo
echo "  ################################################################################"
echo
echo "    Lo script installera' le librerie necessarie. "
echo "    Il processo potrebbe durare a lungo."
echo
echo "  ################################################################################"
echo
sleep 10s
sudo apt-get install python3-pip python3-matplotlib libatlas-base-dev python3-gpiozero
echo
python3 -m pip install pyrtlsdr scipy paho-mqtt
echo
sudo apt-get install libusb-1.0-0.dev git cmake build-essential
echo


## INSTALLAZIONE LIBRERIA OSMOCOM RTLSDR
echo
echo "  ################################################################################"
echo 
echo "    Lo script installera' la libreria OSMOCOM per il device SDR. "
echo "    Se necessario accettare premendo INVIO"
echo
echo "  ################################################################################"
echo
sleep 10s
git clone git://git.osmocom.org/rtl-sdr.git
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



## SCRITTURA FILE SERVICE E TIMER
echo
echo "  ################################################################################"
echo 
echo "    Lo script carica i file per rendere automatico il programma CARMELO "
echo "    e l'invio dei dati. "
echo
echo "  ################################################################################"
echo
sleep 10s

### 1. carmelo.service

echo "[Unit] " | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo "Description= Carmelo " | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo "[Service]" | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo "Type=simple" | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo "User=pi" | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo "ExecStart=/usr/bin/python3 /home/pi/carmelo.py" | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo "Restart=always" | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo "[Install]" | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo "WantedBy=multi-user.target" | sudo tee -a  /etc/systemd/system/carmelo.service > /dev/null
echo

### 2. spedisci.service

echo "[Unit]" | sudo tee -a  /etc/systemd/system/spedisci.service > /dev/null
echo "Description= spedisci file" | sudo tee -a  /etc/systemd/system/spedisci.service > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/spedisci.service > /dev/null
echo "[Service]" | sudo tee -a  /etc/systemd/system/spedisci.service > /dev/null
echo "Type=simple" | sudo tee -a  /etc/systemd/system/spedisci.service > /dev/null
echo "User=pi" | sudo tee -a  /etc/systemd/system/spedisci.service > /dev/null
echo "ExecStart=/usr/bin/python3 /home/pi/spedisci.py" | sudo tee -a  /etc/systemd/system/spedisci.service > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/spedisci.service > /dev/null
echo "[Install]" | sudo tee -a  /etc/systemd/system/spedisci.service > /dev/null
echo "WantedBy=multi-user.target" | sudo tee -a  /etc/systemd/system/spedisci.service > /dev/null
echo

### 3. spedisci.timer

echo "[Unit]" | sudo tee -a  /etc/systemd/system/spedisci.timer > /dev/null
echo "Description= spedisci file" | sudo tee -a  /etc/systemd/system/spedisci.timer > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/spedisci.timer > /dev/null
echo "[Timer]" | sudo tee -a  /etc/systemd/system/spedisci.timer > /dev/null
echo "OnCalendar=*:0/5" | sudo tee -a  /etc/systemd/system/spedisci.timer > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/spedisci.timer > /dev/null
echo "[Install]" | sudo tee -a  /etc/systemd/system/spedisci.timer > /dev/null
echo "WantedBy=timers.target" | sudo tee -a  /etc/systemd/system/spedisci.timer > /dev/null
echo


### 4. receiving_station_data.txt

echo
echo -n "Inserisci la tua localizzazione (potresti scrivere Comune e Provincia, ad es Budrio (BO)): "
read NAME
echo -n "Inserisci la latitudine espressa in decimali (es 44.4567):  "
read LAT
echo -n "Inserisci la longitudine espressa in decimali (es 12.4567)  "
read LNG
echo -n "Inserisci il tipo di antenna usata (Yagi, Ground Plane, Discone ecc….): "
read ANTENNA
echo -n "Inserisci l’angolo di vista della antenna in gradi (es. 360 oppure meno se ci sono ostacoli): "
read VIEW
echo -n "Inserisci la frequenza in herz della portante del trasmettitore sulla quale ci si vuole sintonizzare (es. 143.05e6) : "
read FREQ
echo -n "Scegli il simbolo con il quale si vuole comparire nella rappresentazione complessiva di Carmelo scegliendo tra: 
echo -n "Asterisk, Circle, CircleCross, CircleDot, CircleY, CircleX, Cross, Dash, Diamond"
echo -n "DiamondCross, DiamondDot, Hex, InvertedTriangle, Plus, Square, SquareCross, SquarePin"
echo -n "SquareX, Triangle, TriangleDot, TrianglePin, X, Y: "
read SIMBOLO
echo -n "Inserisci il colore con il quale si vuole comparire nella rappresentazione complessiva di Carmelo (green, red, salmon, gold, orange ecc…. in minuscolo) : "
read COLOR

echo "$NAME" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null
echo "$LAT" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null
echo "$LNG" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null
echo "$ANTENNA" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null
echo "$FREQ" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null
echo "$VIEW" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null
echo "$SIMBOLO" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null
echo "$COLOR" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null
echo

sudo systemctl daemon-reload
sudo systemctl enable carmelo.service
sudo systemctl enable spedisci.timer
sudo systemctl enable spedisci.service
sudo systemctl start carmelo.service
sudo systemctl start spedisci.timer


## RIAVVIO E PASSI SUCCESSIVI
echo
echo "  ################################################################################"
echo 
echo "    Raspberry verrà ora arrestato. CARMELO è pronto per funzionare. "
echo "    Prima di riaccenderlo ricordati di collegare alla presa USB il dongle SDR ed il cavo di antenna."
echo
echo "  ################################################################################"
echo
sleep 20s

sudo /sbin/shutdown -h now
