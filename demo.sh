#!/bin/bash

# Путь к временному файлу для сохранения вывода
temp_log=$(mktemp)
temp_err=$(mktemp)

# Переменные для обработки параметров
log_flag=false
err_flag=false
log_file=""
err_file=""

# Функция для вывода справки
show_help() {
    local help_text="Usage: $0 [-u] [-p] [-h] [-l PATH] [-log PATH] [-e PATH] [--errors PATH]
  -u, --users        Output list of users and their home directories sorted alphabetically
  -p, --processes    Output list of running processes sorted by their identifiers (PIDs)
  -h, --help         Show help message
  -l PATH, --log PATH    Redirect output to a log file at the specified path
  -log PATH    Redirect output to a log file at the specified path
  -e PATH, --errors PATH    Redirect stderr output to a file at the specified path
  --errors PATH    Redirect stderr output to a file at the specified path
  "

    # Сохраняем справку в временный файл
    echo "$help_text" >> "$temp_log"
}

# Функция вывода ошибки и остановки программы
err_foo() {
	if [ "$err_flag" = true ] && [ -n "$err_file" ]; then
	    cat "$temp_err" > "$err_file"
	else
	    cat "$temp_err"
	fi
	
	# Очистка памяти
	rm "$temp_log"
	rm "$temp_err"
	
	exit 1
}

# Обработка длинных флагов
for ((i=1; i<=$#; i++)); do
    case "${!i}" in
        --users) set -- "${@:1:i-1}" "-u" "${@:i+1}" ;;
        --processes) set -- "${@:1:i-1}" "-p" "${@:i+1}" ;;
        --help) set -- "${@:1:i-1}" "-h" "${@:i+1}" ;;
        -log) set -- "${@:1:i-1}" "-l" "${@:i+1}" ;;
	-errors) set -- "${@:1:i-1}" "-e" "${@:i+1}" ;;
    esac
done

# Обработка аргументов командной строки с помощью getopts
while getopts ":uphl:e:" opt; do
    case ${opt} in
        u)
            awk -F: '{print $1, $6}' /etc/passwd | sort >> "$temp_log"
            ;;
        p)
            ps -e --sort=pid >> "$temp_log"
            ;;
        h)
            show_help
            ;;
        l)
            log_flag=true
            log_file="$OPTARG"
            ;;
        e)
            err_flag=true
            err_file="$OPTARG"
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >> "$temp_err"
            err_flag=true
            err_foo
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >> "$temp_err"
            err_flag=true
            err_foo
            ;;
    esac
done

# Перенаправляем стандартный вывод в файл, если указан флаг -l или -log
if [ "$log_flag" = true ]; then
    cat "$temp_log" > "$log_file"
else
    cat "$temp_log"
fi

# Удаляем временные файлы
rm "$temp_log"
rm "$temp_err"

