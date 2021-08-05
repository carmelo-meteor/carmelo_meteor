# CARMELO (Cheap Amatorial Radio MEteor Logger)
# di Lorenzo Barbieri e Gaetano Brando
# versione 2_5 con introduzione finestra

from gpiozero import LED
###---------------------------------accende i led per mostrare che sta caricando
ledverde=LED(17)
ledgiallo=LED(6)
ledrosso=LED(5)
ledgiallo.on()
ledverde.on()
ledrosso.on()
from scipy import signal
from matplotlib import mlab as mlab
from rtlsdr import RtlSdr
import numpy as np
import datetime, sys, os
from pylab import *
from ftplib import FTP
from pathlib import Path
from time import sleep
vers="2_5"
sleep (1)
ledrosso.off()
sdr = RtlSdr()
sleep (1)
ledgiallo.off()

###----------------------------------------legge e carica iparametri di stazione
stazione = [line.rstrip('\n') for line in open('/home/pi/receiving_station_data.txt')]
localita = stazione[0]
lat = float(stazione[1])
long = float(stazione[2])
antenna = stazione[3]
Tx = float(stazione[4])
vista=float(stazione[5])
segno=stazione[6]
colore=stazione[7]
soglia = 0.15  #0.1  ----------------------------soglia per il trigger "meteora"
###-----------------------------------------------------------------------------
sleep (1)
ledverde.off()
###-----------------------------------------------------------caricamento finito
shift = 0.1e6
rxmedio = 50
finestra = 0.0015
cont =  rxm = trig = inizio = 0
contatore =0
contmax = 200   ##---------------------------------------------------------------numero conteggi per stabilire la soglia
trigmax=50      ##---------------------------------------------------------------attesa dopo la meteora prima di chiudere
camp =32768   #65536
sdr.center_freq = Tx-shift
sdr.sample_rate = 1.2e6  # ------------------------------------------------------frequenza di campionamento in Hz
sdr.freq_correction = 1   #----------------------------------------------------- PPM
sdr.gain = 15  ##---5
px=0
rumore=0
rx=frequenza=frequenzaarrot=0

def get_data():
    global rx,frequenza
    frame = sdr.read_samples(camp)  #--------------------------------------------acquisisce lo spettro
    freq,power=signal.periodogram(frame,nfft=1024)
    freq = freq+0.016 + sdr.center_freq/1e6
    rx = frequenza=0
    for i in range(0,1024):  #---------------------------------------------------porzione di spettro
        if power[i]>rx:
            rx=power[i]
            frequenza=freq[i]
meteora=np.empty((0,4))
sleep (2)
ledverde.off()

