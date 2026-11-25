#!/bin/sh
# Entrada da imagem web para o Portainer: gera o cliente em segundo plano
# (para o site subir na hora) e depois segue o entrypoint original.
/usr/local/bin/gerar-cliente.sh &
exec /entrypoint.sh "$@"
