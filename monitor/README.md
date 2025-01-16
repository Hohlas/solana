# LOG Monitor
<details>
<summary>python install</summary>
  
```bash
apt update && apt upgrade && apt install software-properties-common -y
add-apt-repository -y ppa:deadsnakes/ppa
apt install python3.11 python3-pip -y 
```
```bash
pip install openpyxl
```
```bash
mkdir -p $HOME/log_monitor
curl -o $HOME/log_monitor/log_monitor.py https://raw.githubusercontent.com/Hohlas/solana/main/monitor/log_monitor.py
curl -o $HOME/log_monitor/metrics.txt https://raw.githubusercontent.com/Hohlas/solana/main/monitor/metrics.txt
cd $HOME/log_monitor
```

![2025-01-16_15-58-32](https://github.com/user-attachments/assets/42677938-2786-4b3c-99e3-4f02caf62443)
metrics.txt - список необходимых метрик
solana.log - лог файла для анализа
result.xlsx - полученный файл с таблицами для построения графиков

</details>


```bash
# cut log from time1 to time2 
awk '/T06:00:00/,/T12:00:00/' ~/solana/solana.log > ~/log_monitor/solana.log
```
```bash
python3 $HOME/log_monitor/log_monitor.py
```
<details>
<summary>metrics help</summary>
  
num_errors_cross_beam_recv_timeout - количество таймаутов при получении данных через сеть

replay_total_elapsed - Общее количество других ошибок, которые могут возникать при обработке данных

num_errors_blockstore - Ошибки, связанные с блокстором, могут указывать на проблемы с доступом к данным, что также может быть связано с качеством соединения.

num_packets_received / num_packets_sent - количество пакетов, полученных/отправленных сервером. Низкие значения могут указывать на проблемы с сетевым соединением.

process_gossip_packets_time - Время обработки пакетов "госипа" (gossip) — это время, необходимое для обработки сообщений о состоянии сети. Высокие значения могут указывать на задержки в сети

gossip_transmit_loop_time - Время, затраченное на передачу сообщений "госипа".

fetch_stage_packets_forwarded - Количество пакетов, переданных на стадии извлечения.

total_elapsed_us - Общее время выполнения операций в микросекундах. Если это время значительно увеличивается, это может быть признаком проблем с сетью или производительностью.


</details>

![2025-01-16_10-33-20](https://github.com/user-attachments/assets/de8d498a-7b49-4bf0-8290-75c3e8ee3b9c)

