#!/bin/bash


echo
echo "                    CARMELO installer versione 0.6  del 13-06-21                     "
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
sudo apt-get dist-upgrade

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
python3 -m pip install pyrtlsdr==0.2.91 scipy paho-mqtt
echo
sudo apt-get install libusb-1.0-0.dev git cmake build-essential bc
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


### 4. update.service
echo "[Unit]" | sudo tee -a  /etc/systemd/system/update.service > /dev/null
echo "Description= update git" | sudo tee -a  /etc/systemd/system/update.service > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/update.service > /dev/null
echo "[Service]" | sudo tee -a  /etc/systemd/system/update.service > /dev/null
echo "Type=simple" | sudo tee -a  /etc/systemd/system/update.service > /dev/null
echo "User=pi" | sudo tee -a  /etc/systemd/system/update.service > /dev/null
echo "ExecStart=/home/pi/update.sh" | sudo tee -a  /etc/systemd/system/update.service > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/update.service > /dev/null
echo "[Install]" | sudo tee -a  /etc/systemd/system/update.service > /dev/null
echo "WantedBy=default.target" | sudo tee -a  /etc/systemd/system/update.service > /dev/null
echo

### 5. update.timer

echo "[Unit]" | sudo tee -a  /etc/systemd/system/update.timer > /dev/null
echo "Description= update git" | sudo tee -a  /etc/systemd/system/update.timer > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/update.timer > /dev/null
echo "[Timer]" | sudo tee -a  /etc/systemd/system/update.timer > /dev/null
echo "OnCalendar=*-*-* 18:01:30" | sudo tee -a  /etc/systemd/system/update.timer > /dev/null
echo " " | sudo tee -a  /etc/systemd/system/update.timer > /dev/null
echo "[Install]" | sudo tee -a  /etc/systemd/system/update.timer > /dev/null
echo "WantedBy=timers.target" | sudo tee -a  /etc/systemd/system/update.timer > /dev/null
echo

### 6. receiving_station_data.txt

segno=("asterisk" "circle" "circle_cross" "circle_dot" "circle_x" "circle_y" "cross" "dash" "diamond" "diamond_cross" "diamond_dot" "dot" "hex" "hex_dot" "inverted_triangle" "plus" "square" "square_cross" "square_dot" "square_pin" "square_x" "star" "star_dot" "triangle" "triangle_dot" "triangle_pin" "x" "y")
colori=("green" "red" "salmon" "gold" "orange" "black" "brown" "purple" "blue")

echo
echo -n "Inserisci la tua localizzazione e qui potresti scrivere Comune e Provincia (es.: Budrio (BO)): "
read NAME

echo "$NAME" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null

while :; do
    echo -n "Inserisci la latitudine espressa in decimali (es. 44.4567):  "
    read LAT
    [[ $LAT =~ ^[+-]?[0-9]+\.?[0-9]*$ ]] || { echo "Use point instead of common"; continue; } 
    [[ $(bc <<< "$LAT > -90 && $LAT <= 90") == 1 ]] || { echo "error: value out of range"; continue; } 
    echo "$LAT" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null
    break  
done

while :; do
    echo -n "Inserisci la longitudine espressa in decimali (es. 11.0909):  "
    read LNG
    [[ $LNG =~ ^[+-]?[0-9]+\.?[0-9]*$ ]] || { echo "Use point instead of common"; continue; } 
    [[ $(bc <<< "$LNG > 0 && $LNG < 360") == 1 ]] || { echo "error: value out of range"; continue; } 
    echo "$LNG" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null
    break  
done

echo -n "Inserisci il tipo di antenna usata es.: Yagi, Ground Plane, Discone ecc….: "
read ANTENNA
echo "$ANTENNA" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null

while :; do
    echo -n "Inserisci la frequenza della portante del trasmettitore sulla quale ci si vuole sintonizzare (in herz) es.: 143.05e6 : "
    read FREQ
    [[ $FREQ =~ ^[+-]?[0-9]+\.?[0-9]+\e?[0-9]*$ ]] || { echo "Use point instead of common"; continue; } 
    echo "$FREQ" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null
    break
done




while :; do
    echo -n "Inserisci l’angolo di vista della antenna in gradi es.: 360 oppure meno se ci sono ostacoli: "
    read VIEW
    [[ $VIEW =~ ^[+-]?[0-9]*$ ]] || { echo "Use integer"; continue; } 
    [[ $(bc <<< "$VIEW > 0 && $VIEW < 361") == 1 ]] || { echo "error: value out of range"; continue; } 
    echo "$VIEW" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null
    break  
done


while :; do
    echo -n "Inserisci il simbolo con il quale si vuole comparire nella rappresentazione complessiva di Carmelo scegliendo tra: asterisk circle circle_cross circle_dot circle_x circle_y cross dash    diamond diamond_cross diamond_dot dot hex hex_dot inverted_triangle plus square square_cross square_dot square_pin square_x star star_dot triangle triangle_dot triangle_pin x y : "
    read SIMBOLO
    [[ " ${segno[*]} " == *" $SIMBOLO "* ]] || { echo "Error: enter a correct simbol"; continue; } 
    echo "$SIMBOLO" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null
    break  	
done

while :; do
    echo -n "Inserisci il colore con il quale si vuole comparire nella rappresentazione complessiva di Carmelo es.: green, red, salmon, gold, orange ecc….(sempre in minuscolo) : "
    read COLOR
    [[ " ${colori[*]} " == *" $COLOR "* ]] || { echo "Error: enter a correct color name"; continue; } 
    echo "$COLOR" | sudo tee -a  /home/pi/receiving_station_data.txt > /dev/null
    break  	
done

sudo systemctl daemon-reload
sudo systemctl enable carmelo.service
sudo systemctl enable spedisci.timer
sudo systemctl enable spedisci.service
sudo systemctl enable update.timer
sudo systemctl enable update.service
sudo systemctl start carmelo.service
sudo systemctl start spedisci.timer
sudo systemctl start update.timer


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
