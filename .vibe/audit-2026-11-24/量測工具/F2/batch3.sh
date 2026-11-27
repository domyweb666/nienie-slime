cd "C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F2work/tools"
export F2P=4
export F2WEB="C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F2work/fix2/prototype/web"
python runpair.py P4S 30 1 f2_p4 '{"shine":0,"opaque":0.9}' 0,1,3,7 - 4 modes_fix2.js
python runpair.py TWO 30 1 f2_two '{"shine":0,"opaque":0.9}' 0,1,3,7 - 3 modes_fix2.js
python runpair.py FZS 30 1000 f2_fz '{"shine":0,"opaque":0.9}' 0,1,3,7 - 4 modes_fix2.js
python runpair.py CALM 30 1 f2_calm '{"shine":0,"opaque":0.9}' 0,1,3,7 - 4 modes_fix2.js
echo ALLDONE
