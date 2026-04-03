#!/usr/bin/env bash
# 将 SunellSDK.framework 工程编译并打包为 SunellSDK.xcframework，供 SwiftPM（仓库根目录 Package.swift）分发。
#
# 产出：默认 Release → Distribution/SunellSDK/SunellSDK.xcframework
#   - 真机：generic/platform=iOS（通常为 ios-arm64）
#   - 模拟器（默认）：仅 **x86_64**（Intel 模拟器 slice：ios-x86_64-simulator）
#     与当前 SunellBaseSDK.a / SunellP2PSDK.a 仅支持「真机 + Intel 模拟器」一致；**v1 不包含 arm64-simulator**（Apple 芯片本机模拟器）。
#     将来若预编译库支持 M 芯片模拟器：SIMULATOR_ARCHS=arm64 或同时打 arm64+x86_64 再合并（需厂商库支持）。
#
# 若已在 Xcode 中分别编出 Release-iphoneos / Release-iphonesimulator 的 .framework，可改用：
#   ./scripts/merge_release_frameworks_to_xcframework.sh
#
# 用法：在仓库根目录执行 ./scripts/build_sunell_xcframework.sh
# 可选环境变量：SCHEME CONFIGURATION PROJECT OUTPUT_DIR BUILD_DIR SIMULATOR_ARCHS

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

SCHEME="${SCHEME:-SunellSDK}"
CONFIGURATION="${CONFIGURATION:-Release}"
PROJECT="${PROJECT:-${ROOT_DIR}/SunellSDK.xcodeproj}"
BUILD_DIR="${BUILD_DIR:-${ROOT_DIR}/build/xcframework}"
OUTPUT_DIR="${OUTPUT_DIR:-${ROOT_DIR}/Distribution/SunellSDK}"
FRAMEWORK_NAME="SunellSDK"
# 模拟器仅打 x86_64，避免链接 arm64-simulator 时与「真机 arm64」预编译 .a 冲突（v1 不支持 Apple Silicon 模拟器）
SIMULATOR_ARCHS="${SIMULATOR_ARCHS:-x86_64}"

IOS_ARCHIVE="${BUILD_DIR}/${FRAMEWORK_NAME}-ios.xcarchive"
SIM_ARCHIVE="${BUILD_DIR}/${FRAMEWORK_NAME}-sim.xcarchive"
XCFRAMEWORK_OUT="${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}" "${OUTPUT_DIR}"

echo "==> [${CONFIGURATION}] Archiving ${SCHEME} for iOS device…"
xcodebuild archive \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination "generic/platform=iOS" \
  -archivePath "${IOS_ARCHIVE}" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  ONLY_ACTIVE_ARCH=NO

IOS_FW="${IOS_ARCHIVE}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
if [[ ! -d "${IOS_FW}" ]]; then
  echo "error: iOS device framework not found: ${IOS_FW}" >&2
  exit 1
fi

HAVE_SIM=0
echo "==> [${CONFIGURATION}] Archiving ${SCHEME} for iOS Simulator（ARCHS=${SIMULATOR_ARCHS}，v1：Intel 模拟器）…"
if xcodebuild archive \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "${SIM_ARCHIVE}" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  ONLY_ACTIVE_ARCH=YES \
  ARCHS="${SIMULATOR_ARCHS}" \
  VALID_ARCHS="${SIMULATOR_ARCHS}"
then
  SIM_FW="${SIM_ARCHIVE}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
  if [[ -d "${SIM_FW}" ]]; then
    HAVE_SIM=1
  fi
else
  echo "" >&2
  echo "warning: 模拟器归档失败（当前已限制为 x86_64 以匹配预编译静态库）。" >&2
  echo "warning: 将只生成 **真机** xcframework。排查: ./scripts/inspect_precompiled_a_platform.sh" >&2
  echo "" >&2
fi

rm -rf "${XCFRAMEWORK_OUT}"

if [[ "${HAVE_SIM}" -eq 1 ]]; then
  SIM_FW="${SIM_ARCHIVE}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
  echo "==> Creating xcframework（真机 + Intel 模拟器 x86_64；v1 不含 arm64-simulator）…"
  xcodebuild -create-xcframework \
    -framework "${IOS_FW}" \
    -framework "${SIM_FW}" \
    -output "${XCFRAMEWORK_OUT}"
else
  echo "==> Creating xcframework（仅真机）…"
  xcodebuild -create-xcframework \
    -framework "${IOS_FW}" \
    -output "${XCFRAMEWORK_OUT}"
fi

echo "==> Slices:"
/usr/bin/find "${XCFRAMEWORK_OUT}" -maxdepth 2 -type d \( -name "ios-*" -o -name "ios-*-simulator" \) 2>/dev/null | sort || ls -la "${XCFRAMEWORK_OUT}"

echo "==> Done: ${XCFRAMEWORK_OUT}"
echo "    SPM：仓库根目录 Package.swift（binaryTarget 指向上述路径）；提交时请一并纳入 xcframework 或改用 url+checksum。"
