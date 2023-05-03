mkdir scope
mkdir scans
mkdir lists
wget -O lists/pry-dns.txt https://i.pry0.cc/lists/pry-dns.txt
wget -O lists/resolvers.txt https://i.pry0.cc/lists/resolvers.txt
wget -O lists/content_discovery_nullenc0de.txt https://gist.githubusercontent.com/nullenc0de/96fb9e934fc16415fbda2f83f08b28e7/raw/146f367110973250785ced348455dc5173842ee4/content_discovery_nullenc0de.txt


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

GO111MODULE=on go install github.com/jaeles-project/gospider@latest

git clone https://github.com/robertdavidgraham/masscan
cd masscan
make
make install
cd ..

git clone https://github.com/blechschmidt/massdns.git
cd massdns
make
make install
cd ..