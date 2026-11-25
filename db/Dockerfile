# Banco para o Portainer: MariaDB com os scripts de db-init/ embutidos
# (no compose original eles são montados de ./db-init).
# Build a partir da raiz do repositório:  docker build -f db/Dockerfile .
FROM mariadb:11.3
COPY db-init/ /docker-entrypoint-initdb.d/
