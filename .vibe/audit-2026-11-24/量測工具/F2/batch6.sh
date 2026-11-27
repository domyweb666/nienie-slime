cd "C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F2work/tools"
until grep -q ALLDONE ../data/log_batch5.txt; do sleep 5; done
export F2P=6
export F2WEB="C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F2work/fix4/prototype/web"
for s in 1 5 9; do python runpair.py P4S 12 1 f6_p4_s$s '{"shine":0,"opaque":0.9}' 0,9 $s 5 modes_fix4.js; done
echo ALLDONE
