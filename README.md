
# FastRecon

## Overview
FastRecon is a semi-automated reconnaissance tool for web security testing. It automates gathering information while allowing for manual depth when needed.

## Features
- DNS Enumeration & Brute Forcing
- Port Scanning
- URL Harvesting
- JavaScript Analysis
- Slack Integration for notifications
- Screenshot capturing
- Results archiving

## Prerequisites
- Go (latest version)
- Node, NPM
- Make, GCC, jq, nmap, bat
- Headless Chrome dependencies for certain tasks

### Installing Headless Chrome Dependencies

```bash
sudo apt install libnss3-dev gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget libgbm-dev
```

## Install
Some tools are installed but not used in the recon. They are installed to prepare for the work following recon. 
```bash
git clone https://github.com/jonasonline/fastrecon.git
cd fastrecon
./init.sh
```

## Usage
```bash
mkdir scope/[target]
touch scope/[target]/roots.txt
```
This will create a subfolder and a root domains file for each base target. Edit the file to add root domains before running recon. 

Here are all the switches the script supports.

```bash
Usage:
  ./scan.sh [target] [flags]

INPUT:
  [target] string      Specify the target name (the name of the folder within the 'scope' directory.)

FLAGS:
  --slackToken string      Slack token for notifications.
  --slackChannel string    Slack channel ID for sending notifications.
  --copyResultsToPath      Specify a path to copy the scan results archive.
  --bruteDns               Enable DNS subdomain brute-forcing.
  --interestingUrlCheck    Perform a detailed check for potentially interesting URLs.
  --uploadToSlack          Upload the results archive to a specified Slack channel.

```

## Output
- **`roots.txt`**

  **Description**: Copy of the root domains file for the target from the `scope` directory, serving as the initial input for reconnaissance, containing base domains to be explored.

- **`subs.txt`**

  **Description**: List of subdomains identified through tools like subfinder and optionally brute-forced via shuffledns, providing a comprehensive list of potential targets.

- **`subs_asn_info.txt`**

  **Description**: ASN (Autonomous System Number) information for the discovered subdomains, useful for understanding the network landscape of the target domains.

- **`asns.txt`**

  **Description**: Filtered list of unique ASNs derived from subdomains' ASN information, useful for identifying networks of interest.

- **`subs_ips.txt`**

  **Description**: IP addresses resolved from the list of subdomains, crucial for further scans like port scanning and service identification.

- **`subs_from_ptr_query.txt`**

  **Description**: Results from reverse DNS lookups (PTR queries) on IP addresses, revealing additional subdomains or hostnames not found through forward DNS lookups.

- **`alive_ports_per_ip.txt`** and **`alive_ports_per_sub.txt`**

  **Description**: Results from port scanning operations, listing open ports on IP addresses and subdomains, indicating potential services for further investigation.

- **`temp/urls_to_crawl.txt`**

  **Description**: Aggregated URLs prepared for crawling, formed by appending `http://` or `https://` based on the port (80 or 443).

- **`urls.txt`**

  **Description**: Cumulation of URLs identified as interesting through crawling and other methods, containing potential targets for vulnerability scanning.

- **`js/`** (directory)

  **Description**: Contains downloaded JavaScript files from crawled URLs for analysis of endpoints, hardcoded secrets, or potentially sensitive information.

- **`link_finder_links.txt`**, **`link_finder_parameters.txt`**, and **`link_finder_wordlist.txt`**

  **Description**: Output from analyzing JavaScript files, revealing internal paths, API endpoints, and parameter names useful for crafting web application attacks.

- **`http.out.json`**

  **Description**: Results from httpx scans, including HTTP response data, headers, and optionally screenshots, providing a snapshot of web service configurations and technologies.

- **`screenshotGallery.html`**

  **Description**: An HTML file containing a gallery of screenshots from scanned URLs, offering a quick visual identification of noteworthy web applications or login pages.

- **`[id]-[timestamp].zip`**
  
  **Description**: A compressed archive of all scan results, facilitating easy download, sharing, or archiving of the reconnaissance phase output for a given target.


## Contributing
Contributions are welcome. Feel free to open issues or submit PRs.

## Acknowledgments
Thanks to the security and open-source communities for tools and inspiration.
