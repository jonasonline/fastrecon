# fastrecon - a simple script for semi automated recon 

### Prerequisites
- GO (latest version)
- make
- gcc
- jq
- nmap
- bat

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
