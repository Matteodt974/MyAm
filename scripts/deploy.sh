#!/usr/bin/env bash
# Regenerates backend/.env from the environment and restarts the stack.
set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/backend"

for required in JWT_SECRET ENCRYPTION_MASTER_KEY GEMINI_API_KEY; do
  if [ -z "${!required:-}" ]; then
    echo "error: $required is empty. Set it in the repository secrets." >&2
    exit 1
  fi
done

umask 077
cat > .env <<ENVFILE
ENVIRONMENT=${ENVIRONMENT:-production}
DATABASE_URL=${DATABASE_URL:-jdbc:postgresql://db:5432/scan}
DATABASE_USER=${DATABASE_USER:-scan}
DATABASE_PASSWORD=${DATABASE_PASSWORD:-scan}
JWT_SECRET=${JWT_SECRET}
ENCRYPTION_MASTER_KEY=${ENCRYPTION_MASTER_KEY}
GEMINI_API_KEY=${GEMINI_API_KEY}
GEMINI_MODEL=${GEMINI_MODEL:-gemini-3.5-flash}
FDC_API_KEY=${FDC_API_KEY:-DEMO_KEY}
OFF_USER_AGENT=${OFF_USER_AGENT:-MyAm/3.0.0 (contact: equipe@courrier.uqam.ca)}
ENVFILE

docker compose up --build -d
docker compose ps
