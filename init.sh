mkdir scope
mkdir scans
mkdir lists
wget -O lists/pry-dns.txt https://i.pry0.cc/lists/pry-dns.txt
wget -O lists/resolvers.txt https://i.pry0.cc/lists/resolvers.txt

go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest
go install -v github.com/tomnomnom/anew@latest
go install -v github.com/d3mondev/puredns/v2@latest
go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest

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