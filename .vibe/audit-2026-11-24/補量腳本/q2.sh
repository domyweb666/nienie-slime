D=C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/c03762d8-d9d7-48d6-842c-b409d5d2cab2/scratchpad/combo; cd $D
for i in 1 2 3; do
python selft.py $D/pat/prototype/web 8994 $D/st_b$i.json 'F1X={cg:1,bl:1.35,gv:1};JELX.mode=9' >> st.log 2>&1
python selft.py $D/head/prototype/web 8995 $D/st_a$i.json >> st.log 2>&1
done
echo ST >> st.log
