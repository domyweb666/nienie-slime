cd "C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F2work/tools"
export F2P=4
python runpair.py FZS 30 1000 pair_fz '{"shine":0,"opaque":0.9}' 0,1,2 - 3
python runpair.py P4S 30 1 pair_p4 '{"shine":0,"opaque":0.9}' 0,1,2 - 3
python runpair.py TWO 30 1 pair_two '{"shine":0,"opaque":0.9}' 0,1,2 - 3
python runpair.py CALM 30 1 pair_calm '{"shine":0,"opaque":0.9}' 0,1,2 - 3
echo ALLDONE
