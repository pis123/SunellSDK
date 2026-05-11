#!/usr/bin/env bash
# One-command SwiftPM binary release:
# 1) Build + zip artifact
# 2) Compute checksum
# 3) Update Package.swift
# 4) Commit + tag + push
# 5) Create GitHub Release and upload zip asset
#
# Usage:
#   ./scripts/spm_publish_release.sh --version 1.2.3
#   ./scripts/spm_publish_release.sh --version 1.2.3 --repo pis123/SunellSDK --notes-file RELEASE_NOTES.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

VERSION=""
REPO_SLUG="${REPO_SLUG:-pis123/SunellSDK}"
ASSET_NAME="${ASSET_NAME:-SunellSDK.xcframework.zip}"
PACKAGE_PATH="${PACKAGE_PATH:-${ROOT_DIR}/Package.swift}"
NOTES_FILE=""
REMOTE_NAME="${REMOTE_NAME:-origin}"
BRANCH_NAME="${BRANCH_NAME:-$(git rev-parse --abbrev-ref HEAD)}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="${2:-}"
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
    --notes-file)
      NOTES_FILE="${2:-}"
      shift 2
      ;;
    --remote)
      REMOTE_NAME="${2:-}"
      shift 2
      ;;
    --branch)
      BRANCH_NAME="${2:-}"
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
if [[ "${VERSION}" =~ [[:space:]] ]]; then
  echo "error: version cannot contain whitespace." >&2
  exit 1
fi
if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh CLI not found. Install GitHub CLI first." >&2
  echo "       https://cli.github.com/" >&2
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "error: working tree is not clean. Commit/stash changes first." >&2
  exit 1
fi

if git rev-parse -q --verify "refs/tags/${VERSION}" >/dev/null; then
  echo "error: local tag '${VERSION}' already exists." >&2
  exit 1
fi

if git ls-remote --exit-code --tags "${REMOTE_NAME}" "refs/tags/${VERSION}" >/dev/null 2>&1; then
  echo "error: remote tag '${VERSION}' already exists on ${REMOTE_NAME}." >&2
  exit 1
fi

echo "==> Build artifact + checksum"
BUILD_OUTPUT="$(VERSION="${VERSION}" "${SCRIPT_DIR}/spm_build_artifact.sh")"
echo "${BUILD_OUTPUT}"

CHECKSUM="$(printf "%s\n" "${BUILD_OUTPUT}" | awk -F= '/^CHECKSUM=/{print $2}' | tail -n1)"
ARTIFACT_PATH="$(printf "%s\n" "${BUILD_OUTPUT}" | awk -F= '/^ARTIFACT_PATH=/{print $2}' | tail -n1)"

if [[ -z "${CHECKSUM}" || -z "${ARTIFACT_PATH}" ]]; then
  echo "error: failed to parse build output for checksum/artifact path." >&2
  exit 1
fi
if [[ ! -f "${ARTIFACT_PATH}" ]]; then
  echo "error: artifact file not found: ${ARTIFACT_PATH}" >&2
  exit 1
fi

# Keep release asset name stable for SwiftPM URL.
DIST_DIR="$(cd "$(dirname "${ARTIFACT_PATH}")" && pwd)"
FINAL_ASSET_PATH="${DIST_DIR}/${ASSET_NAME}"
if [[ "${ARTIFACT_PATH}" != "${FINAL_ASSET_PATH}" ]]; then
  cp -f "${ARTIFACT_PATH}" "${FINAL_ASSET_PATH}"
fi

echo "==> Update Package.swift"
"${SCRIPT_DIR}/spm_update_package.sh" \
  --version "${VERSION}" \
  --checksum "${CHECKSUM}" \
  --repo "${REPO_SLUG}" \
  --asset-name "${ASSET_NAME}" \
  --package-path "${PACKAGE_PATH}"

echo "==> Commit release metadata"
git add "${PACKAGE_PATH}"
git commit -m "release: publish ${VERSION} SwiftPM artifact"

echo "==> Create git tag"
git tag "${VERSION}"

echo "==> Push branch + tag"
git push "${REMOTE_NAME}" "${BRANCH_NAME}"
git push "${REMOTE_NAME}" "${VERSION}"

echo "==> Create GitHub release and upload asset"
if [[ -n "${NOTES_FILE}" ]]; then
  gh release create "${VERSION}" "${FINAL_ASSET_PATH}" \
    --repo "${REPO_SLUG}" \
    --title "${VERSION}" \
    --notes-file "${NOTES_FILE}"
else
  gh release create "${VERSION}" "${FINAL_ASSET_PATH}" \
    --repo "${REPO_SLUG}" \
    --title "${VERSION}" \
    --generate-notes
fi

echo "==> Release done"
echo "Version: ${VERSION}"
echo "Checksum: ${CHECKSUM}"
echo "Asset: ${FINAL_ASSET_PATH}"
