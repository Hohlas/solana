```bash
apt update && apt upgrade && apt install -y software-properties-common
```
```bash
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt install -y python3.11
```
```bash
python3 /root/solana_monitor.py
```
```bash
# cut log from time1 to time2 
awk '/T06:00:00/,/T12:00:00/' ~/solana/solana.log > ~/solana_extracted.log
```
