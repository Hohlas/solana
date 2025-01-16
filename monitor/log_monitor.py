import re
import os
import openpyxl

def extract_metric(log_file_path, metric):
    data = []

    with open(log_file_path, 'r') as log_file:
        for line in log_file:
            # Ищем строки, содержащие заданную метрику
            if metric in line:
                # Извлекаем временную метку (с учетом квадратных скобок)
                timestamp_match = re.match(r'\[(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z)', line)
                # Извлекаем значение заданной метрики
                metric_match = re.search(rf'{metric}=(\d+(\.\d+)?)', line)  # Поддержка дробных чисел

                if timestamp_match and metric_match:
                    data.append([
                        timestamp_match.group(1),  # Время
                        float(metric_match.group(1))  # Значение заданной метрики как число
                    ])
    
    return data

def main():
    # base_path = r'C:\Users\hohla\solana'  # Замените на нужный путь для Windows
    base_path = '/root/log_monitor'  # Используйте этот путь для Ubuntu

    log_file_path = os.path.join(base_path, 'solana.log')  # Путь к лог-файлу
    metrics_file_path = os.path.join(base_path, 'metrics.txt')  # Путь к файлу с метриками
    output_excel_path = os.path.join(base_path, 'result.xlsx')  # Путь к выходному Excel файлу

    # Чтение списка метрик из файла
    with open(metrics_file_path, 'r') as metrics_file:
        metrics = [line.strip() for line in metrics_file if line.strip()]

    # Создаем новый Excel файл
    workbook = openpyxl.Workbook()

    for metric in metrics:
        data = extract_metric(log_file_path, metric)

        # Создаем новую вкладку для каждой метрики
        sheet = workbook.create_sheet(title=metric)
        sheet.append(['time', metric])  # Заголовки столбцов
        
        for entry in data:
            sheet.append(entry)  # Запись данных

    # Установка формата для второго столбца (числа) начиная со второй строки
    for sheet in workbook.sheetnames:
        ws = workbook[sheet]
        for row in range(2, ws.max_row + 1):  # Начинаем со второй строки
            ws.cell(row=row, column=2).number_format = '0.00'  # Форматируем как число с двумя знаками после запятой

    # Удаление стандартного листа, если он пустой
    if 'Sheet' in workbook.sheetnames:
        std_sheet = workbook['Sheet']
        if std_sheet.max_row == 1:  # Если только заголовок
            workbook.remove(std_sheet)

    # Сохраняем Excel файл
    workbook.save(output_excel_path)
    print(f"Данные сохранены в {output_excel_path}")

# Запуск основной функции
if __name__ == "__main__":
    main()
