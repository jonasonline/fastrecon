
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
- Make, GCC, jq, nmap, bat
- Headless Chrome dependencies for certain tasks

### Installing Headless Chrome Dependencies

```bash
sudo apt install libnss3-dev gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget libgbm-dev
```

## Install
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

## Contributing
Contributions are welcome. Feel free to open issues or submit PRs.

## Acknowledgments
Thanks to the security and open-source communities for tools and inspiration.
