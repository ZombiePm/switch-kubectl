#!/bin/bash

# Переключение kubeconfig по имени контекста
# Использование:
#   switch.sh          — список доступных конфигов
#   switch.sh <имя>    — переключиться на конфиг (частичное совпадение)

config_dir="${HOME}/.kube"
active="$config_dir/config"

# Получить context name из kubeconfig файла
get_ctx() {
    kubectl --kubeconfig="$1" config current-context 2>/dev/null || echo "unknown"
}

# Список всех доступных конфигов
list_configs() {
    local current_ctx=""
    [[ -f "$active" ]] && current_ctx=$(get_ctx "$active")

    echo "Доступные kubeconfig:"
    echo ""

    local i=0
    for f in "$config_dir"/config.*; do
        [[ -f "$f" ]] || continue
        local ctx
        ctx=$(get_ctx "$f")
        ((i++))
        echo "  $i) $ctx"
    done

    if [[ -n "$current_ctx" ]]; then
        echo ""
        echo "Активный: $current_ctx"
    fi

    [[ $i -eq 0 ]] && echo "  (нет сохранённых конфигов)"
    return 0
}

# Переключиться на конфиг по имени или номеру
switch_to() {
    local target="$1"
    local match=""
    local match_ctx=""
    local matches=0

    # Сначала пробуем как номер
    if [[ "$target" =~ ^[0-9]+$ ]]; then
        local i=0
        for f in "$config_dir"/config.*; do
            [[ -f "$f" ]] || continue
            ((i++))
            if [[ $i -eq $target ]]; then
                match="$f"
                match_ctx=$(get_ctx "$f")
                matches=1
                break
            fi
        done
    fi

    # Если не нашли по номеру — ищем по имени (частичное совпадение)
    if [[ $matches -eq 0 ]]; then
        for f in "$config_dir"/config.*; do
            [[ -f "$f" ]] || continue
            local ctx
            ctx=$(get_ctx "$f")
            if [[ "$ctx" == *"$target"* ]]; then
                match="$f"
                match_ctx="$ctx"
                ((matches++))
            fi
        done
    fi

    if [[ $matches -eq 0 ]]; then
        echo "Не найден конфиг: $target"
        echo ""
        list_configs
        return 1
    elif [[ $matches -gt 1 ]]; then
        echo "Неоднозначно, найдено $matches совпадений для '$target':"
        for f in "$config_dir"/config.*; do
            [[ -f "$f" ]] || continue
            local ctx
            ctx=$(get_ctx "$f")
            [[ "$ctx" == *"$target"* ]] && echo "  - $ctx"
        done
        return 1
    fi

    # Проверяем, не активен ли уже этот конфиг
    if [[ -f "$active" ]]; then
        local current_ctx
        current_ctx=$(get_ctx "$active")
        if [[ "$current_ctx" == "$match_ctx" ]]; then
            echo "Уже активен: $match_ctx"
            return 0
        fi
        # Сохраняем текущий по имени контекста
        mv "$active" "$config_dir/config.$current_ctx"
    fi

    # Активируем выбранный
    mv "$match" "$active"
    echo "$match_ctx"
}

# --- main ---
if [[ $# -eq 0 ]]; then
    list_configs
else
    switch_to "$1"
fi
