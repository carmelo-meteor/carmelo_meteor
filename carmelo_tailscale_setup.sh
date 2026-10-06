#!/bin/bash
# CARMELO - Setup Tailscale + SSH remoto
# Eseguire come root durante il montaggio della stazione

set -e

# ─── Configurazione ───────────────────────────────────────────
# Inserire qui la propria auth key di Tailscale (Settings → Keys)
# Usare una "reusable auth key" per non doverla cambiare ogni volta
TAILSCALE_AUTHKEY="tskey-auth-kPb1KzKxZR11CNTRL-KtCgmxSUgWHhJZ9FjvYuVHinMBFnUPdXP"
# ──────────────────────────────────────────────────────────────

echo ""
echo "=== CARMELO - Setup Tailscale + SSH ==="
echo ""

# 1. Nome della stazione
read -rp "Inserisci il nome della stazione (es. carmelo-budrio, carmelo-napoli): " STATION_NAME

if [[ -z "$STATION_NAME" ]]; then
  echo "Errore: il nome non può essere vuoto."
  exit 1
fi

# 2. Imposta hostname
echo ""
echo "→ Imposto hostname: $STATION_NAME"
hostnamectl set-hostname "$STATION_NAME"
sed -i "s/127.0.1.1.*/127.0.1.1\t$STATION_NAME/" /etc/hosts

# 3. Assicurati che SSH sia installato e attivo
echo "→ Verifico SSH..."
apt-get install -y openssh-server -qq
systemctl enable --now ssh

# 4. Installa Tailscale
echo "→ Installo Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

# 5. Abilita e avvia Tailscale
echo "→ Avvio il servizio Tailscale..."
systemctl enable --now tailscaled

# 6. Autentica con il tuo account e abilita SSH via Tailscale
echo "→ Connetto al tuo account Tailscale..."
tailscale up --authkey="$TAILSCALE_AUTHKEY" --hostname="$STATION_NAME" --ssh

# 7. Aspetta che Tailscale sia online
echo "→ Aspetto che Tailscale sia online..."
for i in $(seq 1 30); do
  TSHOST=$(tailscale status --json 2>/dev/null | python3 -c \
    "import json,sys; d=json.load(sys.stdin); h=d.get('Self',{}).get('DNSName',''); print(h.rstrip('.')) if h else exit(1)" 2>/dev/null) && break
  sleep 2
done

if [[ -z "$TSHOST" ]]; then
  echo "Errore: Tailscale non si è connesso. Verifica la auth key."
  exit 1
fi

# 8. Mostra IP Tailscale
TSIP=$(tailscale ip -4)

echo ""
echo "✓ Fatto! La stazione '$STATION_NAME' è pronta."
echo ""
echo "  Accesso SSH (hostname): ssh pi@$TSHOST"
echo "  Accesso SSH (IP):       ssh pi@$TSIP"
echo ""
