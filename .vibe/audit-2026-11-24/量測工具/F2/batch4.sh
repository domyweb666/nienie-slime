cd "C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F2work/tools"
export F2P=5
export F2WEB="C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F2work/fix2/prototype/web"
python runpair.py TWO 30 1 f4_two '{"shine":0,"opaque":0.9}' 0,1,3,8 - 3 modes_fix2.js
python runpair.py P4S 30 1 f4_p4 '{"shine":0,"opaque":0.9}' 0,1,3,8 - 4 modes_fix2.js
python runpair.py FZS 30 1000 f4_fz '{"shine":0,"opaque":0.9}' 0,1,3,8 - 4 modes_fix2.js
python runpair.py CALM 20 1 f4_calm '{"shine":0,"opaque":0.9}' 0,3,8 - 5 modes_fix2.js
echo ALLDONE
