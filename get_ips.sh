#!/bin/bash

REPORT_FILE="/tmp/ip_inventory_report.txt"

rm -f "$REPORT_FILE"

echo "Запуск Ansible Playbook (выполнение задач)..."
echo "--------------------------------------------------------------------------------"

ANSIBLE_TIMEOUT=30 ansible-playbook playbooks/utils/run-generate_ip_report.yml "$@" || true

echo "--------------------------------------------------------------------------------"
echo ""

if [ -f "$REPORT_FILE" ]; then
    cat "$REPORT_FILE"
else
    echo "Ошибка: Файл отчета $REPORT_FILE не был сгенерирован."
    exit 1
fi
