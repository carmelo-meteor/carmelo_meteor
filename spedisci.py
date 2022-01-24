#versione del 24-01-2022 ore 19.22

from pathlib import Path
import os
from paho.mqtt.client import Client
import time

#versione 3

keyword = "ID"
path = os.chdir("tmp")#.dirname(os.path.realpath(__file__)) #imposta la directory in cui lavora

elenco = [f for f in os.listdir(path) if f.endswith('.log')]

client = Client()

client.connect('3.22.58.103', 1883)

for file in elenco:

        if keyword in file:
            genere = "sono_vivo"
        else:
            genere = "meteora"

        with open(file) as inputfile:
            nome_file = str(file)
            testo_file = inputfile.read()
            testo_messaggio = nome_file + testo_file
            client.publish(topic=genere, payload=testo_messaggio)

        os.unlink(Path(file))

        print(nome_file, " sent")
