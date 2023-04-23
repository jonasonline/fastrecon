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

### ADD SCAN LOGIC HERE ###


# calculate time diff
end_time=$(date +%s)
seconds="$(expr $end_time - $timestamp)"
time=""

if [[ "$seconds" -gt 59 ]]
then
    minutes=$(expr Sseconds / 60)
    time="$minutes minutes"

else
    time="$seconds seconds"
fi

echo "Scan $id took $time"
#echo "Scan $id took $time" | notify