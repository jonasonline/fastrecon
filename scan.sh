#!/bin/bash

# source: https://blog.projectdiscovery.io/building-one-shot-recon/ and https://www.youtube.com/watch?v=kWcuZvNXmDM 

# set vars
id="$1"
ppath="$(pwd)"
scope_path="$ppath/scope/$id"

bruteDns=false
fullUrlCheck=false

for arg in "$@"
do
    case $arg in
        --brutedns)
        bruteDns=true
        shift # Remove --brutedns from args
        ;;
        --fullurlcheck)
        fullUrlCheck=true
        shift # Remove --fullurlcheck from args
        ;;
    esac
done

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
cat "$scan_path/roots.txt" | subfinder | anew "$scan_path/subs.txt" | wc -l
if [ "$bruteDns" = true ]; then
  echo "Brute force DNS subdomains"
  cat "$scan_path/roots.txt" | shuffledns -w "$ppath/lists/jhaddix_all.txt" -r "$ppath/lists/resolvers.txt" | anew "$scan_path/subs.txt" | wc -l
fi

## Not Working 
# cat "$scan_path/subs.txt" | sed -e 's/\./\n/g' -e 's/\-/\n/g' -e 's/[0-9]*//g' | sort -u | anew "$scan_path/domain_words.txt"
# ./DNSCewl/DNScewl -tL "$scan_path/subs_clean.txt" 

### DNS Resolution
# Removing wildcard subdomains
#puredns resolve "$scan_path/subs.txt" -r "$ppath/lists/resolvers.txt" -w "$scan_path/resolved.txt" | wc -l
#dnsx -l "$scan_path/resolved.txt" -json -o "$scan_path/dns.json" -r "$ppath/lists/resolvers.txt" | jq -r ' .a?[]?' | anew "$scan_path/ips.txt" | wc -l

cat "$scan_path/subs.txt" | dnsx -ro -silent -r "$ppath/lists/resolvers.txt" | anew "$scan_path/subs_ips.txt" | dnsx -ptr -ro -r "$ppath/lists/resolvers.txt" -silent | anew "$scan_path/subs_additional.txt"

### Port Scanning & HTTP Server Discovery
cat "$scan_path/subs_ips.txt" | naabu -top-ports 1000 -silent | anew "$scan_path/alive_ports_per_ip.txt"
cat "$scan_path/subs.txt" | naabu -top-ports 1000 -silent | anew "$scan_path/alive_ports_per_sub.txt"
awk '/:80$/{print "http://" $0} /:443$/{print "https://" $0}' "$scan_path/alive_ports_per_sub.txt" | sed 's/:80//g; s/:443//g' | anew "$scan_path/urls_to_crawl.txt"

### Crawling and harvesring URLs
cat "$scan_path/urls_to_crawl.txt" | katana -jc -aff | anew "$scan_path/crawl.txt"
cat "$scan_path/roots.txt" | gau --blacklist ttf,woff,woff2,eot,otf,svg,png,jpg,jpeg,gif,bmp,pdf,mp3,mp4,mov --subs | anew "$scan_path/gau.txt"

### Sorting and removing junk and dups
grep -h '^http' "$scan_path/gau.txt" "$scan_path/crawl.txt" | sort | anew "$scan_path/urls.txt"

### JavaScript Pulling
cat "$scan_path/urls.txt" | grep "\.js$" | sort | uniq | httpx -mc 200 -sr -srd "$scan_path/js"
python3 xnLinkFinder/xnLinkFinder.py  -i "$scan_path/js" -o "$scan_path/link_finder_links.txt" -op "$scan_path/link_finder_parameters.txt" 
while IFS= read -r domain; do grep -E "^(http|https)://[^/]*$domain" "$scan_path/link_finder_links.txt"; done < "$scan_path/roots.txt" | sort -u | anew "$scan_path/urls.txt"

### Gathering interesting stuff
### TODO - filter extensive probing ### cat "$scan_path/urls.txt" | unfurl format %s://%d%p | grep -vE "\.(js|css|ico)$" | sort | uniq 
cat "$scan_path/urls.txt" | unfurl format %s://%d | sort | uniq | httpx -fhr -sr -srd "$scan_path/responses" -screenshot -json -o "$scan_path/http.json"
if [ "$fullUrlCheck" = true ]; then
  echo "Performing full URL check is enabled"
  cat "$scan_path/urls.txt" | unfurl format %s://%d%p | sort | uniq | httpx -silent -title -status-code -mc 403,400,500 | anew "$scan_path/interesting_urls.txt"
fi
cat "$scan_path/urls.txt" | unfurl keypairs | anew "$scan_path/url_keypairs.txt"

### Fuzzing - disabled
#ffuf -c -w OneListForAll/onelistforallmicro.txt:list -w $scan_path/interesting_urls_formatted.txt:host -u host/list -mc 200,400,500,403 -o "$scan_path/fuzzed.txt"

### Create screenshot gallery
output_file="$scan_path/screenshotGallery.html"

echo "<html>" > "$output_file"
echo "<head>" >> "$output_file"
echo "<style>" >> "$output_file"
echo "body { display: flex; flex-wrap: wrap; justify-content: center; padding: 10px; }" >> "$output_file"
echo ".image-container { margin: 10px; text-align: center; }" >> "$output_file"
echo "img { max-width: 300px; height: auto; border: 1px solid #ccc; }" >> "$output_file"
echo "</style>" >> "$output_file"
echo "</head>" >> "$output_file"
echo "<body>" >> "$output_file"

# Find all .jpg, .jpeg, .png, .gif files in the current folder and subfolders.
find "$scan_path" -type f \( -iname \*.jpg -o -iname \*.jpeg -o -iname \*.png -o -iname \*.gif \) | while read -r img
do
    folder_name=$(basename "$(dirname "${img}")")
    echo "<div class='image-container'>" >> "$output_file"
    echo "<a href=\"${img}\"><img src=\"${img}\" alt=\"Image\" title=\"${folder_name}\"></a>" >> "$output_file"
    echo "<div><a href=\"http://${folder_name}\">${folder_name}</a></div>" >> "$output_file"
    echo "</div>" >> "$output_file"
done

echo "</body>" >> "$output_file"
echo "</html>" >> "$output_file"


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