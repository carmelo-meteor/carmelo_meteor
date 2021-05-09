from ftplib import FTP
from pathlib import Path
import os

path = os.chdir("/tmp")#.dirname(os.path.realpath(__file__)) #imposta la directory in cui lavora
elenco = [f for f in os.listdir(path) if f.endswith('.log')]


for file in elenco:
    file_path = Path(file)
    print(file_path)

    with FTP('ftp.womera.altervista.org', 'womera', 'Carmelo2') as ftp, open(file_path, 'rb') as file:
        ftp.storbinary(f'STOR {file_path.name}', file)

    os.unlink(file_path)