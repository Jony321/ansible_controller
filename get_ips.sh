#!/bin/bash

REPORT_FILE="/tmp/ip_inventory_report.txt"

# Удаляем старый отчет перед запуском
rm -f "$REPORT_FILE"

echo "Запуск Ansible Playbook (выполнение задач)..."
echo "--------------------------------------------------------------------------------"

# Добавляем || true, чтобы ненулевой код возврата ansible (при недоступности отдельных ВМ) не прерывал скрипт
ANSIBLE_TIMEOUT=30 ansible-playbook ./run-generate_ip_report.yml "$@" || true

echo "--------------------------------------------------------------------------------"
echo ""

# Гарантированно выводим файл отчета
if [ -f "$REPORT_FILE" ]; then
    cat "$REPORT_FILE"
else
    echo "Ошибка: Файл отчета $REPORT_FILE не был сгенерирован."
    exit 1
fi
