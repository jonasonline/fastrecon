#!/bin/bash

# Source: https://blog.projectdiscovery.io/building-one-shot-recon/ and https://www.youtube.com/watch?v=kWcuZvNXmDM 

# Set variables
echo "Setting up variables"
id="$1"
ppath="$(pwd)"
scope_path="$ppath/scope/$id"

bruteDns=false
interestingUrlCheck=false
uploadToSlack=false

slack_token=""
slack_channel=""
copyResultsToPath=""

rate=0

echo "Parsing command line arguments"
for ((i = 1; i <= $#; i++ )); do
    if [ "${!i}" = "--slackToken" ]; then
        i=$((i + 1))
        slack_token="${!i}"
    elif [ "${!i}" = "--slackChannel" ]; then
        i=$((i + 1))
        slack_channel="${!i}"
    elif [ "${!i}" = "--copyResultsToPath" ]; then
        i=$((i + 1))
        copyResultsToPath="${!i}"
    elif [ "${!i}" = "--rate" ]; then
        i=$((i + 1))
        rate="${!i}"    
    elif [ "${!i}" = "--bruteDns" ]; then
        bruteDns=true
    elif [ "${!i}" = "--uploadToSlack" ]; then
        uploadToSlack=true
    fi
done

timestamp="$(date +%s)"
scan_path="$ppath/scans/$id-$timestamp"

echo "Checking for existing scope path: $scope_path"
# Exit if scope path does not exist
if [ ! -d "$scope_path" ]; then
    echo "Path doesn't exist"
    exit 1
fi

echo "Creating scan directories"
mkdir -p "$scan_path/temp"

### PERFORM SCAN ###
echo "Starting scan against roots:"
cat "$scope_path/roots.txt"
cp -v "$scope_path/roots.txt" "$scan_path/roots.txt"

echo "Starting DNS enumeration"
# Check if the curated subs file exists
if [ ! -f "$scope_path/subs_curated.txt" ]; then
    # If the file does not exist, run the commands
    echo "File subs_curated.txt not found, starting enumeration"
    cat "$scan_path/roots.txt" | subfinder -all -recursive | anew "$scan_path/subs.txt" | dnsx -silent -asn | anew  "$scan_path/subs_asn_info.txt" | awk -F'[][]' '{print $2}' | awk '{print $1}' | cut -d',' -f1 | grep -v "^AS0$" | anew "$scan_path/asns.txt"
    
    # Check if brute force DNS subdomains option is enabled
    if [ "$bruteDns" = true ]; then
        echo "Brute force DNS subdomains"
        cat "$scan_path/roots.txt" | shuffledns -w "$ppath/lists/jhaddix_all.txt" -r "$ppath/lists/resolvers.txt" | anew "$scan_path/subs.txt" | wc -l
    fi
else
    echo "The file $scope_path/subs_curated.txt already exists, skipping scan."
fi

echo "Performing DNS resolution"
cat "$scan_path/subs.txt" | dnsx -ro -silent -r "$ppath/lists/resolvers.txt" | anew "$scan_path/subs_ips.txt" | dnsx -ptr -ro -r "$ppath/lists/resolvers.txt" -silent | anew "$scan_path/subs_from_ptr_query.txt"

echo "Starting port scanning and HTTP server discovery"
cat "$scan_path/subs_ips.txt" "$scan_path/subs.txt" | naabu -top-ports 1000 -silent | anew "$scan_path/alive_ports.txt"
awk '/:80$/{print "http://" $0} /:443$/{print "https://" $0}' "$scan_path/alive_ports.txt" | sed 's/:80//g; s/:443//g' | anew "$scan_path/temp/urls_to_crawl.txt"

echo "Crawling and harvesting URLs"
if [ "$rate" -ne 0 ]; then
    echo "Rate limited scan"
    cat "$scan_path/temp/urls_to_crawl.txt" | katana -jc -jsl -aff -kf all -rl "$rate" | anew "$scan_path/temp/crawl_out.txt"
else
    cat "$scan_path/temp/urls_to_crawl.txt" | katana -jc -jsl -aff -kf all | anew "$scan_path/temp/crawl_out.txt"
fi
echo "Crawling completed, URLs harvested"

echo "Sorting and removing junk and duplicates"
grep -h '^http' "$scan_path/temp/gau.txt" "$scan_path/temp/crawl_out.txt" | sort | anew "$scan_path/urls.txt"

echo "Pulling JavaScript files"
if [ "$rate" -ne 0 ]; then
    echo "Rate limited scan"
    cat "$scan_path/urls.txt" | grep -E "\.js(\.map)?($|\?)" | sort | uniq | httpx -silent -mc 200 -rl "$rate" -sr -srd "$scan_path/js"
else
    cat "$scan_path/urls.txt" | grep -E "\.js(\.map)?($|\?)" | sort | uniq | httpx -silent -mc 200 -sr -srd "$scan_path/js"
fi
echo "JavaScript pulling completed"

echo "Scraping stuff from JavaScript files"
python3 $PWD/xnLinkFinder/xnLinkFinder.py -i "$scan_path/js" -o "$scan_path/link_finder_links.txt" -op "$scan_path/link_finder_parameters.txt" -owl "$scan_path/link_finder_wordlist.txt"
while IFS= read -r domain; do grep -E "^(http|https)://[^/]*$domain" "$scan_path/link_finder_links.txt"; done < "$scan_path/roots.txt" | sort -u | anew "$scan_path/urls.txt"
echo "Scraping JavaScript content completed"

# Processing functions for JavaScript and .map files
echo "Processing JavaScript and .map files"
process_files "$js_dir"
process_directory "$js_dir"
execute_in_subdirectories "$js_dir"

echo "Updating and notifying new entries"
update_and_notify

echo "Creating zip archive for download"
zip -q -r "$id-$timestamp.zip" . 
cd $ppath

if [ -n "$slack_token" ] && [ -n "$slack_channel" ] && [ $uploadToSlack = true ]; then    
    echo "Uploading results to Slack"
    file_path="$scan_path/$id-$timestamp.zip"
    filename="$id-$timestamp.zip"

    curl -F file=@"$file_path" -F channels="$slack_channel" -F token="$slack_token" -F filename="$filename" https://slack.com/api/files.upload
fi

if [ -n "$copyResultsToPath" ]; then
    echo "Copying results to specified path"
    cp $scan_path/$id-$timestamp.zip $copyResultsToPath
fi

# Calculate time difference
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

echo -e "\nScan $id took $time"

if [ -n "$slack_token" ] && [ -n "$slack_channel" ] ; then    
    echo "Sending completion notification to Slack"
    curl -X POST -H "Authorization: Bearer $slack_token" -H 'Content-type: application/json; charset=utf-8' --data '{"channel":"'"$slack_channel"'","text":"Scan '"$id"' took '"$time"'"}' https://slack.com/api/chat.postMessage
fi
