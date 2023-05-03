#!/bin/bash

# source: https://blog.projectdiscovery.io/building-one-shot-recon/

# set vars
id="$1"
ppath="$(pwd)"
scope_path="$ppath/scope/$id"

timestamp="$(date +%s)"
scan_path="$ppath/scans/$id-$timestamp"

# exit if scope path doesnt exist
if [ ! -d "$scope_path" ]; then
    echo "Path doesn't exist"
    exit 1
fi

mkdir -p "$scan_path"

cd "$scan_path"

### PERFORM SCAN ###
echo "Starting scan against roots:"
cat "$scope_path/roots.txt"
cp -v "$scope_path/roots.txt" "$scan_path/roots.txt"

### DNS Enum
## Requires non-free API key## cat "$scan_path/roots.txt" | haktrails subdomains | anew subs.txt | wc -l
cat "$scan_path/roots.txt" | subfinder | anew subs.txt | wc -l
cat "$scan_path/roots.txt" | shuffledns -w "$ppath/lists/pry-dns.txt" -r "$ppath/lists/resolvers.txt" | anew subs.txt | wc -l

### DNS Resolution
puredns resolve "$scan_path/subs.txt" -r "$ppath/lists/resolvers.txt" -w "$scan_path/resolved.txt" | wc -l
dnsx -l "$scan_path/resolved.txt" -json -o "$scan_path/dns.json" | jq -r ' .a?[]?' | anew "$scan_path/ips.txt" | wc -l

### Port Scanning & HTTP Server Discovery
nmap -T4 -vv -iL "$scan_path/ips.txt" --top-ports 3000 -n --open -oX "$scan_path/nmap.xml"
tew -x "$scan_path/nmap.xml" -dnsx "$scan_path/dns.json" --vhost -o "$scan_path/hostport.txt" | httpx -sr -srd "$scan_path/responses" -screenshot -json -o "$scan_path/http.json"

cat "$scan_path/http.json" | jq -r '.url' | sed -e 's/:80$//g' -e 's/:443$//g' | sort -u > "$scan_path/http.txt"

### Crawling and harvesring URLs
gospider -S "$scan_path/http.txt" --json | grep "{" | jq -r '.output?' | tee "$scan_path/crawl.txt"
cat "$scan_path/http.txt" | katana -jc -aff | tee "$scan_path/crawl_kat.txt" | anew "$scan_path/crawl.txt"
cat "$scan_path/roots.txt" | gau --blacklist ttf,woff,woff2,eot,otf,svg,png,jpg,jpeg,gif | tee "$scan_path/gau.txt"

### Sorting and removing junk and dups
grep -h '^http' "$scan_path/gau.txt" "$scan_path/crawl.txt" | sort | uniq > "$scan_path/urls.txt"

### JavaScript Pulling
cat "$scan_path/urls.txt" | grep "\.js" | httpx -sr -srd "$scan_path/js"


# calculate time diff
end_time=$(date +%s)
seconds="$(expr $end_time - $timestamp)"
time=""

if [[ "$seconds" -gt 59 ]]
then
    minutes=$(expr $seconds / 60)
    time="$minutes minutes"

else
    time="$seconds seconds"
fi

echo "Scan $id took $time"