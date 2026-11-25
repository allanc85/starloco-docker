# StarLoco no Portainer

Este fork (branch `portainer`) adiciona uma stack que o Portainer (Community ou Business) consegue
implantar direto do Git, sem `build`, bind mounts nem arquivos de segredo.

| Arquivo | Para quê |
| --- | --- |
| `docker-compose.portainer.yml` | Stack do Portainer: imagens do GHCR + variáveis de ambiente |
| `.github/workflows/portainer-images.yml` | Gera e publica as imagens `ghcr.io/<dono>/starloco-*` |
| `db/Dockerfile` | MariaDB com `db-init/` embutido |
| `web/Dockerfile.portainer`, `web/nginx.portainer.conf` | Site com `public/` e o cliente embutidos |
| `web/gerar-cliente.sh`, `web/entrypoint-portainer.sh` | Gera o cliente com o IP do servidor em `/cliente/<token>.zip` |

Nenhum arquivo do projeto original foi alterado. A branch `main` do fork continua igual à do
projeto original (use **Sync fork** no GitHub) e a `portainer` só acrescenta arquivos:
para atualizar, faça merge da `main` na `portainer`.

## 1. Gerar as imagens (uma vez, e a cada atualização)

1. No fork, aba **Actions** → habilite os workflows (forks vêm com eles desligados).
2. Escolha **Imagens para o Portainer** → **Run workflow**, na branch `portainer`. Leva de 10 a 20 minutos.
3. Em **Packages** (no seu perfil), confira os 5 pacotes `starloco-*`. Se estiverem
   privados, torne-os públicos ou cadastre o GHCR em Portainer → Registries
   com um token `read:packages`.

## 2. Gerar as senhas

Rode em qualquer terminal (na VPS, por exemplo) e guarde o resultado:

```bash
echo "MARIADB_ROOT_PASSWORD=$(openssl rand -hex 24)"
echo "STARLOCO_DB_PASSWORD=$(openssl rand -hex 24)"
echo "EXCHANGE_KEY=$(openssl rand -base64 32)"
echo "GAME_SERVER_KEY=$(openssl rand -hex 8)"
echo "CLIENT_DOWNLOAD_TOKEN=$(openssl rand -hex 8)"
```

As senhas do banco só valem na primeira inicialização. Para trocá-las depois,
é preciso alterar o usuário dentro do MariaDB ou apagar o volume `mariadb_data`.

## 3. Criar a stack

Portainer → **Stacks** → **Add stack** → **Repository**:

- Repository URL: `https://github.com/allanc85/starloco-docker`
- Repository reference: `refs/heads/portainer`
- Compose path: `docker-compose.portainer.yml`
- Environment variables → **Advanced mode**, cole:

```env
IMAGE_PREFIX=ghcr.io/allanc85/starloco
GAME_SERVER_IP=<IP público da VPS>
GAME_SERVER_NAME=Amigos
WEB_PORT=80
RATE_XP=1
RATE_DROP=1
RATE_KAMAS=1
MARIADB_ROOT_PASSWORD=...
STARLOCO_DB_PASSWORD=...
EXCHANGE_KEY=...
GAME_SERVER_KEY=...
CLIENT_DOWNLOAD_TOKEN=...
```

A primeira subida leva alguns minutos, porque o banco importa cerca de 75 MB de SQL.

## 4. Portas

| Porta | Serviço | Pública? |
| --- | --- | --- |
| 450 | login | sim |
| 5555 | jogo | sim |
| `WEB_PORT` (80) | site, dados do jogo e download do cliente | sim |
| 3306 / 6379 / 8000 | MariaDB / Redis / Zaap | não (sem `ports`) |

Se a porta 80 já estiver em uso (por um proxy reverso, por exemplo), defina `WEB_PORT`
com outra porta. O cliente gerado já sai apontando para ela.

## 5. Cliente e contas

- Cliente: `http://<GAME_SERVER_IP>[:WEB_PORT]/cliente/<CLIENT_DOWNLOAD_TOKEN>.zip`
  (gerado em segundo plano cerca de 1 minuto depois de o `web` subir; veja os logs do `web`).
- Contas: Portainer → Containers → `mariadb` → **Console** (`/bin/bash`):

```bash
mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" starloco_login -e "INSERT INTO world_accounts (account, pass, pseudo) VALUES ('LOGIN', SHA2(MD5('SENHA'), 512), 'APELIDO');"
```

A conta de teste `test` / `test` vem no banco. Apague-a num servidor público:

```bash
mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" starloco_login -e "DELETE FROM world_accounts WHERE account='test';"
```
