. "$(dirname "$0")/lib.sh"; PORT=8995
run c_rnd.json rd_def '{}' "$N" 3
run c_rnd.json rd_A3 "$A3" "$N" 3
run c_rnd.json rd_A4 "$A4" "$N" 3
run c_rnd.json rd_A5 "$A5" "$N" 3
run c_rnd.json rd_all "$ALL" "$N" 3
run c_rnd.json rd_v260 '{}' "$O" 3
run c_rnd.json rd_def_2 '{}' "$N" 3
for s in 1 5 7; do run c_rnd100.json rd${s}_def '{}' "$N" 3 --slime $s; run c_rnd100.json rd${s}_all "$ALL" "$N" 3 --slime $s; done
echo QB >> out/q.log
