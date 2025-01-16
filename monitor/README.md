# LOG Monitor
<details>
<summary>python install</summary>
  
```bash
apt update && apt upgrade -y
add-apt-repository -y ppa:deadsnakes/ppa
apt install python3.11 software-properties-common -y 
```
```bash
apt install  
```
```bash
apt install python3-pip  
pip install openpyxl
```
```bash
mkdir -p $HOME/log_mon
curl -o $HOME/log_mon/log_monitor.py https://raw.githubusercontent.com/Hohlas/solana/main/monitor/log_monitor.py
```
</details>

```bash
python3 /root/log_monitor.py
```
```bash
# cut log from time1 to time2 
awk '/T06:00:00/,/T12:00:00/' ~/solana/solana.log > ~/solana_extracted.log
```
curl -o $REPO_DIR/core/src/consensus.rs https://raw.githubusercontent.com/Hohlas/solana/main/Jito/files/v2.0/consensus.rs
