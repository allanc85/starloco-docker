#!/bin/sh
# Gera o cliente Dofus Retro 1.39.8 já apontando para este servidor e publica em
# http://<GAME_SERVER_IP>[:WEB_PORT]/cliente/<CLIENT_DOWNLOAD_TOKEN>.zip
# Só refaz o ZIP quando o IP, o nome, o token ou a imagem mudam.
set -eu

SRC=/opt/dofus-client
OUT=/runtime/client
IP="${GAME_SERVER_IP:-}"
TOKEN="$(printf '%s' "${CLIENT_DOWNLOAD_TOKEN:-}" | tr -cd 'A-Za-z0-9_-')"
NOME="$(printf '%s' "${GAME_SERVER_NAME:-StarLoco}" | tr -cd 'A-Za-z0-9_-')"
PORTA="$(printf '%s' "${WEB_PORT:-80}" | tr -cd '0-9')"
PORTA="${PORTA:-80}"
if [ "$PORTA" = "80" ]; then BASE="http://$IP"; else BASE="http://$IP:$PORTA"; fi

if [ -z "$IP" ] || [ -z "$TOKEN" ]; then
  echo "[cliente] GAME_SERVER_IP ou CLIENT_DOWNLOAD_TOKEN vazio: download do cliente desativado."
  exit 0
fi
if ! printf '%s' "$IP" | grep -Eq '^[A-Za-z0-9.-]+$'; then
  echo "[cliente] GAME_SERVER_IP inválido: '$IP'"
  exit 1
fi

CFG_REL="resources/app/retroclient/config.xml"
ASSINATURA="$IP|$PORTA|$NOME|$TOKEN|$(md5sum "$SRC/$CFG_REL" | cut -d' ' -f1)"
mkdir -p "$OUT"
if [ -f "$OUT/$TOKEN.zip" ] && [ "$(cat "$OUT/.assinatura" 2>/dev/null)" = "$ASSINATURA" ]; then
  echo "[cliente] ZIP já está atualizado: /cliente/$TOKEN.zip"
  exit 0
fi

echo "[cliente] Gerando o cliente para $IP (leva cerca de 1 minuto)..."
TMP="$(mktemp -d)"
cp -R "$SRC" "$TMP/Dofus-StarLoco"
sed -i "s/127\.0\.0\.1/$IP/g" "$TMP/Dofus-StarLoco/$CFG_REL"
sed -i "s/name=\"Shogun\"/name=\"$NOME\"/" "$TMP/Dofus-StarLoco/$CFG_REL"
# Dados do jogo (mapas, textos) vêm do site; ajusta a porta se não for a 80
sed -i "s#url=\"http://$IP/\"#url=\"$BASE/\"#" "$TMP/Dofus-StarLoco/$CFG_REL"
( cd "$TMP" && zip -qr "$OUT/.novo.zip" Dofus-StarLoco )
rm -f "$OUT"/*.zip
mv "$OUT/.novo.zip" "$OUT/$TOKEN.zip"
printf '%s' "$ASSINATURA" > "$OUT/.assinatura"
chmod 755 "$OUT"
chmod 644 "$OUT/$TOKEN.zip"
rm -rf "$TMP"
echo "[cliente] Pronto: $BASE/cliente/$TOKEN.zip"
