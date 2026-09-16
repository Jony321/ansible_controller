# Ansible Controller

Каркас для деплоя ПО на удалённые машины через Ansible: плейбуки, переменные хостов, скрипты (`tools/`), Makefile-обёртки и REST-демон для оркестрации локальных запусков `ansible-playbook`.

Полная документация: [`docs/README.md`](docs/README.md). Для AI-агентов: [`AGENTS.md`](AGENTS.md).

## Требования

| Компонент | Назначение |
|-----------|------------|
| Ansible + ansible-galaxy | Запуск плейбуков и установка ролей |
| `uv` | Создаётся через `make prepare` |
| `fzf` | Интерактивный выбор хостов в `make` (`brew install fzf`) |
| GNU readlink | Для `set-vars.sh` на macOS (`brew install coreutils`) |

## Быстрый старт

#### IP inventory script
- playbooks/utils/run-generate_ip_report.yml - плейбук, который пройдется по хостам для сбора информации об ip адресах.
- ./get_ips.sh - скрипт обертка над run-generate_ip_report.yml, который выводит отчет в консоль после выполнения плейбука. Сам отчет сохраняется в /tmp/ip_inventory_report.txt.
- subnets.json - файл с описанием выделенных подсетей, зарезервированных и заблокированных адресов. Следует добавлять в этот файл новые заблокированные адреса и подсети, для учета их при составлении отчета об ip адресах.

**Использование**
- Инициализировать переменные - выполнить в терминале `. ./tools/set-vars.sh`.
- Выполнить `./get_ips.sh` из корня репозитория, в результате выполнится проверка адресов на всех хостах в группах tg_proxy_hosts_v2, hypervisors и сгенерируется отчет о занятых и доступных к использованию ip адресов.

Пример отчета
```
=== SUBNETS & FREE COUNT ===
217.199.221.0/27 - free: 0
185.126.92.0/27 - free: 3
185.126.93.0/24 - free: 1
62.76.115.192/27 - free: 0
185.16.213.32/27 - free: 0
78.24.92.0/24 - free: 167
185.218.180.0/27 - free: 15

=== BLOCKED ADDRESSES ===
185.126.93.15
185.126.93.17

=== ALL IP ADDRESSES ===
1st nic - hostname - 2nd nic - external ip
217.199.221.1 - reserved
217.199.221.2 - ru.ix.hyper01.wx.027 - N/A - 217.199.221.2
217.199.221.3 - ru.ix.hyper01.wx.028 - N/A - 217.199.221.3
217.199.221.4 - ru.ix.hyper01.wx.029 - N/A - 217.199.221.4
217.199.221.5 - ru.ix.hyper01.wx.030 - N/A - 217.199.221.5
217.199.221.6 - ru.ix.hyper01.wx.031 - N/A - 217.199.221.6
```

#### Base usage
```bash
make prepare
. ./tools/set-vars.sh
./tools/get-roles.sh traefik server-common

# inventory/hosts — вручную; host_vars — по образцу host_vars/.examples/
mkdir -p host_vars/myhost.example.com
cp host_vars/.examples/idp.domain.com/traefik.yml host_vars/myhost.example.com/

./playbooks/services/run-traefik.yml -l myhost.example.com
```

Подробнее: [`docs/guides/getting-started.md`](docs/guides/getting-started.md).

## Структура репозитория

| Каталог | Назначение |
|---------|------------|
| [`playbooks/`](playbooks/) | Плейбуки по категориям + `run-*-full.yml` в корне |
| [`host_vars/`](host_vars/) | Переменные конкретных хостов; примеры в `.examples/` |
| [`group_vars/`](group_vars/) | Групповые переменные Ansible |
| [`inventory/`](inventory/) | Инвентарь (`hosts` создаётся вручную) |
| [`vars/`](vars/) | Общие extra vars (`extra.yaml` для shebang-плейбуков) |
| [`tools/roles_lists/`](tools/roles_lists/) | Списки Galaxy-ролей для `get-roles.sh` |
| [`tools/`](tools/) | Скрипты, CI, mitogen-плейбук |
| [`daemon/`](daemon/) | REST API провижининга |
| [`docs/`](docs/) | Документация |
| `roles/` | Скачанные роли (gitignored) |
| `library/` | mitogen после `switch-to-mitogen.yml` (gitignored) |

Детали: [`docs/architecture/repository-layout.md`](docs/architecture/repository-layout.md).

## Установка ролей

Роли не хранятся в git. Скачивание по спискам в `tools/roles_lists/`:

```bash
./tools/get-roles.sh traefik docker    # конкретные роли
./tools/get-roles.sh                   # все списки (долго)
```

См. [`docs/reference/roles-lists.md`](docs/reference/roles-lists.md).

## Make

Makefile предоставляет удобный интерфейс для запуска Ansible playbook'ов. Для интерактивного выбора используется `fzf`.

