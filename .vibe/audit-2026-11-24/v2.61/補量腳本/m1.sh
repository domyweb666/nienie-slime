# QC 完 → T70 長版
cd "$(dirname "$0")"; until grep -q '^QC' out/qC.log 2>/dev/null; do sleep 10; done; bash qD.sh
