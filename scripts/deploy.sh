
#!/usr/bin/env bash

# 1. Validar argumentos
if [ "$#" -ne 2 ]; then
    echo "Uso: ./scripts/deploy.sh <nova_versao> <versao_estavel>"
    exit 1
fi

NOVA_VERSAO=$1
VERSAO_ESTAVEL=$2

echo "A instalar versão $NOVA_VERSAO..."

# 2. Fazer deployment e aguardar os serviços
APP_VERSION=$NOVA_VERSAO docker compose \
    -f compose.yaml \
    --env-file config/.env.prod \
    -p fp07-prod \
    up -d --pull always --force-recreate --wait --wait-timeout 90

# 3. Verificar se o deployment funcionou
if [ $? -eq 0 ]; then
    echo "Containers iniciados."
else
    echo "Erro ao iniciar os containers."
fi

# 4. Executar smoke tests
bash scripts/smoke-test.sh

# 5. Verificar o resultado dos testes
if [ $? -eq 0 ]; then
    echo "Deployment realizado com sucesso!"
    exit 0
fi

echo "ERRO: O deployment falhou!"

# 6. Pedir autorização para rollback
read -r -p "Deseja voltar à versão $VERSAO_ESTAVEL? (s/n): " resposta

if [ "$resposta" != "s" ]; then
    echo "Rollback cancelado."
    exit 1
fi

# 7. Executar rollback
echo "A recuperar versão $VERSAO_ESTAVEL..."

APP_VERSION=$VERSAO_ESTAVEL docker compose \
    -f compose.yaml \
    --env-file config/.env.prod \
    -p fp07-prod \
    up -d --pull always --force-recreate --wait --wait-timeout 90

if [ $? -ne 0 ]; then
    echo "ERRO: O rollback falhou."
    exit 1
fi

# 8. Validar após rollback
bash scripts/smoke-test.sh

if [ $? -eq 0 ]; then
    echo "Rollback realizado com sucesso!"
else
    echo "ERRO: A aplicação continua com problemas."
fi

exit 1
