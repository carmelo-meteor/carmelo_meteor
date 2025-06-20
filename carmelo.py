# CARMELO (Cheap Amatorial Radio MEteor Logger)
# di Lorenzo Barbieri e Gaetano Brando
## dimezzato l'ampiezza del campione
## ripulito
## ms nel titolo
vers="Carmelo2_38"

from gpiozero import LED,Button
###------------------------------------------------------------------------------accende i led per mostrare che sta caricando
ledverde=LED(17)
ledgiallo=LED(6)
ledrosso=LED(5)
ledgiallo.on()
ledverde.on()
ledrosso.on()
from scipy import signal
from rtlsdr import RtlSdr
import numpy as np
import datetime, sys, os
from pathlib import Path
from time import sleep
import time

sleep (1)
ledrosso.off()
sdr = RtlSdr()
sleep (1)
ledgiallo.off()

###------------------------------------------------------------------------------legge e carica i parametri di stazione
stazione = [line.rstrip('\n') for line in open('/home/pi/receiving_station_data.txt')]
localita = stazione[0]
lat = float(stazione[1])
long = float(stazione[2])
antenna = stazione[3]
Tx = float(stazione[4])
vista=float(stazione[5])
segno=stazione[6]
colore=stazione[7]
soglia = 0.1  #0.05  ------------------------------------------------------------soglia sul rumore per il trigger "meteora"
###-----------------------------------------------------------------------------
sleep (1)
ledverde.off()
###------------------------------------------------------------------------------caricamento finito
button = Button(26)
camp = 4096     #8192
shift = 0.1e6
rxmedio = 50
finestra = Tx/(15e9)    #14  KHz (per Graves)
finestrina= Tx/(150e9)  #1.4 KHz
falspos=3

cont =  rxm = trig = inizio = 0
contatore =0
contmax = 500   ##---------------------------------------------------------------numero conteggi per stabilire la soglia
trigmax=35      ##--------------50-----------------------------------------------attesa dopo la meteora prima di chiudere
sdr.center_freq = Tx-shift
sdr.sample_rate = 1.2e6  # 1.2e6-------------------------------------------------frequenza di campionamento in Hz!!!!!
sdr.freq_correction = 1   #  1 --------------------------------------------------PPM
sdr.gain = 43.4
diff_gain = 55

if button.is_pressed:
    pre_gain = 20##----preampl NOOELECT
else:
    pre_gain = 15##----preampl cinese

if localita in ['AAB Hayfield - Derbyshire (UK)','GAV Arcugnano - VI(ITA)']: ##da togliere
    pre_gain = 20##----preampl NOOELECT
sdr.bandwidth=6000#----Hz
px=0
rumore=0
rx=frequenza=0
ggg=0


def get_data(rx, frequenza):
    frame = sdr.read_samples(camp)  #--------------------------------------------acquisisce lo spettro
    freq, power = signal.periodogram(frame, fs=1.0, window='boxcar') #---------------effettua l'FFT
    freq = freq+0.016 + sdr.center_freq/1e6
    rx = frequenza=0
    rx = power.max()
    pow_index = power.argmax() # --- per avere l'indice del valore massimo
    frequenza = freq[pow_index]
    return rx, frequenza

meteora=np.empty((0,4))
sleep (2)
ledverde.off()