```bash
make help
````

 ### Интерактивный запуск

 При запуске `make` без аргументов открывается интерактивный `fzf`, в котором можно выбрать playbook:

```
make
```

 После выбора playbook последовательно предлагается выбрать:

1. **Хосты** — только хосты, на которые выбранный playbook действительно может быть применён.
2. **Теги** — теги, доступные в выбранном playbook.

 В обоих списках поддерживается множественный выбор: используйте `Tab` для выбора нескольких элементов и `Enter` для подтверждения.

 `Esc` позволяет отказаться от выбора и использовать `all`.

 ### Запуск с параметрами

 Playbook можно запускать напрямую, задав хосты и/или теги через переменные окружения:

```
HOST=ru01.example.com make traefik
```

 Для нескольких хостов:

```
HOST=ru01.example.com,us03.example.com make docker-services
```

 Для запуска только определённых тегов:

```
TAGS=users,iptables make some-playbook
```

 Можно одновременно указать несколько хостов и тегов:

```
HOST=ru01.example.com,us03.example.com \
TAGS=users,iptables \
make some-playbook
```

 Если `HOST` или `TAGS` не заданы, соответствующий параметр будет выбран интерактивно через `fzf`.

 ### Доступные targets

 | Target | Описание |
| --- | --- |
| `make` | Интерактивный выбор playbook, хостов и тегов |
| `prepare` | Подготовка `uv`, `.venv` и зависимостей демона |
| `daemon` | Запуск REST API провижининга |
| `sshconfig` | Настройка SSH config на localhost |
| `docker-services` | Деплой docker-services |
| `traefik` | Деплой Traefik |
| `update-from-upstream` | Обновление из upstream |
| `generate-playbooks` | Генерация Make targets для Ansible playbook'ов |
| `import-infra-to-sshconfig` | Импорт хостов из Ansible Controller в `~/.ssh/config` |

 Полный список targets:

```
make help
```

 ### Требования

 Для интерактивного режима требуется `fzf`:

```
brew install fzf
```

 При отсутствии `HOST` Makefile автоматически запускает `tools/select-hosts.sh`, который получает список фактических target-хостов выбранного playbook через `ansible-playbook --list-hosts`.

 При отсутствии `TAGS` используется `tools/select-tags.sh`, который получает список тегов через `ansible-playbook --list-tags`.

 После выбора playbook, хостов и тегов выполняется команда в следующем виде:

```
<playbook> -l <host(s)> -t <tag(s)>
```

 После успешного выполнения playbook автоматически запускается `./playbooks/utils/run-checks.yml` для выбранных хостов.


## Плейбуки

Каталоги: `backups`, `configuration`, `databases`, `exporters`, `logs`, `monitoring`, `services`, `utils`, `vpns`.

Типичный плейбук — один `run-*.yml` на одну Galaxy-роль:

```yaml
#!/usr/bin/env -S ansible-playbook -e @vars/extra.yaml
---
- name: Configure target servers
  hosts: traefik
  roles:
    - { role: sorrowless.traefik, tags: ['traefik'] }
```

Композитные стеки — в корне `playbooks/` как `run-*-full.yml` (19 файлов), например `run-minimal-full.yml`, `run-mail-full.yml`:

```yaml
- name: Ensure TLS certificates
  import_playbook: services/run-tls.yml
```

```bash
./playbooks/run-minimal-full.yml -l myhost.example.com --tags common
find playbooks -name 'run-*.yml' | sort
```

Каталог: [`docs/reference/playbooks-catalog.md`](docs/reference/playbooks-catalog.md).

## Переменные и vault

```bash
. ./tools/set-vars.sh    # become + vault (+ mitogen если установлен)
```

Плейбуки подключают [`vars/extra.yaml`](vars/extra.yaml). Vault: `tools/get-vault-pass` через [`ansible.cfg`](ansible.cfg).

Примеры host vars: [`host_vars/.examples/`](host_vars/.examples/).

## Ускорение: mitogen

```bash
ansible-playbook tools/switch-to-mitogen.yml
. ./tools/set-vars.sh
```

## Демон провижининга

```bash
make daemon
```

API и `curl`-примеры: [`daemon/readme.md`](daemon/readme.md), [`docs/guides/provisioner-daemon.md`](docs/guides/provisioner-daemon.md).

## Динамический inventory

Ansible inventory генерируется динамически с помощью [`inventory/hosts.py`](https://github.com/sorrowless/ansible_controller/blob/master/inventory/hosts.py).

Группы хостов автоматически формируются на основе YAML-файлов в `inventory/host_vars/<host>/`. Например:

```text
inventory/host_vars/
├── web-01/
│   ├── nginx.yml
│   └── docker.yml
└── web-02/
    └── nginx.yml
````

 создаст следующие группы:

```
[nginx]
web-01
web-02

[docker]
web-01
```

 Сгенерированный inventory объединяется со статическим inventory `inventory/hosts`. Существующие хосты, группы и переменные сохраняются, а дублирующиеся хосты и группы автоматически объединяются.

 Посмотреть итоговый inventory можно командой:

```
ansible-inventory -i inventory/hosts.py --list
```

## CI

Скрипт [`tools/ci-script.py`](tools/ci-script.py) анализирует git diff, скачивает роли и генерирует ansible-команды. Маппинг vars → playbooks: [`tools/ci-config.yml`](tools/ci-config.yml).

```bash
python tools/ci-script.py --preview --target_branch main
python tools/ci-script.py --apply --target_branch main
```

Пример маппинга в `ci-config.yml`:

```yaml
mappings:
  scrape_configs_*.yml:
    playbooks/monitoring/run-vmagent.yml: {}

  docker.yml:
    playbooks/services/run-docker.yml:
      priority: 30
```

См. [`docs/guides/ci-automation.md`](docs/guides/ci-automation.md).

## Примеры сценариев

| Сценарий | Документ |
|----------|----------|
| Минимальный сервер | [`docs/examples/minimal-server.md`](docs/examples/minimal-server.md) |
| Traefik | [`docs/examples/traefik-deploy.md`](docs/examples/traefik-deploy.md) |
| Мониторинг | [`docs/examples/monitoring-stack.md`](docs/examples/monitoring-stack.md) |

## Лицензия

Apache 2.0

## Автор

[Stan Bogatkin](https://sbog.org)
