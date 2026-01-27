#!/bin/bash
# Diagnóstico SMTP + Amavis + ClamAV — grava tudo em um arquivo de texto
# Uso: ./scripts/diagnose_amavis_smtp.sh
#      ./scripts/diagnose_amavis_smtp.sh resultado.txt
# Saída: diagnostico_smtp_amavis.txt (ou o nome passado como argumento)

set +e

CONTAINER="${CONTAINER:-smtp}"
OUT="${1:-diagnostico_smtp_amavis.txt}"

# Garantir que rodamos na pasta do docker-compose
cd "${0%/*}/.." 2>/dev/null || true

{
  echo "=============================================="
  echo "Diagnóstico SMTP + Amavis + ClamAV"
  echo "Data: $(date -Iseconds 2>/dev/null || date)"
  echo "Arquivo de saída: $OUT"
  echo "=============================================="
  echo ""

  echo "=== 1. Logs do container (clam, amavis, socket, base) ==="
  docker-compose logs "$CONTAINER" 2>&1 | grep -iE 'clam|amavis|socket|base' || echo "(nenhuma linha encontrada)"
  echo ""

  echo "=== 2. ClamAV: log de arranque do clamd ==="
  docker-compose exec -T "$CONTAINER" cat /tmp/clamd_start.log 2>/dev/null || echo "(arquivo não encontrado ou vazio)"
  echo ""

  echo "=== 3. ClamAV: conteúdo de /var/lib/clamav/ ==="
  docker-compose exec -T "$CONTAINER" ls -la /var/lib/clamav/ 2>/dev/null || echo "(erro ao listar)"
  echo ""

  echo "=== 4. ClamAV: diretórios do socket ==="
  docker-compose exec -T "$CONTAINER" ls -la /var/run/clamav/ /run/clamav/ 2>/dev/null || echo "(erro ou diretórios inexistentes)"
  echo ""

  echo "=== 5. Processos clam e amavis ==="
  docker-compose exec -T "$CONTAINER" ps aux 2>/dev/null | grep -E 'clam|amavis' | grep -v grep || echo "(nenhum processo clam/amavis encontrado)"
  echo ""

  echo "=== 6. Amavis: saída de amavisd debug (primeiras 80 linhas) ==="
  docker-compose exec -T "$CONTAINER" sh -c 'timeout 10 amavisd debug 2>/dev/null || timeout 10 amavisd-new debug 2>/dev/null || amavisd debug 2>/dev/null || amavisd-new debug' 2>&1 | head -80
  echo ""

  echo "=== 7. Fila do Postfix (postqueue -p) ==="
  docker-compose exec -T "$CONTAINER" postqueue -p 2>&1 || echo "(erro ao obter fila)"
  echo ""

  echo "=== 8. Quarentena Amavis (virusmails) ==="
  docker-compose exec -T "$CONTAINER" ls -la /var/lib/amavis/virusmails/ 2>/dev/null || echo "(erro ou diretório inexistente)"
  echo ""

  echo "=== 9. Maildir user1 — arquivos novos (últimos 5 min) ==="
  docker-compose exec -T "$CONTAINER" find /var/mail/vhosts/empresa.local/user1/Maildir -mmin -5 -type f 2>/dev/null || echo "(erro ou nenhum arquivo)"
  echo ""

  echo "=== 10. Últimas 60 linhas do mail.log (relacionadas a amavis/clam/defer) ==="
  docker-compose exec -T "$CONTAINER" tail -200 /var/log/mail.log 2>/dev/null | grep -iE 'amavis|clam|defer|content_filter|10024|virus' || echo "(nenhuma linha ou mail.log inacessível)"
  echo ""

  echo "=============================================="
  echo "Fim do diagnóstico. Abra o arquivo: $OUT"
  echo "=============================================="
} 2>&1 | tee "$OUT"

echo ""
SAVED="$(pwd)/$OUT"
echo "Resultado salvo em: $SAVED"
echo "Para ver: cat \"$OUT\"   ou   less \"$OUT\"   ou abra o arquivo no editor."