while True:
    rxprec=rx
    freqprec=frequenza
    rx, frequenza = get_data(rx, frequenza)
    if inizio==0:   #------------------------------------------------------------calcolo del rumore
        rxm=rxm+rx
        cont+=1
        if cont==20:
            ledverde.off()
        if cont>contmax:
            ledverde.on()
            ledrosso.off()
            rxmedio=rxm/contmax
            rumore= (10*np.log10(rxmedio)) - sdr.gain - diff_gain - pre_gain
            cont=rxm=0
            #--------------------------------------------------------------------manda il messaggio "sono vivo"
            d = datetime.date.today()
            if ggg != d.day:
                ledrosso.on()
                ggg = d.day
                now = datetime.datetime.now()
                messaggio="ID" + "_" + localita + str(datetime.datetime.strftime(now,'%Y%m%d_%H%M%S'))+ '.log'
                messaggio = os.path.join("/tmp",messaggio)
                with open(messaggio,"w") as f:
                    riga1 = "# " +"Locality" + ","+"Lat." + ","+"Long." + "," + "Tx freq" + \
                        "," +"Antenna" + "," + "Vista(°)" + "," + "segno" + "," + "colore" + "," + "version"+ "," + "n° Falsi positivi"
                    riga2 = localita +","+str(lat) + ","+str(long) + "," + str(Tx/10e5)+\
                        "," + antenna + ","+str(vista)+ "," + segno + "," + colore + "," + vers+ ","  +str(falspos)
                    riga = riga1 +"\n" + riga2
                    f.write(riga)
                    falspos=0
                    sleep (1)
                    ledrosso.off()

            #--------------------------------------------------------------------

    if rx > rxmedio + (rxmedio*soglia) and (Tx/1e6 - finestrina) < frequenza < (Tx/1e6 + finestra): #-------------inizio meteora
        trig=trigmax
        if inizio==0:    #-------------------------------------------------------primo istante
            istante = datetime.datetime.utcnow()
            px= (10*np.log10(rxprec)) - sdr.gain - diff_gain - pre_gain
            snr = px-rumore
            meteora = np.append(meteora,np.array([[contatore,px,freqprec,snr]]),axis=0)
            contatore+=1
            px= (10*np.log10(rx)) - sdr.gain - diff_gain - pre_gain
            snr = px-rumore
            meteora = np.append(meteora,np.array([[contatore,px,frequenza,snr]]),axis=0)
            inizio=1
            ledgiallo.on()
        else:
            contatore+=1
            if contatore ==2:
                secondaf=frequenza
            px= (10*np.log10(rx)) - sdr.gain - diff_gain - pre_gain
            snr = px-rumore
            meteora = np.append(meteora,np.array([[contatore,px,frequenza,snr]]),axis=0)
    else:
        if inizio==1 and trig!=0:
            contatore+=1
            if contatore ==2:
                secondaf=frequenza
            px= (10*np.log10(rx)) - sdr.gain - diff_gain - pre_gain
            snr = px-rumore
            meteora = np.append(meteora,np.array([[contatore,px,frequenza,snr]]),axis=0)
    trig-=1


    if trig==1:  #---------------------------------------------------------------fine rilevazione
        ledgiallo.off()
        if contatore>trigmax and round (secondaf,2)==Tx/1e6: #---------------------------------------------se è consistente e con le due prime freq==tx
            listafreq = meteora[2:-33,2:3]
            (sorted_data, idx, counts) = np.unique(listafreq, return_index=True, return_counts=True)# calcola la moda
            index = idx[np.argmax(counts)]
            moda=float(listafreq[index])*1e6
            delta = Tx - (moda)


            if  abs(delta)<1000 and max(counts)>1:#---------------------------------------------------se la moda è a meno di 1 KHz da Tx allora stampa
                ledrosso.on()
                pippo=np.amax(meteora,axis=0)
                sdr_max=round(pippo[3],2)
                pot_max=round(pippo[1],2)##-----------------------------------------------nuovo----------------------------------------
                fine = datetime.datetime.utcnow()
                durata_camp= (fine-istante)/contatore
                ms=int((istante.microsecond)/1000)
                nomefile=str('R'+datetime.datetime.strftime(istante,'%Y%m%d_%H%M%S'))+str(ms)+\
                         "_" + localita + '.log'
                nomefile = os.path.join("/tmp",nomefile)

                with open(nomefile,"w") as f:
                    riga1 = "# " +"Locality" + ","+"Lat." + ","+"Long." + "," + "Tx freq" + \
                            "," + "Noise(dB)"+ ","+"Antenna"+ ","+"Gain(dB)"+"," +"Sampling duration(ms)"+","+"Meteor duration (ms)"+","+"Max snr"+","+"Vista(°)" +\
                             "," + "segno" + "," + "colore" + "," + "Max power" + "," + "ms"+","+"pre-gain"
                    riga2 = localita +","+str(lat) + ","+str(long) + "," + str(Tx/10e5)+\
                            "," + str(round(rumore,2))+"," +antenna + ","+str(sdr.gain)+ ","+str(durata_camp.microseconds/1000)+","+\
                            str(round((contatore-trigmax)*(durata_camp.microseconds/1000)))+","+str(sdr_max)+\
                            ","+str(vista) + "," + segno + "," + colore + "," + str(pot_max) + "," + str(ms)+ "," + str(pre_gain)
                    riga3 ="# " +"Samp" + ","+"Rx power" + ","+"Freq." + "," + "SNR"
                    riga = riga1 +"\n" + riga2+"\n" +riga3 +"\n"
                    f.write(riga)
                    for i in range(len(meteora)):
                        f.write(str(int(meteora[i][0])) + ","+str(round(meteora[i][1],2)) + ","+\
                                str(round(meteora[i][2],6)) + "," + str(round(meteora[i][3],2))+"\n")
            else:
                 falspos += 1

        trig=inizio=rxm=cont=0
        contatore=0
        meteora=np.empty((0,4))



try:
    pass
except KeyboardInterrupt:
     raise SystemExit
finally:
    sdr.close()