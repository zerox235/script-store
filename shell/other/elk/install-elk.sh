#!/bin/bash
# ==================================================
# ELK 7.17.21 单机版一键部署脚本（低配机器优化版）
# [功能]：ELK 单机版一键部署（低内存优化）
# [环境]：CentOS 7/8, RockyLinux 7/8
# [配置]：2核2G内存，20G磁盘空间
# [日期]：2026-05-04
# [作者]：Kahle
# ==================================================



# 确保脚本在执行错误时退出
set -e
# 引入公共脚本（ curl -Ls 可以替换为 wget -qO- ）
_D="/tmp/remote-func2512"; _F="$_D/_base.sh_$(date +%Y%m%d)"; _R="https://ghfast.top/https://raw.githubusercontent.com/kahle23/script-store/refs/heads/master/shell/_func/_base.sh";
mkdir -p "$_D" && { [ ! -f "$_F" ] && curl -Ls "$_R" > "$_F" || true; } && source "$_F"; find "$_D" -name "_base.sh_*" -mtime +1 -delete 2>/dev/null &
# 引入内置脚本
load_inbuilt_script "sys"


# 打印部署信息
log_info "===================================="
log_info ">> 开始ELK单机版部署（低配优化版） <<"
log_info "====================================\n\n"


# 1. 系统环境初始化
log_method_start "[1/7] 系统环境初始化..."
# 检查 root 权限
if ! check_root; then exit 1; fi
# 检测操作系统
detect_os
# 关闭防火墙和SELinux
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
# 配置系统资源限制（ES必备）
cat >> /etc/security/limits.conf << EOF
* soft nofile 65535
* hard nofile 65535
* soft nproc 4096
* hard nproc 4096
EOF
# 调整内核参数
cat >> /etc/sysctl.conf << EOF
vm.max_map_count=262144
net.core.somaxconn=65535
EOF
sysctl -p
log_method_end



# 2. 安装Java环境
log_method_start "[2/7] 安装Java环境..."
$pkg_mgr install -y java-1.8.0-openjdk-devel
java -version
if [ $? -eq 0 ]; then
    log_info "Java安装成功"
else
    log_error "Java安装失败，请检查网络"
    exit 1
fi
log_method_end



# 3. 配置Elasticsearch国内镜像源
log_method_start "[3/7] 配置Elasticsearch国内镜像源..."
cat > /etc/yum.repos.d/elasticsearch.repo << EOF
[elasticsearch-7.x]
name=Elasticsearch repository for 7.x packages
baseurl=https://mirrors.tuna.tsinghua.edu.cn/elasticstack/7.x/yum/
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
$pkg_mgr clean all
$pkg_mgr makecache
log_method_end



# 4. 安装Elasticsearch（低内存配置）
log_method_start "[4/7] 安装Elasticsearch..."
$pkg_mgr install -y elasticsearch-7.17.21
if [ $? -ne 0 ]; then
    log_error "Elasticsearch安装失败，请检查网络或yum源配置"
    exit 1
fi
# 配置Elasticsearch（低内存优化）
cat > /etc/elasticsearch/elasticsearch.yml << EOF
cluster.name: elk-cluster
node.name: node-1
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 0.0.0.0
http.port: 9200
discovery.seed_hosts: ["127.0.0.1"]
cluster.initial_master_nodes: ["node-1"]
xpack.security.enabled: false
EOF
# 配置JVM内存（低配机器优化）
sed -i 's/-Xms1g/-Xms256m/g' /etc/elasticsearch/jvm.options
sed -i 's/-Xmx1g/-Xmx512m/g' /etc/elasticsearch/jvm.options
# 修改Elasticsearch用户内存限制
sed -i 's/ES_JAVA_OPTS=""/ES_JAVA_OPTS="-Xms256m -Xmx512m"/g' /etc/sysconfig/elasticsearch
log_method_end



# 5. 安装Logstash（低内存配置）
log_method_start "[5/7] 安装Logstash..."
$pkg_mgr install -y logstash-7.17.21
if [ $? -ne 0 ]; then
    log_error "Logstash安装失败，请检查网络或yum源配置"
    exit 1
fi
# 配置Logstash基础管道
cat > /etc/logstash/conf.d/simple.conf << EOF
input {
  beats {
    port => 5044
  }
  tcp {
    port => 5000
    codec => json_lines
  }
}

output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => "logstash-%{+YYYY.MM.dd}"
  }
  stdout {
    codec => rubydebug
  }
}
EOF
# 配置Logstash JVM内存（低配优化）
sed -i 's/-Xms1g/-Xms128m/g' /etc/logstash/jvm.options
sed -i 's/-Xmx1g/-Xmx256m/g' /etc/logstash/jvm.options
log_method_end



# 6. 安装Kibana
log_method_start "[6/7] 安装Kibana..."
$pkg_mgr install -y kibana-7.17.21
if [ $? -ne 0 ]; then
    log_error "Kibana安装失败，请检查网络或yum源配置"
    exit 1
fi
# 配置Kibana（中文界面）
cat > /etc/kibana/kibana.yml << EOF
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://localhost:9200"]
i18n.locale: "zh-CN"
EOF
log_method_end



# 7. 启动所有服务并设置开机自启
log_method_start "[7/7] 启动ELK服务..."
# 启动 Elasticsearch
systemctl daemon-reload
if [ ! -f "/usr/lib/systemd/system/elasticsearch.service" ]; then
    log_error "Elasticsearch服务单元文件不存在，请检查安装是否完整"
    exit 1
fi
systemctl enable elasticsearch
systemctl start elasticsearch
sleep 10
# 检查 Elasticsearch 状态
curl -s http://localhost:9200
if [ $? -eq 0 ]; then
    log_info "Elasticsearch启动成功"
else
    log_error "Elasticsearch启动失败，请检查日志：journalctl -u elasticsearch"
fi
# 启动 Logstash（临时取消 JAVA_HOME，使用 Logstash 自带 JDK ）
unset JAVA_HOME
systemctl enable logstash
systemctl start logstash
sleep 5
# 启动 Kibana 
systemctl enable kibana
systemctl start kibana
sleep 5
# 下载部署文档
elk_doc_url="https://raw.githubusercontent.com/kahle23/script-store/refs/heads/master/shell/other/elk/elk-doc.txt"
download_by_mirror "${elk_doc_url}" "/root/elk-doc.txt"
log_method_end


log_info "===================================="
log_info ">>>>    ELK部署完成！    <<<<"
log_info "===================================="
log_info ""
log_info "访问地址："
log_info "  Elasticsearch: http://服务器IP:9200"
log_info "  Kibana:        http://服务器IP:5601"
log_info "  Logstash输入:  TCP 5000端口, Beats 5044端口"
log_info ""
log_info "内存优化配置："
log_info "  Elasticsearch: 256MB-512MB"
log_info "  Logstash:      128MB-256MB"
log_info ""
log_info "常用命令："
log_info "  查看服务状态：systemctl status elasticsearch/logstash/kibana"
log_info "  查看服务日志：journalctl -u elasticsearch -f"
log_info "  重启服务：systemctl restart elasticsearch"
log_info ""
log_info "脚本执行完毕！"


