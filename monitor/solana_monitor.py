import re
import csv
import os

log_file_path = os.path.join(os.environ['HOME'], 'solana', 'solana1.log')
output_csv_path = os.path.join(os.environ['HOME'], 'solana.csv')

def parse_log_file(log_file_path, output_csv_path):
    # Открываем файл для чтения
    with open(log_file_path, 'r') as log_file:
        # Создаем список для хранения данных
        data = []
        
        # Читаем файл построчно
        for line in log_file:
            # Ищем временную метку
            timestamp_match = re.match(r'(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z)', line)
            if timestamp_match:
                timestamp = timestamp_match.group(1)
                
                # Ищем нужные метрики
                num_errors_match = re.search(r'num_errors_cross_beam_recv_timeout=(\d+)', line)
                replay_total_elapsed_match = re.search(r'replay_total_elapsed=(\d+)', line)
                average_load_match = re.search(r'average_load_one_minute=([\d.]+)', line)

                # Если все метрики найдены, добавляем их в данные
                if num_errors_match and replay_total_elapsed_match and average_load_match:
                    data.append([
                        timestamp,
                        num_errors_match.group(1),
                        replay_total_elapsed_match.group(1),
                        average_load_match.group(1)
                    ])

    # Записываем данные в CSV файл
    with open(output_csv_path, 'w', newline='') as csv_file:
        csv_writer = csv.writer(csv_file, delimiter=';')
        # Записываем заголовок
        csv_writer.writerow(['time', 'num_errors_cross_beam_recv_timeout', 'replay_total_elapsed', 'average_load_one_minute'])
        # Записываем данные
        csv_writer.writerows(data)

# Укажите путь к файлу solana.log и выходному файлу monitor.csv
log_file_path = '/path/to/solana.log'  # Замените на ваш путь к файлу
output_csv_path = 'monitor.csv'

# Запуск функции парсинга
parse_log_file(log_file_path, output_csv_path)
