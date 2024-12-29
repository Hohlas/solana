import re
import csv
import os

def extract_metric(log_file_path, output_csv_path, metric):
    with open(log_file_path, 'r') as log_file:
        # Список для хранения данных
        data = []

        for line in log_file:
            # Ищем строки, содержащие заданную метрику
            if metric in line:
                # Извлекаем временную метку (с учетом квадратных скобок)
                timestamp_match = re.match(r'\[(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z)', line)
                # Извлекаем значение заданной метрики
                metric_match = re.search(rf'{metric}=(\d+)', line)

                if timestamp_match and metric_match:
                    data.append([
                        timestamp_match.group(1),  # Время
                        metric_match.group(1)  # Значение заданной метрики
                    ])

    # Отладочный вывод содержимого data
    # print(f"Собранные данные для метрики '{metric}':")
    # for entry in data:
    #    print(entry)

    # Записываем данные в CSV файл
    with open(output_csv_path, 'w', newline='') as csv_file:
        csv_writer = csv.writer(csv_file, delimiter=';')
        csv_writer.writerow(['time', metric])  # Заголовки столбцов
        csv_writer.writerows(data)  # Запись данных

def main():
    base_path = r'C:\Users\hohla\solana'  # Замените на нужный путь для Windows
    # base_path = '/home/username/solana'  # Используйте этот путь для Ubuntu

    log_file_path = os.path.join(base_path, 'solana.log')  # Путь к лог-файлу
    metrics_file_path = os.path.join(base_path, 'metrics.txt')  # Путь к файлу с метриками

    # Чтение списка метрик из файла
    with open(metrics_file_path, 'r') as metrics_file:
        metrics = [line.strip() for line in metrics_file if line.strip()]

    # Для каждой метрики вызываем функцию извлечения
    for metric in metrics:
        output_csv_path = os.path.join(base_path, f'{metric}.csv')  # Путь к выходному файлу для каждой метрики
        extract_metric(log_file_path, output_csv_path, metric)

# Запуск основной функции
if __name__ == "__main__":
    main()
