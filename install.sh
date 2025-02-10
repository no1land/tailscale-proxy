#!/bin/bash

# 颜色
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# 检测是否为 Root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用 root 用户运行此脚本！\n" && exit 1

# 系统检测
os_check() {
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
    elif cat /etc/issue | grep -q -E -i "debian"; then
        release="debian"
    elif cat /etc/issue | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version | grep -q -E -i "debian"; then
        release="debian"
    elif cat /proc/version | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    else
        echo -e "${red}未检测到系统版本，请联系脚本作者！${plain}\n" && exit 1
    fi
}

# 检查系统架构
arch_check() {
    arch=$(arch)
    if [[ $arch != "x86_64" && $arch != "aarch64" ]]; then
        echo -e "${red}不支持的系统架构: ${arch}${plain}\n" && exit 1
    fi
}

# 检查依赖并安装
install_dependencies() {
    if [[ ${release} == "centos" ]]; then
        yum install -y wget curl tar
    else
        apt-get update
        apt-get install -y wget curl tar
    fi
}

# 安装 Docker
install_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${yellow}正在安装 Docker...${plain}"
        curl -fsSL https://get.docker.com | bash -s docker
        systemctl enable docker
        systemctl start docker
    fi
    
    if ! command -v docker-compose >/dev/null 2>&1; then
        echo -e "${yellow}正在安装 Docker Compose...${plain}"
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
}

# 部署服务
deploy_service() {
    # 创建工作目录
    mkdir -p /opt/tailscale-proxy
    cd /opt/tailscale-proxy

    # 下载配置文件
    wget -N --no-check-certificate https://raw.githubusercontent.com/your-repo/docker-compose.yml
    wget -N --no-check-certificate https://raw.githubusercontent.com/your-repo/setup.sh
    chmod +x setup.sh

    # 获取 Tailscale 密钥
    echo -e "${yellow}请输入 Tailscale 认证密钥 (从 https://login.tailscale.com/admin/settings/keys 获取)：${plain}"
    read -p "密钥: " auth_key
    
    if [[ -z "${auth_key}" ]]; then
        echo -e "${red}错误：密钥不能为空${plain}" && exit 1
    fi

    # 运行安装脚本
    ./setup.sh "${auth_key}"
}

# 显示结果
show_result() {
    echo -e "\n${green}安装完成！${plain}"
    echo -e "------------------------------------------------"
    echo -e "代理配置信息："
    echo -e "代理类型: SOCKS5"
    echo -e "代理端口: 1080"
    echo -e "用户名: $(grep PROXY_USER /opt/tailscale-proxy/.env | cut -d= -f2)"
    echo -e "密码: $(grep PROXY_PASS /opt/tailscale-proxy/.env | cut -d= -f2)"
    echo -e "------------------------------------------------"
}

# 主函数
main() {
    clear
    echo -e "${green}开始安装 Tailscale + GOST 代理服务...${plain}"
    
    os_check
    arch_check
    install_dependencies
    install_docker
    deploy_service
    show_result
}

main "$@"
