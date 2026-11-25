# QB 完 → 第 7 項（3 個 Chrome）→ T70 完 → 混合
cd "$(dirname "$0")"; until grep -q '^QB' out/q.log 2>/dev/null; do sleep 10; done; PR=3 bash q7.sh; until grep -q 'T70LONG' out/q.log; do sleep 10; done; bash qA.sh
