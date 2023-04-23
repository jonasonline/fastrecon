mkdir scope
mkdir scans
mkdir lists
wget -O lists/pry-dns.txt https://i.pry0.cc/lists/pry-dns.txt
wget -O lists/resolvers.txt https://i.pry0.cc/lists/resolvers.txt

go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest
go install -v github.com/tomnomnom/anew@latest

sudo apt-get --assume-yes install git make gcc
git clone https://github.com/robertdavidgraham/masscan
cd masscan
make
make install