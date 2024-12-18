#!/bin/bash

# source: https://blog.projectdiscovery.io/building-one-shot-recon/ and https://www.youtube.com/watch?v=kWcuZvNXmDM 

# set vars
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

# exit if scope path doesnt exist
if [ ! -d "$scope_path" ]; then
    echo "Path doesn't exist"
    exit 1
fi

mkdir -p "$scan_path/temp"

### PERFORM SCAN ###
echo "Starting scan against roots:"
cat "$scope_path/roots.txt"
cp -v "$scope_path/roots.txt" "$scan_path/roots.txt"

### DNS Enum
echo "Starting DNS enumeration and resolvning"
## Requires non-free API key## cat "$scan_path/roots.txt" | haktrails subdomains | anew subs.txt | wc -l
# Check if the curated subs file exists
if [ ! -f "$scope_path/subs_curated.txt" ]; then
    # If the file does not exist, run the commands
    cat "$scan_path/roots.txt" | subfinder -all -recursive | anew "$scan_path/subs.txt" | dnsx -silent -asn | anew  "$scan_path/subs_asn_info.txt" | awk -F'[][]' '{print $2}' | awk '{print $1}' | cut -d',' -f1 | grep -v "^AS0$" | anew "$scan_path/asns.txt"
    
    # Check if brute force DNS subdomains option is enabled
    if [ "$bruteDns" = true ]; then
        echo "Brute force DNS subdomains"
        cat "$scan_path/roots.txt" | shuffledns -w "$ppath/lists/jhaddix_all.txt" -r "$ppath/lists/resolvers.txt" | anew "$scan_path/subs.txt" | wc -l
    fi
else
    echo "The file $scope_path/subs_curated.txt already exists, skipping scan."
fi
echo "Finished DNS enumeration"

## Not Working 
# cat "$scan_path/subs.txt" | sed -e 's/\./\n/g' -e 's/\-/\n/g' -e 's/[0-9]*//g' | sort -u | anew "$scan_path/domain_words.txt"
# ./DNSCewl/DNScewl -tL "$scan_path/subs_clean.txt" 

### DNS Resolution
# Removing wildcard subdomains
#puredns resolve "$scan_path/subs.txt" -r "$ppath/lists/resolvers.txt" -w "$scan_path/resolved.txt" | wc -l
#dnsx -l "$scan_path/resolved.txt" -json -o "$scan_path/dns.json" -r "$ppath/lists/resolvers.txt" | jq -r ' .a?[]?' | anew "$scan_path/ips.txt" | wc -l

cat "$scan_path/subs.txt" | dnsx -ro -silent -r "$ppath/lists/resolvers.txt" | anew "$scan_path/subs_ips.txt" | dnsx -ptr -ro -r "$ppath/lists/resolvers.txt" -silent | anew "$scan_path/subs_from_ptr_query.txt"

echo "Finished DNS enumeration and resolving"

### Port Scanning & HTTP Server Discovery
echo "Starting port scan"
cat "$scan_path/subs_ips.txt" "$scan_path/subs.txt" | naabu -top-ports 1000 -silent | anew "$scan_path/alive_ports.txt"
#cat "$scan_path/subs.txt" | naabu -top-ports 1000 -silent | anew "$scan_path/alive_ports_per_sub.txt"
awk '/:80$/{print "http://" $0} /:443$/{print "https://" $0}' "$scan_path/alive_ports.txt" | sed 's/:80//g; s/:443//g' | anew "$scan_path/temp/urls_to_crawl.txt"
echo "Finished port scan"


### Crawling and harvesring URLs
echo "Starting crawling and URL harvesting"
if [ "$rate" -ne 0 ]; then
    echo "Rate limited scan"
    cat "$scan_path/temp/urls_to_crawl.txt" | katana -jc -jsl -aff -kf all -rl "$rate" | anew "$scan_path/temp/crawl_out.txt"
    cat "$scan_path/roots.txt" | urlfinder -rl "$rate" -all | anew "$scan_path/temp/urls_unsorted.txt"
else
    cat "$scan_path/temp/urls_to_crawl.txt" | katana -jc -jsl -aff -kf all | anew "$scan_path/temp/crawl_out.txt"
    cat "$scan_path/roots.txt" | urlfinder -all | anew "$scan_path/temp/urls_unsorted.txt"
fi
cat "$scan_path/roots.txt" | gau --blacklist ttf,woff,woff2,eot,otf,svg,png,jpg,jpeg,gif,bmp,pdf,mp3,mp4,mov --subs | anew "$scan_path/temp/gau.txt"

### Sorting and removing junk and dups
grep -h '^http' "$scan_path/temp/gau.txt" "$scan_path/temp/crawl_out.txt" | sort | anew "$scan_path/urls.txt"
cat "$scan_path/temp/urls_unsorted.txt" | sort | anew "$scan_path/urls.txt"
echo "Finished crawling and URL harvesting"

### JavaScript Pulling
echo "Starting JS processing"
if [ "$rate" -ne 0 ]; then
    echo "Rate limited scan"
    cat "$scan_path/urls.txt" | grep -E "\.js(\.map)?($|\?)" | sort | uniq | httpx -silent -mc 200 -rl "$rate" -sr -srd "$scan_path/js"
