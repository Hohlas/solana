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
mkdir -p $HOME/log_monitor
curl -o $HOME/log_monitor/log_monitor.py https://raw.githubusercontent.com/Hohlas/solana/main/monitor/log_monitor.py
curl -o $HOME/log_monitor/metrics.txt https://raw.githubusercontent.com/Hohlas/solana/main/monitor/metrics.txt
cd $HOME/log_monitor
```
</details>


```bash
# cut log from time1 to time2 
awk '/T06:00:00/,/T12:00:00/' ~/solana/solana.log > $HOME/log_monitor/solana.log
```
```bash
python3 $HOME/log_monitor/log_monitor.py
```

