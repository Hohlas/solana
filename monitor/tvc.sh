#!/bin/bash

# Файл с валидаторами
VALIDATORS_FILE=~/validators.txt
# Файл для записи результатов
OUTPUT_FILE=~/TVC.csv

# Проверка на существование файла
if [ ! -f "$OUTPUT_FILE" ]; then
    # Создаем заголовок CSV файла с использованием точки с запятой как разделителя
    {
        echo -n "Time;"
        
        # Читаем файл с валидаторами и формируем заголовок
        while IFS= read -r IDENTITY; do
            # Удаляем символы \r, если они есть
            IDENTITY=$(echo "$IDENTITY" | tr -d '\r')
            echo -n "$IDENTITY;"
        done < "$VALIDATORS_FILE"
        
        echo ""  # Завершаем строку заголовка
        
    } > "$OUTPUT_FILE"  # Записываем заголовок в файл
fi

while true; do
    # Получаем текущее время
    CURRENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")

    # Запускаем команду один раз с флагом --sort=credits и сохраняем результат в переменной в формате текстового вывода
    VALIDATORS_OUTPUT=$(solana validators --sort=credits -r -n)

    # Инициализируем массив для хранения TVC значений
    TVC_VALUES=()

    # Читаем файл с валидаторами построчно
    while IFS= read -r IDENTITY; do
        # Удаляем символы \r, если они есть
        IDENTITY=$(echo "$IDENTITY" | tr -d '\r')
        
        # Получаем TVC для текущего валидатора из текстового вывода
        TVC=$(echo "$VALIDATORS_OUTPUT" | grep "$IDENTITY" | awk '{print $1}')  # Измените на нужное поле, если требуется

        if [ -z "$TVC" ]; then
            echo "Warning: TVC not found for validator $IDENTITY"  # Логирование отсутствующего TVC
            TVC_VALUES+=("")  # Добавляем пустую строку для отсутствующего значения
        else
            TVC_VALUES+=("$TVC")  # Добавляем значение TVC в массив
        fi
    done < "$VALIDATORS_FILE"

    # Преобразуем массив TVC_VALUES в строку, разделенную точкой с запятой
    TVC_STRING=$(IFS=';'; echo "${TVC_VALUES[*]}")

    # Записываем текущее время и TVC значения в файл с использованием точки с запятой
    echo "$CURRENT_TIME;$TVC_STRING" >> "$OUTPUT_FILE"

    # Ждем 1 минуту перед следующей итерацией
    sleep 60
done
