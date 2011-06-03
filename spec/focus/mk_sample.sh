rm -rf omnisync-sample.tar
rm -rf tester
mkdir -p tester/OmniFocus.ofocus
cp sample.xml tester/OmniFocus.ofocus/contents.xml
cd tester/OmniFocus.ofocus
zip 00000000000000\=jg_Qiayp72m+l8TMaNw79vf.zip contents.xml
cd ../..
tar cvf omnisync-sample.tar tester/OmniFocus.ofocus/00000000000000\=jg_Qiayp72m+l8TMaNw79vf.zip
rm -rf tester
echo "Done making sample tar file"