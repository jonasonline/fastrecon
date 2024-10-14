#!/bin/bash

set -e

# Function to clone or update a git repository
clone_or_update_repo() {
    local repo_url=$1
    local repo_dir=$2

    if [ -d "$repo_dir" ]; then
        echo "Updating repository: $repo_dir"
        cd "$repo_dir"
        git pull
        cd ..
    else
        echo "Cloning repository: $repo_url"
        git clone "$repo_url" "$repo_dir"
    fi
}

# Create necessary directories
mkdir -p scope scans lists

# Download lists only if they do not exist
download_if_not_exists() {
    local url=$1
    local output=$2

    if [ ! -f "$output" ]; then
        echo "Downloading $output..."
        wget -q -O "$output" "$url"
    else
        echo "File $output already exists. Skipping download."
    fi
}

# Download list files
download_if_not_exists "https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt" "lists/resolvers.txt"
download_if_not_exists "https://gist.githubusercontent.com/jhaddix/f64c97d0863a78454e44c2f7119c2a6a/raw/96f4e51d96b2203f19f6381c8c545b278eaa0837/all.txt" "lists/jhaddix_all.txt"
download_if_not_exists "https://gist.githubusercontent.com/nullenc0de/96fb9e934fc16415fbda2f83f08b28e7/raw/146f367110973250785ced348455dc5173842ee4/content_discovery_nullenc0de.txt" "lists/content_discovery_nullenc0de.txt"

# Update package list and install necessary packages
sudo apt-get update
sudo apt-get install -y libpcap-dev libgbm1 libxrandr2 libcairo2 libatk1.0-0 libatk-bridge2.0-0 \
libxcomposite1 libxdamage1 libxfixes3 libcups2 libdrm2 libpango-1.0-0 libpangocairo-1.0-0 \
libxkbcommon0 libx11-xcb1

# Install or update Go-based tools
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest
go install -v github.com/tomnomnom/anew@latest
go install -v github.com/d3mondev/puredns/v2@latest
go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go install -v github.com/pry0cc/tew@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install -v github.com/projectdiscovery/katana/cmd/katana@latest
go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
go install -v github.com/lc/gau/v2/cmd/gau@latest
go install -v github.com/owasp-amass/amass/v3/...@master
go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
go install -v github.com/tomnomnom/unfurl@latest
go install -v github.com/ffuf/ffuf/v2@latest
go install -v github.com/KathanP19/Gxss@latest
go install -v github.com/projectdiscovery/notify/cmd/notify@latest
go install -v github.com/tomnomnom/gf@latest
GO111MODULE=on go install -v github.com/jaeles-project/gospider@latest

# Install npm packages globally if not already installed
install_npm_package() {
    local package=$1
    if ! npm list -g --depth=0 | grep -q "$package@"; then
        echo "Installing npm package: $package"
        npm install -g "$package"
    else
        echo "npm package $package is already installed. Skipping."
    fi
}

install_npm_package "js-beautify"
install_npm_package "recover-source"

# Clone or update gf repository and copy examples
GF_DIR="$HOME/gf"
clone_or_update_repo "https://github.com/tomnomnom/gf.git" "$GF_DIR"
mkdir -p ~/.gf
cp -r "$GF_DIR/examples/"* ~/.gf/

# Install or upgrade pip packages
if pip3 show uro > /dev/null 2>&1; then
    echo "Upgrading pip package: uro"
    pip3 install --upgrade uro
else
    echo "Installing pip package: uro"
    pip3 install uro
fi

# Install feroxbuster
FEROXBUSTER_PATH="$HOME/.local/bin/feroxbuster"
if [ ! -f "$FEROXBUSTER_PATH" ]; then
    echo "Installing feroxbuster..."
    curl -sL https://raw.githubusercontent.com/epi052/feroxbuster/main/install-nix.sh | bash -s "$HOME/.local/bin"
else
    echo "feroxbuster is already installed. Skipping."
fi

# Clone or update DNSCewl repository
clone_or_update_repo "https://github.com/codingo/DNSCewl.git" "DNSCewl"

# Clone or update OneListForAll repository
clone_or_update_repo "https://github.com/six2dez/OneListForAll.git" "OneListForAll"

# Clone or update xnLinkFinder repository and install
clone_or_update_repo "https://github.com/xnl-h4ck3r/xnLinkFinder.git" "xnLinkFinder"
cd xnLinkFinder
sudo python3 setup.py install
cd ..

echo "Done!"
echo "Remember to authenticate with Project Discovery to use DP tools! (https://cloud.projectdiscovery.io/)"