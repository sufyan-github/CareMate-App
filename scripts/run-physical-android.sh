#!/usr/bin/env bash
set -euo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_SDK_PATH="${ANDROID_SDK_ROOT:-/home/md-abu-sufyan/Android/Sdk}"
ADB_BINARY="${ANDROID_SDK_PATH}/platform-tools/adb"
API_HEALTH_URL="http://127.0.0.1:3000/api/v1/health"

if ! curl --fail --silent --max-time 3 "${API_HEALTH_URL}" >/dev/null; then
  echo "CareMate API is not running on port 3000."
  echo "Start it in another terminal:"
  echo "  cd \"${REPOSITORY_ROOT}\" && pnpm --filter @caremate/api dev"
  exit 1
fi

if [[ ! -x "${ADB_BINARY}" ]]; then
  echo "Android adb was not found at ${ADB_BINARY}."
  exit 1
fi

DEVICE_ID="$(${ADB_BINARY} devices | awk 'NR > 1 && $2 == "device" { print $1; exit }')"
if [[ -z "${DEVICE_ID}" ]]; then
  echo "No authorized Android device is connected."
  exit 1
fi

"${ADB_BINARY}" -s "${DEVICE_ID}" reverse tcp:3000 tcp:3000

cd "${REPOSITORY_ROOT}/apps/mobile"
exec flutter --no-version-check run \
  -d "${DEVICE_ID}" \
  --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1
