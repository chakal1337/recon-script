#!/bin/bash
if [[ $# < 1 ]]; then
 echo "$0 <domain>";
 exit;
fi
echo "Checking dependencies...";
if ! which assetfinder &>/dev/null;  then
 sudo apt install assetfinder;
fi
if ! which getallurls &>/dev/null;  then
 sudo apt install getallurls;
fi
if ! which nmap &>/dev/null;  then
 sudo apt install nmap;
fi
if ! which httprobe &>/dev/null;  then
 sudo apt install nmap;
fi
if ! which dirsearch &>/dev/null; then
 sudo apt install dirsearch;
fi
echo "Cleaning up previous scan files...";
rm assetsfound.txt &>/dev/null;
rm all_urls.txt &>/dev/null;
rm nmap-scan.txt &>/dev/null;
rm assetsworking.txt &>/dev/null;
rm dirsearched.txt &>/dev/null;
rm customwordlist.txt &>/dev/null;
echo "Starting..";
echo "Running assetfinder...";
assetfinder -subs-only $1 | tee -a assetsfound.txt;
echo "Cleaning up asset list...";
cat assetsfound.txt | sort -u | uniq > assetsfoundt.txt;
mv assetsfoundt.txt assetsfound.txt;
echo "Probing for working http servers...";
cat assetsfound.txt | httprobe | tee -a assetsworking.txt;
echo "Cleaning working assets list...";
cat assetsworking.txt | sort -u | uniq > assetsworkingt.txt;
mv assetsworkingt.txt assetsworking.txt;
echo "Creating custom wordlist...";
for i in $(cat assetsworking.txt); do curl $i --output - | sed -e "s/\s/\n/g" | tr "[:cntrl:][:punct:]" "\n" | tr -s "[:cntrl:]" "\n" >>customwordlist.txt; done;
echo "Cleaning custom wordlist...";
cat customwordlist.txt | sort -u | uniq > customwordlistt.txt;
mv customwordlistt.txt customwordlist.txt;
echo "Running getallurls...";
for i in $(cat assetsworking.txt); do getallurls $i | tee -a all_urls.txt; done;
echo "Running nmap...";
nmap -sT -Pn -T5 -vv -n -iL assetsfound.txt -oN nmap-scan.txt;
echo "Running dirsearch...";
cp assetsworking.txt /tmp/assetsworking.txt;
dirsearch -l /tmp/assetsworking.txt -o /tmp/dirsearched.txt;
rm /tmp/assetsworking.txt;
mv /tmp/dirsearched.txt dirsearched.txt;
echo "Running dirsearch with the custom wordlist...";
cp assetsworking.txt /tmp/assetsworking.txt;
cp customwordlist.txt /tmp/customwordlist.txt;
dirsearch -l /tmp/assetsworking.txt -o /tmp/dirsearched.txt -w /tmp/customwordlist.txt;
rm /tmp/assetsworking.txt;
rm /tmp/customwordlist.txt;
mv /tmp/dirsearched.txt dirsearched_customlist.txt;
echo "All done!";
