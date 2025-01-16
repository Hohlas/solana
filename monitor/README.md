# LOG Monitor
<details>
<summary>rust setup</summary>
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
</details>

```bash
python3 /root/solana_monitor.py
```
```bash
# cut log from time1 to time2 
awk '/T06:00:00/,/T12:00:00/' ~/solana/solana.log > ~/solana_extracted.log
```
