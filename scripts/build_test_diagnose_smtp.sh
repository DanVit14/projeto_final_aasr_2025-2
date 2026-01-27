#!/bin/bash
# Fluxo completo: build → up → espera → testes (envio, EICAR, antispam) → diagnóstico
# Toda a saída vai para um único arquivo de texto.
#
# Uso: ./scripts/build_test_diagnose_smtp.sh
#      ./scripts/build_test_diagnose_smtp.sh resultado_completo.txt
# Saída: build_test_diagnose_smtp.txt (ou o nome passado)

set +e

ROOT="$(cd "${0%/*}/.." && pwd)"
OUT="${1:-build_test_diagnose_smtp.txt}"
OUTPATH="$ROOT/$OUT"
CONTAINER="${CONTAINER:-smtp}"

{
  cd "$ROOT" || exit 1
  echo "=============================================="
  echo "BUILD → UP → TESTES → DIAGNÓSTICO (SMTP/Amavis/ClamAV)"
  echo "Data: $(date -Iseconds 2>/dev/null || date)"
  echo "Pasta: $ROOT"
  echo "Arquivo de saída: $OUTPATH"
  echo "=============================================="
  echo ""

  echo "========== 1. BUILD (docker-compose build smtp --no-cache) =========="
  docker-compose build smtp --no-cache
  echo ""

  echo "========== 2. UP (docker-compose up -d smtp) =========="
  docker-compose up -d smtp
  echo ""

  echo "========== 3. ESPERANDO 90s para serviços subirem =========="
  sleep 90
  echo ""

  echo "========== 4. ENVIO DE E-MAIL DE TESTE (send_test_email.sh) =========="
  ./scripts/send_test_email.sh 2>&1 || true
  echo ""
  sleep 15

  echo "========== 5. TESTE EICAR - ANTIVÍRUS (test_eicar.sh) =========="
  ./scripts/test_eicar.sh 2>&1 || true
  echo ""
  sleep 15

  echo "========== 6. TESTE ANTISPAM (test_antispam.sh) =========="
  ./scripts/test_antispam.sh 2>&1 || true
  echo ""
  sleep 20

  echo "========== 7. DIAGNÓSTICO - Logs (clam, amavis, socket, base) =========="
  docker-compose logs "$CONTAINER" 2>&1 | grep -iE 'clam|amavis|socket|base' || echo "(nenhuma linha encontrada)"
  echo ""

  echo "========== 8. DIAGNÓSTICO - Log clamd (/tmp/clamd_start.log) =========="
  docker-compose exec -T "$CONTAINER" cat /tmp/clamd_start.log 2>/dev/null || echo "(arquivo não encontrado ou vazio)"
  echo ""

  echo "========== 9. DIAGNÓSTICO - /var/lib/clamav/ =========="
  docker-compose exec -T "$CONTAINER" ls -la /var/lib/clamav/ 2>/dev/null || echo "(erro ao listar)"
  echo ""

  echo "========== 10. DIAGNÓSTICO - Socket clamd (/var/run/clamav, /run/clamav) =========="
  docker-compose exec -T "$CONTAINER" ls -la /var/run/clamav/ /run/clamav/ 2>/dev/null || echo "(erro ou inexistentes)"
  echo ""

  echo "========== 11. DIAGNÓSTICO - Processos clam e amavis =========="
  docker-compose exec -T "$CONTAINER" ps aux 2>/dev/null | grep -E 'clam|amavis' | grep -v grep || echo "(nenhum processo)"
  echo ""

  echo "========== 12. DIAGNÓSTICO - amavisd-new debug (80 linhas) =========="
  docker-compose exec -T "$CONTAINER" timeout 10 amavisd-new debug 2>&1 | head -80 || docker-compose exec -T "$CONTAINER" amavisd-new debug 2>&1 | head -80
  echo ""

  echo "========== 13. DIAGNÓSTICO - Fila Postfix (postqueue -p) =========="
  docker-compose exec -T "$CONTAINER" postqueue -p 2>&1 || echo "(erro)"
  echo ""

  echo "========== 14. DIAGNÓSTICO - Quarentena Amavis (virusmails) =========="
  docker-compose exec -T "$CONTAINER" ls -la /var/lib/amavis/virusmails/ 2>/dev/null || echo "(erro ou inexistente)"
  echo ""

  echo "========== 15. DIAGNÓSTICO - Maildir user1 (últimos 5 min) =========="
  docker-compose exec -T "$CONTAINER" find /var/mail/vhosts/empresa.local/user1/Maildir -mmin -5 -type f 2>/dev/null || echo "(erro ou nenhum arquivo)"
  echo ""

  echo "========== 16. DIAGNÓSTICO - mail.log (amavis/clam/defer/content_filter) =========="
  docker-compose exec -T "$CONTAINER" tail -200 /var/log/mail.log 2>/dev/null | grep -iE 'amavis|clam|defer|content_filter|10024|virus' || echo "(nenhuma linha ou inacessível)"
  echo ""

  echo "=============================================="
  echo "FIM DO FLUXO: build → up → testes → diagnóstico"
  echo "Abra o arquivo: $OUTPATH"
  echo "=============================================="
} 2>&1 | tee "$OUTPATH"

echo ""
echo "Resultado completo salvo em: $OUTPATH"
echo "Para ver: cat \"$OUTPATH\"   ou   less \"$OUTPATH\"   ou abra o arquivo no editor."
