import re
import csv

def extract_replay_total_elapsed(log_file_path, output_csv_path):
    with open(log_file_path, 'r') as log_file:
        # Список для хранения данных
        data = []

        for line in log_file:
            # Ищем строки, содержащие "replay_total_elapsed"
            if "replay_total_elapsed" in line:
                # Извлекаем временную метку (с учетом квадратных скобок)
                timestamp_match = re.match(r'\[(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z)', line)
                # Извлекаем значение replay_total_elapsed
                replay_total_elapsed_match = re.search(r'replay_total_elapsed=(\d+)', line)

                if timestamp_match and replay_total_elapsed_match:
                    data.append([
                        timestamp_match.group(1),  # Время
                        replay_total_elapsed_match.group(1)  # Значение replay_total_elapsed
                    ])

    # Отладочный вывод содержимого data
    print("Собранные данные:")
    for entry in data:
        print(entry)

    # Записываем данные в CSV файл
    with open(output_csv_path, 'w', newline='') as csv_file:
        csv_writer = csv.writer(csv_file, delimiter=';')
        csv_writer.writerow(['time', 'replay_total_elapsed'])  # Заголовки столбцов
        csv_writer.writerows(data)  # Запись данных

# Укажите пути к файлам
log_file_path = r'C:\Users\hohla\solana\solana1.log'  # Замените на ваш путь к файлу
output_csv_path = r'C:\Users\hohla\solana\solana.csv'  # Замените на ваш путь к выходному файлу

# Запуск функции извлечения
extract_replay_total_elapsed(log_file_path, output_csv_path)
