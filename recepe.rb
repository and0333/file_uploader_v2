Specinfra::Command::Astralinux = Class.new
Specinfra::Command::Astralinux::Base = Class.new(Specinfra::Command::Debian::Base)
Specinfra::Command::Astralinux::Base::Ppa = Class.new(Specinfra::Command::Debian::Base::Ppa)
Specinfra::Command::Astralinux::Base::Service = Class.new(Specinfra::Command::Debian::Base::Service)

# ==========================================
# 1. ОБНОВЛЕНИЕ СИСТЕМЫ
# ==========================================

execute 'update_system' do
  command 'apt-get update'
end


# ==========================================
# 2. УСТАНОВКА БАЗОВЫХ ПАКЕТОВ
# ==========================================

%w[
  sudo
  iptables
  iptables-persistent
  curl
  ca-certificates
  gnupg
  lsb-release
  net-tools
  openssh-server
].each do |pkg|
  package pkg do
    action :install
  end
end


# ==========================================
# 3. СОЗДАНИЕ И НАСТРОЙКА ПОЛЬЗОВАТЕЛЯ
# ==========================================


user 'ingipro' do
  create_home true
  shell '/bin/bash'
  action :create
  not_if 'id ingipro'
end

execute 'add_ingipro_to_sudo' do
  command 'usermod -aG sudo ingipro'
  not_if 'groups ingipro | grep -q sudo'
end

file '/etc/sudoers.d/ingipro' do
  content "ingipro ALL=(ALL) NOPASSWD:ALL\n"
  mode '0440'
  owner 'root'
  group 'root'
end


# ==========================================
# 4. SSH НАСТРОЙКА
# ==========================================


directory '/home/ingipro/.ssh' do
  owner 'ingipro'
  group 'ingipro'
  mode '0700'
  action :create
end

execute 'add_ssh_key' do
  command "echo '#{ENV['SSH_PUBLIC_KEY']}' >> /home/ingipro/.ssh/authorized_keys"
  not_if "grep -q '#{ENV['SSH_PUBLIC_KEY']}' /home/ingipro/.ssh/authorized_keys"
end

file '/home/ingipro/.ssh/authorized_keys' do
  owner 'ingipro'
  group 'ingipro'
  mode '0600'
  action :create
end

service 'ssh' do
  action [:enable, :start]
end
# ==========================================
# 5. НАСТРОЙКА IPTABLES (С DROP POLICY!)
# ==========================================

# ВАЖНО: Правильный порядок для безопасности!

# 1. СНАЧАЛА разрешаем установленные соединения (критично!)
execute "iptables_established" do
  command "iptables -I INPUT 1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT"
  not_if "iptables -C INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null"
end

# 2. Разрешаем loopback
execute "iptables_loopback" do
  command "iptables -A INPUT -i lo -j ACCEPT"
  not_if "iptables -C INPUT -i lo -j ACCEPT 2>/dev/null"
end

# 3. Разрешаем SSH (КРИТИЧНО - наш порт!)
execute "iptables_ssh" do
  command "iptables -A INPUT -p tcp --dport 22 -j ACCEPT"
  not_if "iptables -C INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null"
end

# 4. Разрешаем HTTP (для веб-приложения)
execute "iptables_http" do
  command "iptables -A INPUT -p tcp --dport 80 -j ACCEPT"
  not_if "iptables -C INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null"
end


# 5. Разрешаем ICMP (ping)
execute "iptables_icmp" do
  command "iptables -A INPUT -p icmp -j ACCEPT"
  not_if "iptables -C INPUT -p icmp -j ACCEPT 2>/dev/null"
end

# 6. ТОЛЬКО В САМОМ КОНЦЕ устанавливаем DROP policy
execute "iptables_policy_drop" do
  command "iptables -P INPUT DROP && iptables -P FORWARD DROP"
  not_if "iptables -L | grep -q 'Chain INPUT (policy DROP)'"
end

# 7. Сохраняем правила
execute "save_iptables" do
  command "iptables-save > /etc/iptables/rules.v4"
end

# Автозагрузка правил при загрузке системы
file "/etc/network/if-pre-up.d/iptables-restore" do
  content <<-EOL
#!/bin/sh
iptables-restore < /etc/iptables/rules.v4
EOL
  mode "755"
end

# ==========================================
# 6. УСТАНОВКА DOCKER
# ==========================================

execute 'install_docker' do
  command <<-EOL
    apt-get remove -y docker.io docker-doc docker-compose containerd runc podman-docker || true
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg > /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
      > /etc/apt/sources.list.d/docker.list
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  EOL
end

service 'docker' do
  action [:enable, :start]
end

execute 'add_ingipro_to_docker' do
  command 'usermod -aG docker ingipro'
  not_if 'groups ingipro | grep -q docker'
end

execute 'create_docker_network_ingipro' do
  command 'docker network create ingipro'
  not_if 'docker network ls --format "{{.Name}}" | grep -q "^ingipro$"'
end

# ==========================================
# 7. ПОДГОТОВКА ДИРЕКТОРИЙ ДЛЯ ПРИЛОЖЕНИЯ
# ==========================================


directory "/home/ingipro/storage" do
  action :create
  mode "0755"
  owner "ingipro"
  group "ingipro"
end
# ==========================================
# 8. ФИНАЛЬНАЯ ПРОВЕРКА
# ==========================================

execute 'final_check' do
  command <<-EOL
    echo "=== FINAL SYSTEM CHECK ==="
    echo "User ingipro exists: $(id ingipro)"
    echo "User: $(id ingipro)"
    echo "Sudo: $(sudo whoami)"
    echo "Sudo access: $(groups ingipro | grep -q sudo && echo 'YES' || echo 'NO')"
    echo "Docker installed: $(command -v docker && echo 'YES' || echo 'NO')"
    echo "Docker running: $(systemctl is-active docker)"
    echo "iptables rules: $(iptables -L INPUT | wc -l) rules"
    echo "iptables policy: $(iptables -L | grep 'Chain INPUT')"
    echo "=== CHECK COMPLETE ==="
  EOL
end
