#!/usr/bin/env bash
set -euo pipefail

# Project root (script-aware)
cd "$(dirname "$0")/.."

# Basic app settings
export PORT=${PORT:-3001}
export RAILS_ENV=${RAILS_ENV:-development}

# JWT config
export JWT_ISSUER=${JWT_ISSUER:-ffcrm-user-svc}
export JWT_AUDIENCE=${JWT_AUDIENCE:-admin-api}
export JWT_KID=${JWT_KID:-dev-$(date +%s)}
export JWT_EXP=${JWT_EXP:-900}

# Load PEMs from files (avoid multiline .env issues)
export JWT_PRIVATE_KEY_PEM="$(cat jwt_private.pem)"
export JWT_PUBLIC_KEY_PEM="$(cat jwt_public.pem)"

echo "Starting on port $PORT (env=$RAILS_ENV)"
echo "JWT kid=$JWT_KID issuer=$JWT_ISSUER audience=${JWT_AUDIENCE:-<none>} private=${#JWT_PRIVATE_KEY_PEM} chars public=${#JWT_PUBLIC_KEY_PEM} chars"

# Boot the app
exec bundle exec puma -C config/puma.rb