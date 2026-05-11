#!/usr/bin/env bash
# Build xcframework, zip it for SwiftPM binaryTarget(url:), and compute checksum.
#
# Usage:
#   ./scripts/spm_build_artifact.sh
#   VERSION=1.2.3 ./scripts/spm_build_artifact.sh
#
# Machine-readable output:
#   ARTIFACT_PATH=/abs/path/to/SunellSDK.xcframework.zip
#   CHECKSUM=<swiftpm-checksum>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

FRAMEWORK_NAME="${FRAMEWORK_NAME:-SunellSDK}"
DIST_DIR="${DIST_DIR:-${ROOT_DIR}/Distribution/SunellSDK}"
XCFRAMEWORK_PATH="${XCFRAMEWORK_PATH:-${DIST_DIR}/${FRAMEWORK_NAME}.xcframework}"

# Optional semantic version, used only in output artifact filename.
VERSION="${VERSION:-}"
if [[ -n "${VERSION}" ]]; then
  ARTIFACT_NAME="${FRAMEWORK_NAME}.xcframework-${VERSION}.zip"
else
  ARTIFACT_NAME="${FRAMEWORK_NAME}.xcframework.zip"
fi

ARTIFACT_PATH="${DIST_DIR}/${ARTIFACT_NAME}"
CHECKSUM_FILE="${DIST_DIR}/${FRAMEWORK_NAME}.checksum.txt"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild not found." >&2
  exit 1
fi
if ! command -v swift >/dev/null 2>&1; then
  echo "error: swift not found." >&2
  exit 1
fi

echo "==> Building xcframework..."
"${SCRIPT_DIR}/build_sunell_xcframework.sh"

if [[ ! -d "${XCFRAMEWORK_PATH}" ]]; then
  echo "error: xcframework not found: ${XCFRAMEWORK_PATH}" >&2
  exit 1
fi

mkdir -p "${DIST_DIR}"
rm -f "${ARTIFACT_PATH}"

echo "==> Zipping artifact: ${ARTIFACT_PATH}"
(
  cd "${DIST_DIR}"
  ditto -c -k --sequesterRsrc --keepParent \
    "${FRAMEWORK_NAME}.xcframework" \
    "${ARTIFACT_NAME}"
)

echo "==> Computing SwiftPM checksum..."
CHECKSUM="$(swift package compute-checksum "${ARTIFACT_PATH}")"
echo "${CHECKSUM}" > "${CHECKSUM_FILE}"

echo "==> Done."
echo "ARTIFACT_PATH=${ARTIFACT_PATH}"
echo "CHECKSUM=${CHECKSUM}"
