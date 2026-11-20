
#!/usr/bin/env bash
set -Eeuo pipefail

BASE_URL="${BASE_URL:-http://localhost:8003}"

# Função para verificar os endpoints
verificar_endpoint() {
    local endpoint="$1"
    local esperado=200
    local resultado

    resultado=$(curl -s -o /dev/null -w "%{http_code}" \
        "${BASE_URL}${endpoint}") || resultado="000"

    if [[ "$resultado" == "$esperado" ]]; then
        echo "SUCESSO: ${endpoint} - HTTP ${resultado}"
        return 0
    else
        echo "ERRO: ${endpoint} - HTTP ${resultado} (esperado ${esperado})"
        return 1
    fi
}

echo "A validar API: ${BASE_URL}"

falhas=0

# 1. Verificação de /health
verificar_endpoint "/health" || falhas=$((falhas + 1))

# 2. Verificação de /ready
verificar_endpoint "/ready" || falhas=$((falhas + 1))

# 3. Verificação de /api/status
verificar_endpoint "/api/status" || falhas=$((falhas + 1))

# 4. Mensagem final
if [[ "$falhas" -eq 0 ]]; then
    echo "SUCESSO: Todos os testes passaram."
    exit 0
else
    echo "ERRO: Foram encontradas ${falhas} falha(s)."
    exit 1
fi
