#!/usr/bin/env bash
# Update Package.swift binaryTarget URL + checksum for GitHub Release publishing.
#
# Usage:
#   ./scripts/spm_update_package.sh --version 1.2.3 --checksum <checksum>
#   ./scripts/spm_update_package.sh --version 1.2.3 --checksum <checksum> --repo pis123/SunellSDK

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

PACKAGE_PATH="${PACKAGE_PATH:-${ROOT_DIR}/Package.swift}"
REPO_SLUG="${REPO_SLUG:-pis123/SunellSDK}"
ASSET_NAME="${ASSET_NAME:-SunellSDK.xcframework.zip}"
VERSION=""
CHECKSUM=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="${2:-}"
      shift 2
      ;;
    --checksum)
      CHECKSUM="${2:-}"
      shift 2
      ;;
    --repo)
      REPO_SLUG="${2:-}"
      shift 2
      ;;
    --asset-name)
      ASSET_NAME="${2:-}"
      shift 2
      ;;
    --package-path)
      PACKAGE_PATH="${2:-}"
      shift 2
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${VERSION}" ]]; then
  echo "error: --version is required." >&2
  exit 1
fi
if [[ -z "${CHECKSUM}" ]]; then
  echo "error: --checksum is required." >&2
  exit 1
fi
if [[ ! -f "${PACKAGE_PATH}" ]]; then
  echo "error: Package.swift not found at ${PACKAGE_PATH}" >&2
  exit 1
fi

URL="https://github.com/${REPO_SLUG}/releases/download/${VERSION}/${ASSET_NAME}"

python3 - <<'PY' "${PACKAGE_PATH}" "${URL}" "${CHECKSUM}"
import re
import sys
from pathlib import Path

package_path = Path(sys.argv[1])
url = sys.argv[2]
checksum = sys.argv[3]

text = package_path.read_text(encoding="utf-8")
updated = text

updated, url_count = re.subn(
    r'url:\s*"[^"]+"',
    f'url: "{url}"',
    updated,
    count=1,
)
updated, checksum_count = re.subn(
    r'checksum:\s*"[^"]+"',
    f'checksum: "{checksum}"',
    updated,
    count=1,
)

if url_count != 1 or checksum_count != 1:
    raise SystemExit("error: failed to locate binaryTarget url/checksum in Package.swift")

if updated != text:
    package_path.write_text(updated, encoding="utf-8")
PY

echo "Updated ${PACKAGE_PATH}"
echo "URL=${URL}"
echo "CHECKSUM=${CHECKSUM}"
