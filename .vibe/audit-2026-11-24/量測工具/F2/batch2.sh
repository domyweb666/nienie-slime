cd "C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F2work/tools"
export F2P=4
export F2WEB="C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F2work/fix/prototype/web"
python runpair.py P4S 24 1 fix_p4 '{"shine":0,"opaque":0.9}' 0,1,3,5,6 - 4 modes_fix.js
python runpair.py FZS 24 1000 fix_fz '{"shine":0,"opaque":0.9}' 0,1,3,5,6 - 4 modes_fix.js
python runpair.py TWO 24 1 fix_two '{"shine":0,"opaque":0.9}' 0,1,3,5,6 - 3 modes_fix.js
python runpair.py CALM 24 1 fix_calm '{"shine":0,"opaque":0.9}' 0,1,3,6 - 4 modes_fix.js
echo ALLDONE
