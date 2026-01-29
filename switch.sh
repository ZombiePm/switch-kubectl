#!/bin/bash

# Папка с конфигами
config_dir="/root/.kube"

# Переход в директорию
cd "$config_dir" || exit 1

# Текущая временная метка UTC
timestamp=$(date -u +%s)

# Если есть файл config, переименовываем его
if [[ -f "config" ]]; then
    mv "config" "config.$timestamp"
    echo "Старый конфиг переименован в: config.$timestamp"
fi

# Находим самый старый файл config.<timestamp>
oldest_config=$(ls -1 config.* 2>/dev/null | sort | head -n 1)

# Если найден файл, делаем его активным
if [[ -n "$oldest_config" ]]; then
    mv "$oldest_config" "config"
    echo "Переключено на: config (из $oldest_config)"
else
    echo "Нет доступных конфигов для переключения!"
    exit 1
fi

# Выводим текущий контекст
kubectl config current-context
