#!/bin/bash
# 沒有 Mac 時，在 Linux 上先驗 Swift。用法：tools/swift-linux-check/check.sh   （在 repo 根目錄跑；swiftc 要在 PATH 上，Swift 6.x 的 Linux 工具鏈）
# 做三件事：1 建替身模組（假的 UIKit、SwiftUI、Metal…，只有型別，什麼都不會動）；2 型別檢查控制器、調節台、SwiftUI 畫面；3 型別檢查 SlimeView、JellySkin。
# 替身不等於真的 SDK：這裡過了，CI 還是可能有錯；這裡不過，CI 一定不過。改替身之前先拿上一版原檔跑一次，確認是替身的問題。
set -u
H="$(cd "$(dirname "$0")" && pwd)"; R="$(cd "$H/../.." && pwd)"; S="$H/stubs"; M="${TMPDIR:-/tmp}/nienie-swift-check"; mkdir -p "$M/mod"
N="$R/ios/NieNie"
mod() { swiftc -emit-module -parse-as-library -swift-version 5 -module-name "$1" -I "$M/mod" -o "$M/mod/$1.swiftmodule" "${@:2}" 2>&1 | grep -E "error" ; }
mod UIKit "$S/UIKit.swift" "$S/UIKitDraw.swift"; mod Metal "$S/MetalStub.swift"; mod QuartzCore "$S/QuartzCore.swift"; mod SwiftUI "$S/SwiftUI.swift"; mod AVFoundation "$S/AVFoundation.swift"; mod CoreMotion "$S/CoreMotion.swift"; mod CoreGraphics "$S/CoreGraphics.swift"; mod CoreHaptics "$S/CoreHaptics.swift"
# SlimeView 的 FrameStats 和量測開關：從真的檔案抄宣告
python3 - "$N/Slime/SlimeView.swift" > "$M/ViewStub.swift" <<'PY'
import re, sys
src = open(sys.argv[1], encoding='utf-8').read()
m = re.search(r'    struct FrameStats \{.*?\n    \}\n', src, re.S)
print('import SwiftUI\nfinal class SlimeView {\n' + m.group(0))
for name in ['labGrey', 'labCircle', 'latencyTest']:
    if re.search(r'\n    var ' + name + r'\b', src): print('    var ' + name + ' = false')
if re.search(r'\n    var labLayersOff\b', src): print('    var labLayersOff: Set<String> = []')
print('}')
PY
echo "== 控制器、調節台、SwiftUI 畫面"
swiftc -typecheck -swift-version 5 -I "$M/mod" "$S/AppStubs.swift" "$S/WindowStub.swift" "$M/ViewStub.swift" "$N/App/SlimeController.swift" "$N/UI/FeelDesk.swift" "$N/UI/FeelDeskModel.swift" "$N/UI/TunePanel.swift" "$N/UI/ContentView.swift" "$N/UI/LabProbe.swift" "$N/Slime/JellySkin.swift" \
  "$N/Slime/FeelParams.swift" "$N/Slime/SlimeRig.swift" "$N/Slime/SlimeBrain.swift" "$N/Slime/SlimeFuzz.swift" 2>&1 | grep -E "error:" | sed -E 's/^.*NieNie\///' | cut -c1-220
echo "== SlimeView、JellySkin"
sed -e 's/@objc private func tick/private func tick/' -e 's/#selector(tick(_:))/Selector("tick")/' -e 's/NSLog("\[windows\] reason: %@", why as NSString)/_ = why/' "$N/Slime/SlimeView.swift" > "$M/SlimeView.swift"   # Linux 沒有 Objective-C，String 也不能 as NSString
swiftc -typecheck -swift-version 5 -I "$M/mod" "$M/SlimeView.swift" "$S/SceneStub.swift" "$S/WindowStub.swift" "$N/UI/LabProbe.swift" "$N/Slime/JellySkin.swift" "$N/Slime/SlimeRig.swift" "$N/Slime/SlimeBrain.swift" "$N/Slime/FeelParams.swift" 2>&1 | grep -E "error:" | cut -c1-220
echo "== 做完（上面沒有 error 就是過）"
