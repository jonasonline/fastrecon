# fastrecon - a simple script for semi automated recon 

### Prerequisites
- GO (latest version)
- make
- gcc
- jq
- nmap
- bat

#### Install prerequisites for headless chrome
```bash
sudo apt-get install libnss3-dev
sudo apt-get install -y gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget libgbm-dev
```

### Install
```bash
./init.sh
```

### Usage
Create a subfolder and a root domains file for each base target

```bash
mkdir scope/[target]
touch scope/[target]/roots.txt
```

Run initial recon
```bash
./scan.sh [target]
```

####  Search for wildcard domains
