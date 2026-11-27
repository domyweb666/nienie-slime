cd "C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F2work/tools"
export F2P=6
B="C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F2work"
for fn in P4S FZS TWO; do s0=1; [ $fn = FZS ] && s0=1000
F2WEB="$B/prototype/web" python runpair.py $fn 30 $s0 k_base_$fn '{"shine":0,"opaque":0.9}' 0 - 4 modes_none.js
F2WEB="$B/fix7/prototype/web" python runpair.py $fn 30 $s0 k_fix7_$fn '{"shine":0,"opaque":0.9}' 0 - 4 modes_none.js
done
echo ALLDONE
