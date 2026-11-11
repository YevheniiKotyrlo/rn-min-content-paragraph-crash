#!/usr/bin/env bash
# Builds ReproducerApp in Release, installs it on the iPhone or iPad whose devicectl identifier is the first argument,
# launches it three times for 15 seconds each and reads the crash reports the device writes.
# Signing: DEVELOPMENT_TEAM, and BUNDLE_ID (org.reactjs.native.example.ReproducerApp by default), from the environment.
# Exit 1 while a launch crashes under Yoga's computeMinContentMainSize, 0 once the three launches run without a crash,
# 2 when a step fails or a launch crashes elsewhere.
set -uo pipefail

device="${1:?usage: DEVELOPMENT_TEAM=<team> ./reproduce.sh <devicectl device identifier>}"
team="${DEVELOPMENT_TEAM:?set DEVELOPMENT_TEAM to the team that signs the app}"
bundle_id="${BUNDLE_ID:-org.reactjs.native.example.ReproducerApp}"
here="$(cd "$(dirname "$0")" && pwd)"
app="${here}/ReproducerApp"
logs="${here}/logs"
mkdir -p "${logs}"

if ! macos="$(sw_vers -productVersion)" || ! xcode="$(xcodebuild -version | tr '\n' ' ')" ||
    ! node_version="$(node --version)" || ! pod_version="$(pod --version)" ||
    ! device_line="$(xcrun devicectl list devices 2>/dev/null | grep -F "${device}")"; then
    echo "SUMMARY: a tool the run needs is missing, or devicectl does not list ${device}"
    exit 2
fi
echo "macOS ${macos}; ${xcode}; node ${node_version}; pod ${pod_version}"
echo "device: ${device_line}"

echo "\$ yarn install --frozen-lockfile"
if ! (cd "${app}" && npx --yes yarn@1 install --frozen-lockfile --non-interactive > "${logs}/yarn-install.log" 2>&1); then
    tail -n 20 "${logs}/yarn-install.log"
    echo "SUMMARY: yarn install failed"
    exit 2
fi
react_native_version="$(cd "${app}" && node -p 'require("react-native/package.json").version')" || exit 2
echo "react-native ${react_native_version}"

echo "\$ pod install"
if ! (cd "${app}/ios" && pod install > "${logs}/pod-install.log" 2>&1); then
    tail -n 20 "${logs}/pod-install.log"
    echo "SUMMARY: pod install failed"
    exit 2
fi

# Xcode adds the device to the profile it makes only when the destination names the device.
echo "\$ xcodebuild -workspace ReproducerApp.xcworkspace -scheme ReproducerApp -configuration Release -destination id=${device} build"
if ! (cd "${app}/ios" && xcodebuild -workspace ReproducerApp.xcworkspace -scheme ReproducerApp -configuration Release \
    -destination "id=${device}" -derivedDataPath "${here}/derived-data" DEVELOPMENT_TEAM="${team}" \
    CODE_SIGN_STYLE=Automatic PRODUCT_BUNDLE_IDENTIFIER="${bundle_id}" -allowProvisioningUpdates -allowProvisioningDeviceRegistration build \
    > "${logs}/build.log" 2>&1); then
    grep -E 'error:|\*\* BUILD' "${logs}/build.log" | head -n 20
    echo "SUMMARY: the Release build failed"
    exit 2
fi
echo "** BUILD SUCCEEDED **"

product="${here}/derived-data/Build/Products/Release-iphoneos/ReproducerApp.app"
if ! xcrun devicectl device install app --device "${device}" "${product}" > "${logs}/install.log" 2>&1; then
    cat "${logs}/install.log"
    echo "SUMMARY: installing the app failed"
    exit 2
fi

crash_reports() {
    xcrun devicectl device info files --device "${device}" --domain-type systemCrashLogs 2>/dev/null |
        awk '{ print $1 }' | grep '^ReproducerApp-.*\.ips$' | LC_ALL=C sort
}

min_content_crashes=0
other_crashes=0
for launch in 1 2 3; do
    known="$(crash_reports)"
    xcrun devicectl device process launch --device "${device}" --terminate-existing --console "${bundle_id}" \
        > "${logs}/console-${launch}.log" 2>&1 &
    launcher=$!
    sleep 15
    kill "${launcher}" 2> /dev/null
    wait "${launcher}" 2> /dev/null
    grep -m 3 -E 'flags:|relayouts done' "${logs}/console-${launch}.log" | sed -E 's/^.*\[javascript\] //'
    now="$(crash_reports)"
    fresh="$(LC_ALL=C comm -13 <(printf '%s\n' "${known}") <(printf '%s\n' "${now}") | tail -n 1)"
    if [[ -z "${fresh}" ]]; then
        echo "launch ${launch}: ran 15 seconds without a crash"
        continue
    fi
    report="${logs}/launch-${launch}.ips"
    xcrun devicectl device copy from --device "${device}" --domain-type systemCrashLogs --source "${fresh}" \
        --destination "${report}" > /dev/null 2>&1
    exception="$(grep -o '"exception" *: *{[^}]*}' "${report}" | grep -oE '"(type|signal|subtype|message)":"[^"]*"' | tr '\n' ' ')"
    echo "launch ${launch}: crashed, ${fresh}: ${exception}"
    if grep -q 'computeMinContentMainSize' "${report}"; then
        min_content_crashes=$((min_content_crashes + 1))
        grep -oE '"symbol":"[^"]*(computeMinContentMainSize|ParagraphShadowNode::[A-Za-z]+|__dynamic_cast)[^"]*"' "${report}" |
            awk '!seen[$0]++' | head -n 4
    else
        other_crashes=$((other_crashes + 1))
    fi
done

if [[ "${min_content_crashes}" -gt 0 ]]; then
    echo "SUMMARY: ${min_content_crashes} of 3 launches crashed under computeMinContentMainSize with enableFlexboxAutoMinSizeInStrictMode on (react-native ${react_native_version})"
    exit 1
fi
if [[ "${other_crashes}" -gt 0 ]]; then
    echo "SUMMARY: ${other_crashes} of 3 launches crashed, none under computeMinContentMainSize"
    exit 2
fi
echo "SUMMARY: 3 launches ran without a crash (react-native ${react_native_version})"
exit 0