while True:
    rxprec=rx
    frequenzaprec=frequenza
    frequenzaarrot=round (frequenza,2)
    get_data()
    frequenzaarrot=round (frequenza,2)
    if inizio==0:   #------------------------------------------------------------calcolo del rumore
        rxm=rxm+rx
        cont+=1
        if cont==20:
            ledverde.off()
        if cont>contmax:
            ledverde.on()
            rxmedio=rxm/contmax
            rumore= 10*np.log10(rxmedio)
            cont=rxm=0

            #-------------------------------------------------------manda il messaggio "sono vivo"
            now = datetime.datetime.now()
            midnight = datetime.datetime.combine(now.date(), datetime.time())
            differenza =  round ((now - midnight).seconds/60,1)
            if 0 < differenza < 0.2:
                messaggio="ID" + "_" + localita + str(datetime.datetime.strftime(now,'%Y%m%d_%H%M%S'))+ '.log'
                messaggio = os.path.join("/tmp",messaggio)
                with open(messaggio,"w") as f:
                    riga1 = "# " +"Locality" + ","+"Lat." + ","+"Long." + "," + "Tx freq" + \
                        "," +"Antenna" + "," + "Vista(°)" + "," + "segno" + "," + "colore" +"," + "version"
                    riga2 = localita +","+str(lat) + ","+str(long) + "," + str(Tx/10e5)+\
                        "," + antenna + ","+str(vista)+ "," + segno + "," + colore + "," + vers
                    riga = riga1 +"\n" + riga2
                    f.write(riga)
            #--------------------------------------------------------

    if rx > rxmedio + (rxmedio*soglia) and (Tx/1e6 - finestra) < frequenza < (Tx/1e6 + finestra): #-------------inizio meteora
        trig=trigmax
        if inizio==0:    #-------------------------------------------------------primo istante
            istante = datetime.datetime.utcnow()
            px= 10*np.log10(rxprec)
            snr = 10*np.log10(rxprec/rxmedio)
            meteora = np.append(meteora,np.array([[contatore,px,frequenza,snr]]),axis=0)
            contatore+=1
            px= 10*np.log10(rx)
            snr = 10*np.log10(rx/rxmedio)
            meteora = np.append(meteora,np.array([[contatore,px,frequenza,snr]]),axis=0)
            inizio=1
            ledgiallo.on()
        else:
            contatore+=1
            if contatore ==2:
                secondaf=frequenza
            px= 10*np.log10(rx)
            snr = 10*np.log10(rx/rxmedio)
            meteora = np.append(meteora,np.array([[contatore,px,frequenza,snr]]),axis=0)
    else:
        if inizio==1 and trig!=0:
            contatore+=1
            if contatore ==2:
                secondaf=frequenza
            px= 10*np.log10(rx)
            snr = 10*np.log10(rx/rxmedio)
            meteora = np.append(meteora,np.array([[contatore,px,frequenza,snr]]),axis=0)
    trig-=1

    if trig==1:  #---------------------------------------------------------------fine rilevazione
        ledgiallo.off()
        if contatore>trigmax and round (secondaf,2)==Tx/1e6: #-------------------se è consistente e con due freq==tx allora stampa
            ledrosso.on()
            pippo=np.amax(meteora,axis=0)
            pot_max=round(pippo[3],2)
            fine = datetime.datetime.utcnow()
            durata_camp= (fine-istante)/contatore
            nomefile=str('R'+datetime.datetime.strftime(istante,'%Y%m%d_%H%M%S'))+\
                     "_" + localita + '.log'

            nomefile = os.path.join("/tmp",nomefile)

            with open(nomefile,"w") as f:
                riga1 = "# " +"Locality" + ","+"Lat." + ","+"Long." + "," + "Tx freq" + \
                        "," + "Noise(dB)"+ ","+"Antenna"+ ","+"Gain(dB)"+"," +"Sampling duration(ms)"+","+"Meteor duration (ms)"+","+"Max power(snr)"+","+"Vista(°)" + "," + "segno" + "," + "colore"
                riga2 = localita +","+str(lat) + ","+str(long) + "," + str(Tx/10e5)+\
                        "," + str(round(rumore,2))+"," +antenna + ","+str(sdr.gain)+ ","+str(round(durata_camp.microseconds/1000))+","+\
                        str(round((contatore-trigmax)*(durata_camp.microseconds/1000)))+","+str(pot_max)+\
                        ","+str(vista) + "," + segno + "," + colore
                riga3 ="# " +"Samp" + ","+"Rx power" + ","+"Freq." + "," + "SNR"
                riga = riga1 +"\n" + riga2+"\n" +riga3 +"\n"
                f.write(riga)

                for i in range(len(meteora)):
                    f.write(str(int(meteora[i][0])) + ","+str(round(meteora[i][1],2)) + ","+\
                            str(round(meteora[i][2],6)) + "," + str(round(meteora[i][3],2))+"\n")


            ledrosso.off()
        trig=inizio=rxm=cont=0
        contatore=0
        meteora=np.empty((0,4))



try:
    pass
except KeyboardInterrupt:
     raise SystemExit
finally:
    sdr.close()