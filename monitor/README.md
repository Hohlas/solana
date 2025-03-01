## LOG Monitor
Визуализатор метрик лог файла соланы.   
Формирует таблицы значений из лог файла по заданным метрикам для построения графиков.

<details>
<summary>установка</summary>
  
```bash
apt update && apt upgrade && apt install software-properties-common -y
add-apt-repository -y ppa:deadsnakes/ppa
apt install python3.11 python3-pip -y 
```
```bash
mkdir -p $HOME/log_monitor
cd $HOME/log_monitor
curl -o $HOME/log_monitor/log_monitor.py https://raw.githubusercontent.com/Hohlas/solana/main/monitor/log_monitor.py
curl -o $HOME/log_monitor/metrics.txt https://raw.githubusercontent.com/Hohlas/solana/main/monitor/metrics.txt
python3 -m venv myenv # Создать виртуальное окружение
source myenv/bin/activate # Активировать виртуальное окружение
pip install openpyxl

```

![2025-01-16_22-02-21](https://github.com/user-attachments/assets/42648db5-7e15-4220-9284-d02b3ffb62f7)

metrics.txt - Список необходимых метрик. Отредактировать по необходимости.  
metrics.xlsx - Полученный файл с таблицами для построения графиков.

</details>


```bash
# копирование заданного временного отрезка лог файла
awk '/T01:00:00/,/T12:00:00/' ~/solana/solana.log > ~/log_monitor/solana.log
```
```bash
# Запуск log_monitor.py для создания файла с таблицами metrics.xlsx
cd $HOME/log_monitor
source myenv/bin/activate # Активировать виртуальное окружение
python3 $HOME/log_monitor/log_monitor.py
```
<details>
<summary>описание метрик</summary>

replay_to_vote_time - время между обработкой слота и голосованием за него. Ее нет в логах, вычисляется как разность времен метрик 'replay-slot-stats' - 'tower-vote latest'. Показывает, насколько быстро нода может голосовать после получения и обработки слота.

fork_to_replay_time - тоже нет в логах. Время в миллисекундах между обнаружением слота (new fork) и завершением его обработки (replay-slot-stats). Увеличение может указывать на проблемы с производительностью ноды.
  
num_errors_cross_beam_recv_timeout - количество таймаутов при получении данных через сеть. Ненулевые значения указывают на проблемы с получением данных из сети (сервер часто теряет соединение).

num_errors_other - Общее количество других ошибок, которые могут возникать при обработке данных. Это может включать сетевые ошибки.

replay_total_elapsed - общее время обработки транзакций. Увеличение может указывать на проблемы с производительностью.

num_errors_blockstore - Ошибки, связанные с блокстором, могут указывать на проблемы с доступом к данным, что также может быть связано с качеством соединения.

num_packets_received / num_packets_sent - количество пакетов, полученных/отправленных сервером. Низкие значения могут указывать на проблемы с сетевым соединением.

process_gossip_packets_time - Время обработки пакетов "госипа" (gossip) — это время, необходимое для обработки сообщений о состоянии сети. Высокие значения могут указывать на задержки в сети

gossip_transmit_loop_time - Время, затраченное на передачу сообщений "госипа". Высокие значения говорят о проблемах с интернет-соединением.

fetch_stage_packets_forwarded - Количество пакетов, переданных на стадии извлечения. Высокое значение может указывать на эффективную работу узла, который активно получает и передает данные. Низкие значения могут сигнализировать о проблемах с сетью или перегрузкой узла.

total_elapsed_us - Общее время выполнения операций в микросекундах. Если это время значительно увеличивается, это может быть признаком проблем с сетью или производительностью.

average_load_one_minute - загрузка CPU за разные промежутки времени

disk-stats - Статистика операций ввода-вывода на диске, которая может указывать на производительность хранения данных.


</details>
В терминале появится вывод статистики выбросов по слотам  

![image](https://github.com/user-attachments/assets/c1735afd-bc05-438a-bc36-4450804c5692)

Открыть в екселе metrics.xlsx
![image](https://github.com/user-attachments/assets/4e553fb8-e21e-435a-8e5d-4026574f60aa)



## TVC scanner

```bash
mkdir -p $HOME/tvc_scan
cd $HOME/tvc_scan
curl -o $HOME/tvc_scan/tvc.sh https://raw.githubusercontent.com/Hohlas/solana/main/monitor/tvc.sh
curl -o $HOME/tvc_scan/validators.txt https://raw.githubusercontent.com/Hohlas/solana/main/monitor/validators.txt
chmod +x $HOME/tvc_scan/tvc.sh
./tvc.sh
```
