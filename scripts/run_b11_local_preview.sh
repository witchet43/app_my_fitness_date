#!/usr/bin/env bash
# Local Flutter B11 QA only. Never modifies hosted Supabase.
set -euo pipefail
cd "$(dirname "$0")/.."
command -v flutter >/dev/null || { echo "Flutter SDK required"; exit 1; }
command -v docker >/dev/null || { echo "Docker required"; exit 1; }
command -v node >/dev/null || { echo "Node.js required"; exit 1; }
if [ "${SUPABASE_ACCESS_TOKEN:-}" != "" ]; then
  echo "Refusing local QA with a hosted Supabase access token."
  exit 1
fi
# Supabase CLI otherwise binds its Docker ports to 0.0.0.0. Pin them
# to loopback so the local anonymous/auth services are not on the LAN.
QA_NET="mfd-b11-loopback-$"
docker network create -o 'com.docker.network.bridge.host_binding_ipv4=127.0.0.1' "$QA_NET" >/dev/null
cleanup() {
  if [ -n "${EDGE_PID:-}" ]; then kill "$EDGE_PID" 2>/dev/null || true; fi
  npx --yes supabase@latest stop --no-backup || true
  docker network rm "$QA_NET" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM
npx --yes supabase@latest start --network-id "$QA_NET" --exclude studio,realtime,storage,functions,analytics,pooler
set -a
eval "$(npx --yes supabase@latest status -o env)"
set +a
if [ "${API_URL:-}" != "http://127.0.0.1:54321" ]; then
  echo "Not connected to local Supabase; refusing to start."
  exit 1
fi
PUBLIC_KEY="${PUBLISHABLE_KEY:-}"
if [[ "$PUBLIC_KEY" != sb_publishable_* ]]; then
  echo "A local publishable key is required. Never use a secret key."
  exit 1
fi
unset SERVICE_ROLE_KEY SECRET_KEY SUPABASE_SERVICE_ROLE_KEY DATABASE_URL DB_URL
npx --yes supabase@latest functions serve member-api-v26 --no-verify-jwt --env-file supabase/local-preview.env > /tmp/mfd-b11-local-edge.log 2>&1 &
EDGE_PID=$!
for attempt in $(seq 1 70); do
  code="$(curl -sS --max-time 3 -o /dev/null -w '%{http_code}' -X OPTIONS -H 'Origin: http://127.0.0.1:5173' http://127.0.0.1:54321/functions/v1/member-api-v26/v1/dating/rhythm || true)"
  if [ "$code" = "204" ]; then break; fi
  sleep 2
done
if [ "$code" != "204" ]; then
  echo "Local Edge did not start. See /tmp/mfd-b11-local-edge.log"
  tail -n 45 /tmp/mfd-b11-local-edge.log || true
  exit 1
fi
cd apps/flutter_client
flutter create --platforms=web . --project-name=my_fitness_date
flutter pub get
echo "Flutter B11 LOCAL QA: http://127.0.0.1:5173/"
echo "Local email inbox: http://127.0.0.1:54324/"
echo "This is NOT a production release and uses NO Google Cloud Build."
flutter run -d "${MFD_BROWSER_TARGET:-chrome}" --web-hostname=127.0.0.1 --web-port=5173 --dart-define=MFD_V26_ENABLED=true --dart-define=MFD_LOCAL_QA=true --dart-define=MFD_GOOGLE_PROVIDER_VERIFIED=false --dart-define=MFD_LOCAL_SUPABASE_URL=http://127.0.0.1:54321 --dart-define=MFD_LOCAL_SUPABASE_PUBLISHABLE_KEY="$PUBLIC_KEY" --dart-define=MFD_API_BASE_URL=http://127.0.0.1:54321/functions/v1/member-api-v26 --dart-define=MFD_TERMS_URL=https://my-fitness-date.pages.dev/terms/ --dart-define=MFD_PRIVACY_URL=https://my-fitness-date.pages.dev/privacy/ --dart-define=MFD_TERMS_VERSION=v27-terms-1 --dart-define=MFD_PRIVACY_VERSION=v27-privacy-1 --dart-define=MFD_OAUTH_REDIRECT_URL=http://127.0.0.1:5173/
