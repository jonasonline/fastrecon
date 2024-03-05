mkdir scope
mkdir scans
mkdir lists
#no longer online# wget -O lists/pry-dns.txt https://i.pry0.cc/lists/pry-dns.txt
#no longer online# wget -O lists/resolvers.txt https://i.pry0.cc/lists/resolvers.txt
wget -O lists/resolvers.txt https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt
wget -O lists/jhaddix_all.txt https://gist.githubusercontent.com/jhaddix/f64c97d0863a78454e44c2f7119c2a6a/raw/96f4e51d96b2203f19f6381c8c545b278eaa0837/all.txt
wget -O lists/content_discovery_nullenc0de.txt https://gist.githubusercontent.com/nullenc0de/96fb9e934fc16415fbda2f83f08b28e7/raw/146f367110973250785ced348455dc5173842ee4/content_discovery_nullenc0de.txt

sudo apt install -y libpcap-dev

go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest
go install -v github.com/tomnomnom/anew@latest
go install -v github.com/d3mondev/puredns/v2@latest
go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go install -v github.com/pry0cc/tew@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/katana/cmd/katana@latest
go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install -v github.com/owasp-amass/amass/v3/...@master
go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
go install github.com/tomnomnom/unfurl@latest
go install github.com/ffuf/ffuf/v2@latest
go install github.com/tomnomnom/gf@latest

sudo apt-get install -y libgbm1 libxrandr2 libcairo2 libatk1.0-0 libatk-bridge2.0-0 libxcomposite1 libxdamage1 libxfixes3 libcups2 libdrm2 libpango-1.0-0 libpangocairo-1.0-0 libxkbcommon0 libx11-xcb1

git clone https://github.com/tomnomnom/gf.git
cp -r gf/examples ~/.gf

GO111MODULE=on go install github.com/jaeles-project/gospider@latest

git clone https://github.com/codingo/DNSCewl.git
git clone https://github.com/six2dez/OneListForAll.git 

git clone https://github.com/xnl-h4ck3r/xnLinkFinder.git
cd xnLinkFinder
sudo python3 setup.py install
cd ..