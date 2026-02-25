#!/bin/bash

# Переключение kubeconfig через Vault (secret/kube/<name>)
# Использование:
#   vswitch.sh              — список конфигов из Vault
#   vswitch.sh <номер>      — переключиться по номеру
#   vswitch.sh <имя>        — переключиться по частичному имени
#   vswitch.sh <номер/имя> <новое_имя> — переименовать конфиг в Vault
#   vswitch.sh init         — загрузить локальные конфиги в Vault

active="${HOME}/.kube/config"

# Проверка vault CLI и переменных
check_vault() {
    if ! command -v vault &>/dev/null; then
        echo "vault CLI не найден"
        exit 1
    fi
    if [[ -z "$VAULT_ADDR" ]]; then
        echo "VAULT_ADDR не установлен"
        exit 1
    fi
}

# Получить список имён из vault
get_names() {
    vault kv list -format=json secret/kube 2>/dev/null | python -c "import sys,json;[print(x) for x in json.load(sys.stdin)]" 2>/dev/null
}

# Список конфигов из Vault
list_configs() {
    local current_ctx=""
    [[ -f "$active" ]] && current_ctx=$(kubectl config current-context 2>/dev/null)

    local names
    names=$(get_names)
    if [[ -z "$names" ]]; then
        echo "Нет конфигов в Vault (secret/kube/)"
        return 0
    fi

    echo "Конфиги в Vault:"
    echo ""

    local i=0
    while IFS= read -r name; do
        ((i++))
        if [[ "$name" == "$current_ctx" ]]; then
            echo "  $i) $name  *"
        else
            echo "  $i) $name"
        fi
    done <<< "$names"

    if [[ -n "$current_ctx" ]]; then
        echo ""
        echo "Активный: $current_ctx"
    fi
    return 0
}

# Найти конфиг по номеру или частичному имени
# Устанавливает переменные: _match, _matches
find_config() {
    local target="$1"
    local names="$2"
    _match=""
    _matches=0

    # Сначала пробуем как номер
    if [[ "$target" =~ ^[0-9]+$ ]]; then
        local i=0
        while IFS= read -r name; do
            ((i++))
            if [[ $i -eq $target ]]; then
                _match="$name"
                _matches=1
                break
            fi
        done <<< "$names"
    fi

    # Если не нашли по номеру — ищем по имени (частичное совпадение)
    if [[ $_matches -eq 0 ]]; then
        while IFS= read -r name; do
            if [[ "$name" == *"$target"* ]]; then
                _match="$name"
                ((_matches++))
            fi
        done <<< "$names"
    fi

    if [[ $_matches -eq 0 ]]; then
        echo "Не найден конфиг: $target"
        echo ""
        list_configs
        return 1
    elif [[ $_matches -gt 1 ]]; then
        echo "Неоднозначно, найдено $_matches совпадений для '$target':"
        while IFS= read -r name; do
            [[ "$name" == *"$target"* ]] && echo "  - $name"
        done <<< "$names"
        return 1
    fi
    return 0
}

# Переключиться на конфиг по имени или номеру
switch_to() {
    local target="$1"
    local names
    names=$(get_names)

    if [[ -z "$names" ]]; then
        echo "Нет конфигов в Vault (secret/kube/)"
        return 1
    fi

    find_config "$target" "$names" || return 1

    # Проверяем, не активен ли уже этот конфиг
    if [[ -f "$active" ]]; then
        local current_ctx
        current_ctx=$(kubectl config current-context 2>/dev/null)
        if [[ "$current_ctx" == "$_match" ]]; then
            echo "Уже активен: $_match"
            return 0
        fi
    fi

    # Скачиваем из Vault и записываем
    mkdir -p "${HOME}/.kube"
    vault kv get -field=kubeconfig "secret/kube/$_match" > "$active" 2>/dev/null
    if [[ $? -ne 0 ]]; then
        echo "Ошибка чтения secret/kube/$_match"
        return 1
    fi

    echo "$_match"
}

# Переименовать конфиг в Vault
rename_config() {
    local target="$1"
    local new_name="$2"
    local names
    names=$(get_names)

    if [[ -z "$names" ]]; then
        echo "Нет конфигов в Vault (secret/kube/)"
        return 1
    fi

    find_config "$target" "$names" || return 1

    local old_name="$_match"

    if [[ "$old_name" == "$new_name" ]]; then
        echo "Имя не изменилось: $old_name"
        return 0
    fi

    # Проверяем, не занято ли новое имя
    if echo "$names" | grep -qx "$new_name"; then
        echo "Имя '$new_name' уже существует в Vault"
        return 1
    fi

    # Копируем данные в новый ключ
    local data
    data=$(vault kv get -field=kubeconfig "secret/kube/$old_name" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo "Ошибка чтения secret/kube/$old_name"
        return 1
    fi

    echo "$data" | vault kv put "secret/kube/$new_name" kubeconfig=- >/dev/null
    if [[ $? -ne 0 ]]; then
        echo "Ошибка записи secret/kube/$new_name"
        return 1
    fi

    # Удаляем старый ключ
    vault kv delete "secret/kube/$old_name" >/dev/null 2>&1

    echo "$old_name -> $new_name"
}

# Загрузить локальные конфиги в Vault
init_configs() {
    local uploaded=0
    local skipped=0

    local existing
    existing=$(get_names)

    # Загрузить все config.* файлы
    for f in "${HOME}/.kube"/config.*; do
        [[ -f "$f" ]] || continue
        local ctx
        ctx=$(kubectl --kubeconfig="$f" config current-context 2>/dev/null)
        [[ -z "$ctx" ]] && continue

        if echo "$existing" | grep -qx "$ctx"; then
            ((skipped++))
        else
            vault kv put "secret/kube/$ctx" kubeconfig=@"$f" >/dev/null
            if [[ $? -eq 0 ]]; then
                echo "  + $ctx"
                ((uploaded++))
            else
                echo "  ! ошибка: $ctx"
            fi
        fi
    done

    # Загрузить активный config
    if [[ -f "$active" ]]; then
        local ctx
        ctx=$(kubectl --kubeconfig="$active" config current-context 2>/dev/null)
        if [[ -n "$ctx" ]]; then
            if echo "$existing" | grep -qx "$ctx"; then
                ((skipped++))
            else
                vault kv put "secret/kube/$ctx" kubeconfig=@"$active" >/dev/null
                if [[ $? -eq 0 ]]; then
                    echo "  + $ctx (active)"
                    ((uploaded++))
                else
                    echo "  ! ошибка: $ctx"
                fi
            fi
        fi
    fi

    echo ""
    echo "Загружено: $uploaded, пропущено: $skipped"
}

# --- main ---
check_vault

if [[ $# -eq 0 ]]; then
    list_configs
elif [[ "$1" == "init" ]]; then
    init_configs
elif [[ $# -eq 2 && "$1" != "init" ]]; then
    rename_config "$1" "$2"
else
    switch_to "$1"
fi
