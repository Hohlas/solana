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
# копирование заданного временного отрезка лог файла
awk '/T06:00:00/,/T12:00:00/' ~/solana/solana.log > ~/log_monitor/solana.log
```
```bash
python3 $HOME/log_monitor/log_monitor.py
```
<details>
<summary>some metrics help</summary>
  
num_errors_cross_beam_recv_timeout - количество таймаутов при получении данных через сеть. Ненулевые значения указывают на проблемы с получением данных из сети (сервер часто теряет соединение).

num_errors_other - Общее количество других ошибок, которые могут возникать при обработке данных. Это может включать сетевые ошибки.

replay_total_elapsed - общее время обработки транзакций. Увеличение может указывать на проблемы с производительностью.

num_errors_blockstore - Ошибки, связанные с блокстором, могут указывать на проблемы с доступом к данным, что также может быть связано с качеством соединения.

num_packets_received / num_packets_sent - количество пакетов, полученных/отправленных сервером. Низкие значения могут указывать на проблемы с сетевым соединением.

process_gossip_packets_time - Время обработки пакетов "госипа" (gossip) — это время, необходимое для обработки сообщений о состоянии сети. Высокие значения могут указывать на задержки в сети

gossip_transmit_loop_time - Время, затраченное на передачу сообщений "госипа". Высокие значения говорят о проблемах с интернет-соединением.

fetch_stage_packets_forwarded - Количество пакетов, переданных на стадии извлечения. Низкие значения могут указывать на проблемы с получением данных.

total_elapsed_us - Общее время выполнения операций в микросекундах. Если это время значительно увеличивается, это может быть признаком проблем с сетью или производительностью.

average_load_one_minute - загрузка CPU за разные промежутки времени

disk-stats - Статистика операций ввода-вывода на диске, которая может указывать на производительность хранения данных.


</details>

![2025-01-16_10-33-20](https://github.com/user-attachments/assets/de8d498a-7b49-4bf0-8290-75c3e8ee3b9c)

