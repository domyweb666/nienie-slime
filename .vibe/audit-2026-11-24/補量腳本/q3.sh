D=C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/c03762d8-d9d7-48d6-842c-b409d5d2cab2/scratchpad/combo; cd $D
run(){ python tool/run.py $1 "$D/r_$2" --procs 5 --port 8997 --src "$D/pat/prototype/web" --pre "$3" --nosnap > "$D/r_$2.log" 2>&1; echo $(date +%T) $2 $(tail -1 $D/r_$2.log) >> $D/q.log; }
until grep -q "^Q2" q.log; do sleep 3; done
run c_gone.json gone_g2 'F1X={};JELX.mode=9'
run c_gone.json gone_h 'F1X={cg:1,gv:1};JELX.mode=9'
run c_gone.json gone_i 'F1X={bl:1.35};JELX.mode=9'
run c_gone.json gone_h2 'F1X={cg:1,gv:1};JELX.mode=9'
run c_gone.json gone_i2 'F1X={bl:1.35};JELX.mode=9'
run c_mix.json mix_i 'F1X={bl:1.35};JELX.mode=9'
echo Q3 >> q.log
until grep -q "^ST" st.log; do sleep 3; done
python timing.py > timing.log 2>&1; python timing.py > timing2.log 2>&1
echo TM >> q.log