else
    cat "$scan_path/urls.txt" | grep -E "\.js(\.map)?($|\?)" | sort | uniq | httpx -silent -mc 200 -sr -srd "$scan_path/js"
fi

python3 $PWD/xnLinkFinder/xnLinkFinder.py -i "$scan_path/js" -o "$scan_path/link_finder_links.txt" -op "$scan_path/link_finder_parameters.txt" -owl "$scan_path/link_finder_wordlist.txt"
while IFS= read -r domain; do grep -E "^(http|https)://[^/]*$domain" "$scan_path/link_finder_links.txt"; done < "$scan_path/roots.txt" | sort -u | anew "$scan_path/urls.txt"
echo "Done harvesting JS files and links"

# Base directory containing httpx response files for JavaScript
js_dir="$scan_path/js"
echo "Processing JS files"

# Function to process JavaScript files
process_files() {
    local directory="$1"
    # Iterate through each item in the directory
    for txt_file in "$directory"/*; do
        if [[ -d "$txt_file" ]]; then
            # If item is a directory, recursively process this subdirectory
            process_files "$txt_file"
        elif [[ $txt_file == *.txt && $(basename "$txt_file") != "index.txt" ]]; then
            # Extract JavaScript file name from the txt content, only the file name, not the full path
            js_name=$(grep -oE 'GET /.* HTTP/1.1' "$txt_file" | sed -E 's/GET \/| HTTP\/1.1//g' | awk -F/ '{print $NF}')
            new_txt_file_path="$directory/${js_name}.txt"

            # Ensure a unique name for the .txt file
            if [[ -e "$new_txt_file_path" ]]; then
                suffix=2
                while [[ -e "${new_txt_file_path%.*}_$suffix.${new_txt_file_path##*.}" ]]; do
                    ((suffix++))
                done
                new_txt_file_path="${new_txt_file_path%.*}_$suffix.${new_txt_file_path##*.}"
            fi

            # Determine start and end lines for JavaScript extraction
            start_line=$(awk '/^\r?$/{i++}i==2{print NR; exit}' "$txt_file")
            end_line=$(awk 'END{print NR}' "$txt_file")
            is_chunked=$(grep -m 1 "Transfer-Encoding: chunked" "$txt_file" | wc -l)

            if [ "$is_chunked" -eq 1 ]; then
                start_line=$((start_line + 2)) # Adjust for chunked encoding
                end_line=$(awk '/^0\r?$/{print NR; exit}' "$txt_file")
                end_line=$((end_line - 1))
            else
                start_line=$((start_line + 1))
                end_line=$((end_line - 2))
            fi

            # Extract JavaScript into a new file
            js_file_path="${directory}/${js_name}"

            # Ensure a unique name for the JavaScript file
            if [[ -e "$js_file_path" ]]; then
                suffix=2
                while [[ -e "${js_file_path%.*}_$suffix.${js_file_path##*.}" ]]; do
                    ((suffix++))
                done
                js_file_path="${js_file_path%.*}_$suffix.${js_file_path##*.}"
            fi

            # Extract the JavaScript content to a new file
            sed -n "${start_line},${end_line}p" "$txt_file" > "$js_file_path"

            # Rename the original txt file to new name with .txt appended
            mv -v "$txt_file" "$new_txt_file_path"
        fi
    done
}

# Start processing files from the base js directory
process_files "$js_dir"

# Downloading .map files
process_directory() {
    local directory="$1"

    # Recursively find all .txt files under the specified directory
    find "$directory" -type f -name "*.txt" | while read -r txt_file; do
        echo "Processing: $txt_file"

        # Find the line that contains sourceMappingURL
        map_url_line=$(grep -m 1 "^//# sourceMappingURL=" "$txt_file")
        if [[ ! -z "$map_url_line" ]]; then
            # Extract the .map file name
            map_file_name=$(echo "$map_url_line" | sed 's/^\/\/# sourceMappingURL=//')

            # Get the path to the .js file from the last line in the .txt file
            js_file_path=$(tail -n 1 "$txt_file" | tr -d '\r')

            # Extract the base URL from the .js file's path
            base_url=$(dirname "$js_file_path")

            # Create the URL for the .map file
            map_file_url="$base_url/$map_file_name"

            # Get the directory path of the .txt file to determine where to save the .map file
            txt_file_dir=$(dirname "$txt_file")

            echo "Downloading .map file from: $map_file_url to: $txt_file_dir/"

            # Use curl to download the .map file to the same directory as the .txt file
            curl -o "${txt_file_dir}/${map_file_name}" "$map_file_url"
        fi
    done
}

# Call the function with the starting directory as argument
process_directory "$js_dir"
echo "Starting JS code recovery"

# Function to recursively execute a command in all subdirectories of a given directory
execute_in_subdirectories() {
    local base_directory="$1"

    # Find all directories under the specified base directory
    find "$base_directory" -type d | while read -r directory; do
        echo "Executing command in: $directory"

        # Run the command with the directory as its input
        recover-source -i "$directory"
    done
}

# Call the function with the path to the js directory
execute_in_subdirectories "$js_dir"
echo "Finished JS processing"

echo "Starting gathering url responses"
if [ "$rate" -ne 0 ]; then
    echo "Rate limited scan"
    cat "$scan_path/urls.txt" | unfurl format %s://%d | sort | uniq | httpx -rl "$rate" -silent -fhr -sr -srd "$scan_path/responses" -screenshot -esb -ehb -json -o "$scan_path/http.out.json" > /dev/null 2>&1
else
    cat "$scan_path/urls.txt" | unfurl format %s://%d | sort | uniq | httpx -silent -fhr -sr -srd "$scan_path/responses" -screenshot -esb -ehb -json -o "$scan_path/http.out.json" > /dev/null 2>&1
fi

cat "$scan_path/urls.txt" | unfurl keypairs | anew "$scan_path/url_keypairs.txt"
echo "Finished gathering url responses"


### Create screenshot gallery
echo "Starting creating screenshot gallery"
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

# Find all .jpg, .jpeg, .png, .gif files in the current folder and subfolders to create a screeshot index page.
find "$scan_path" -type f \( -iname \*.jpg -o -iname \*.jpeg -o -iname \*.png -o -iname \*.gif \) | while read -r img
do
    # Konverterar den absoluta sökvägen till en relativ sökväg
    relative_path=$(realpath --relative-to="$scan_path" "$img")
    # Extraherar mappnamnet som också är URL:en
    url=$(basename "$(dirname "$img")")

    echo "<div class='image-container'>" >> "$output_file"
    echo "<a href=\"$relative_path\"><img src=\"$relative_path\" alt=\"Image\" title=\"$url\"></a>" >> "$output_file"
    # Använder mappnamnet som URL för länken
    echo "<div><a href=\"http://$url\">$url</a></div>" >> "$output_file"
    echo "</div>" >> "$output_file"
done

echo "</body>" >> "$output_file"
echo "</html>" >> "$output_file"
echo "Finished creating screenshot gallery"

echo "Saving results and sending notifications"
update_and_notify() {
    local new_subs="$scan_path/subs.txt"
    local new_urls="$scan_path/urls.txt"
    local old_subs="$scope_path/subs.txt"
    local old_urls="$scope_path/urls.txt"
    local notify_config="$HOME/.config/notify/provider-config.yaml"

    # Check for the notify configuration file
    if [ ! -f "$notify_config" ]; then
        echo "Notify configuration file not found: $notify_config"
        return 1
    fi

    # Check and update subs.txt
    if [ -f "$new_subs" ]; then
        # Append new unique subdomains to the existing list and notify if there are new entries
        local old_subs_exists_and_not_empty=false
        if [ -f "$old_subs" ] && [ -s "$old_subs" ]; then
            old_subs_exists_and_not_empty=true
            echo "The old subs file exists and is not empty."
        else
            echo "The old subs file does not exist or is empty."
        fi

        if ! cmp --silent "$new_subs" "$old_subs"; then
            local new_entries=$(cat "$new_subs" "$old_subs" | anew $old_subs)
            if [ ! -z "$new_entries" ] && [ "$old_subs_exists_and_not_empty" = true ]; then
                echo "$new_entries" | notify -bulk -silent
            fi
        fi
    fi

    # Check and update urls.txt
    if [ -f "$new_urls" ]; then
        # Append new unique URLs to the existing list and notify if there are new entries
        local old_urls_exists_and_not_empty=false
        if [ -f "$old_urls" ] && [ -s "$old_urls" ]; then
            old_urls_exists_and_not_empty=true
            echo "The old urls file exists and is not empty."
        else
            echo "The old urls file does not exist or is empty."
        fi
        if ! cmp --silent "$new_urls" "$old_urls"; then
            local new_entries=$(cat "$new_urls" "$old_urls" | anew $old_urls)
            if [ ! -z "$new_entries" ] && [ "$old_urls_exists_and_not_empty" = true ]; then
                echo "New entries in $old_urls" | notify -bulk -silent
            fi
        fi
    fi
}

update_and_notify

# creating zip for download
cd $scan_path
zip -q -r "$id-$timestamp.zip" . 
cd $ppath

if [ -n "$slack_token" ] && [ -n "$slack_channel" ] && [ $uploadToSlack = true ]; then    
    # Upload 
    file_path="$scan_path/$id-$timestamp.zip"
    filename="$id-$timestamp.zip"

    curl -F file=@"$file_path" -F channels="$slack_channel" -F token="$slack_token" -F filename="$filename" https://slack.com/api/files.upload
fi

if [ -n "$copyResultsToPath" ]; then
    cp $scan_path/$id-$timestamp.zip $copyResultsToPath
fi

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

echo -e "\nScan $id took $time"

if [ -n "$slack_token" ] && [ -n "$slack_channel" ] ; then    
    curl -X POST -H "Authorization: Bearer $slack_token" -H 'Content-type: application/json; charset=utf-8' --data '{"channel":"'"$slack_channel"'","text":"Scan '"$id"' took '"$time"'"}' https://slack.com/api/chat.postMessage
fi