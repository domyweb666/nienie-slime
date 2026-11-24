D=C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/c03762d8-d9d7-48d6-842c-b409d5d2cab2/scratchpad/combo; cd $D
B='cg:1,bl:1.35,gv:1'
C='cr:1,iw:1,cg:1,bl:1.35,up:3,gv:1,fl:1.35,vc:6'
run(){ python tool/run.py $1 "$D/r_$2" --procs 5 --port 8993 --src "$D/pat/prototype/web" --pre "$3" --nosnap > "$D/r_$2.log" 2>&1; echo $(date +%T) $2 $(tail -1 $D/r_$2.log) >> $D/q.log; }
for k in gone mix rnd; do
 run c_$k.json ${k}_a 'F1X={};JELX.mode=0'
 run c_$k.json ${k}_b "F1X={$B};JELX.mode=9"
 run c_$k.json ${k}_c "F1X={$C};JELX.mode=9"
 run c_$k.json ${k}_d "F1X={$C,hs:1};JELX.mode=9"
 run c_$k.json ${k}_e "F1X={$B,kp:1};JELX.mode=9"
done
echo Q1 >> q.log
# 加跑：a、b 重跑一次量雜訊；手機彈簧現狀 f；只換皮 g
run c_gone.json gone_b2 "F1X={$B};JELX.mode=9"
run c_gone.json gone_a2 'F1X={};JELX.mode=0'
run c_gone.json gone_f 'F1X={kp:1};JELX.mode=0'
run c_gone.json gone_g 'F1X={};JELX.mode=9'
run c_mix.json mix_g 'F1X={};JELX.mode=9'
run c_mix.json mix_f 'F1X={kp:1};JELX.mode=0'
run c_rnd.json rnd_g 'F1X={};JELX.mode=9'
run c_rnd.json rnd_f 'F1X={kp:1};JELX.mode=0'
run c_mix.json mix_b2 "F1X={$B};JELX.mode=9"
run c_mix.json mix_a2 'F1X={};JELX.mode=0'
echo Q2 >> q.log
