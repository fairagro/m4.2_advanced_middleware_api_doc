#!/usr/bin/env bash
set -euo pipefail

echo "==> Dev container ready for Archify documentation work"
echo "    Node: $(node -v)"
echo "    npm:  $(npm -v)"
echo "    Middleware API mount: ${MIDDLEWARE_API_ROOT:-unset}"
echo "    Middleware Harvester mount: ${MIDDLEWARE_HARVESTER_ROOT:-unset}"
echo "    SQL-to-ARC mount: ${SQL_TO_ARC_ROOT:-unset}"

if [[ -d "${MIDDLEWARE_API_ROOT:-}" ]]; then
  echo "    Middleware API found: $(ls -d "${MIDDLEWARE_API_ROOT}")"
else
  echo "    WARNING: Middleware API repo not mounted at ${MIDDLEWARE_API_ROOT:-}"
  echo "    Expected sibling folder: ../m4.2_advanced_middleware_api"
fi

if [[ -d "${MIDDLEWARE_HARVESTER_ROOT:-}" ]]; then
  echo "    Middleware Harvester found: $(ls -d "${MIDDLEWARE_HARVESTER_ROOT}")"
else
  echo "    WARNING: Middleware Harvester repo not mounted at ${MIDDLEWARE_HARVESTER_ROOT:-}"
  echo "    Expected sibling folder: ../m4.2_middleware_harvester"
fi

if [[ -d "${SQL_TO_ARC_ROOT:-}" ]]; then
  echo "    SQL-to-ARC found: $(ls -d "${SQL_TO_ARC_ROOT}")"
else
  echo "    WARNING: SQL-to-ARC repo not mounted at ${SQL_TO_ARC_ROOT:-}"
  echo "    Expected sibling folder: ../m4.2_sql_to_arc"
fi

# Chromium dependencies for Archify finalize browser-check
if command -v sudo >/dev/null 2>&1; then
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    chromium \
    fonts-liberation \
    ca-certificates \
    >/dev/null
  echo "    Chromium: $(chromium --version 2>/dev/null || echo installed)"
fi

echo "==> Next: install Archify skill (project-scoped) when confirmed in chat"
echo "    npx -y skills@latest add https://archify.si --skill archify --agent cursor --copy --yes"
