sbog.controller
===============

Base framework to create further Ansible deploys for organization. It's nothing
more but just a carcass to further developing deployments.

#### Requirements

Ansible Galaxy

#### Dependencies

None

#### IP inventory script
playbooks/utils/run-generate_ip_report.yml - плейбук, который пройдется по хостам для сбора информации об ip адресах.
./get_ips.sh - скрипт обертка над run-generate_ip_report.yml, который выводит отчет в консоль после выполнения плейбука. Сам отчет сохраняется в /tmp/ip_inventory_report.txt.
subnets.json - файл с описанием выделенных подсетей, зарезервированных и заблокированных адресов. Следует добавлять в этот файл новые заблокированные адреса и подсети, для учета их при составлении отчета об ip адресах.
Выполнить ./get_ips.sh из корня репозитория, в результате выполнится проверка адресов на всех хостах в группах tg_proxy_hosts_v2, hypervisors и сгенерируется отчет о занятых и доступных к использованию ip адресов.

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

This will install all needed roles to `roles` directory:

```bash
./tools/get-roles.sh
```

Then you just need to create according group/host vars, inventory files and run
your playbooks.
In case you just need to know current nodes list, run

```bash
./tools/nodes_list.sh
```

Some examples can be found in `host_vars/.examples` directory.
In case you want to faster deploys there is a playbook which downloads mitogen
and installed it locally and configures as default strategy. You can run it by

```bash
ansible-playbook tools/switch-to-mitogen.yml
```

#### Playbooks directory structure
The directory has the following structure:
- backups
- configuration
- databases
- exporters
- logs
- monitoring
- services
- utils
- vpns
- full-files

Playbooks in every directory run exactly one included role. But full-files includes entire run-files from subdirectories.

```yaml
# example run-bitwarden-full.yml
...
---
- name: Ensure TLS certificates
  import_playbook: services/run-tls.yml

- name: Setup Nginx
  import_playbook: services/run-nginx.yml
...
```
```yaml
# example services/run-tls.yml
...
---
- name: Configure target servers
  hosts: all
  #serial: 1
  remote_user: root

  roles:
    - { role: sorrowless.tls, tags: ['tls'] }
...
```

#### Gitlab-CI

Python script tools/ci-script.py check git diff for current branch and target branch (specified by option --target_branch). For changed host and group vars files that script find corresponding roles for thats files in tools/roles_lists directory and download it. Than scrip generate ansible commands with limits and tags. On option --preview script just show commands, on option --apply script will execute that commands. You can specify tags for generated commands and manualy match config files with run-files in tools/ci-files-mapping.yml.

```yaml
# example tools/ci-files-mapping.yml
scrape_configs_*.yml: # host/group vars file. You can use unix wildcards in conf-files names
  run-vmagent.yml: # run-file who will execute for that conf-faile
  - some-tag # tags for that run-file
```

#### License

Apache 2.0

#### Author Information

[Stan Bogatkin](https://sbog.org)
