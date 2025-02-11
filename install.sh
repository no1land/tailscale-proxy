#!/bin/bash

# 颜色
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# 检测是否为 Root（非 macOS）
if [[ "$(uname)" != "Darwin" && $EUID -ne 0 ]]; then
    echo -e "${red}错误：${plain} Linux 系统必须使用 root 用户运行此脚本！\n" 
    exit 1
fi

# 系统检测
os_check() {
    if [[ "$(uname)" == "Darwin" ]]; then
        release="mac"
    elif [[ -f /etc/redhat-release ]]; then
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

# 检查依赖并安装
install_dependencies() {
    if [[ ${release} == "mac" ]]; then
        if ! command -v wget >/dev/null 2>&1; then
            echo -e "${yellow}正在使用 curl 下载文件...${plain}"
        fi
    elif [[ ${release} == "centos" ]]; then
        yum install -y wget curl tar
    else
        apt-get update
        apt-get install -y wget curl tar
    fi
}

# 检查并安装 Docker
install_docker() {
    if [[ ${release} == "mac" ]]; then
        if ! command -v docker >/dev/null 2>&1; then
            echo -e "${red}错误：未检测到 Docker Desktop${plain}"
            echo -e "${yellow}请访问 https://www.docker.com/products/docker-desktop 下载安装 Docker Desktop${plain}"
            echo -e "${yellow}安装完成后重新运行此脚本${plain}"
            exit 1
        else
            # 检查 Docker 是否正在运行
            if ! docker info >/dev/null 2>&1; then
                echo -e "${red}错误：Docker Desktop 未启动${plain}"
                echo -e "${yellow}请启动 Docker Desktop 后重新运行此脚本${plain}"
                exit 1
            fi
        fi
    else
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
    fi
}

# 部署服务
deploy_service() {
    if [[ ${release} == "mac" ]]; then
        # macOS 使用当前目录
        INSTALL_DIR="$(pwd)/tailscale-proxy"
        mkdir -p "$INSTALL_DIR"
        cd "$INSTALL_DIR"
    else
        # Linux 使用 /opt 目录
        INSTALL_DIR="/opt/tailscale-proxy"
        mkdir -p "$INSTALL_DIR"
        cd "$INSTALL_DIR"
    fi

    # 下载配置文件
    echo -e "${yellow}下载配置文件...${plain}"
    
    GITHUB_URL="https://raw.githubusercontent.com/no1land/tailscale-proxy/main"
    
    curl -o docker-compose.yml "${GITHUB_URL}/docker-compose.yml"
    if [ $? -ne 0 ]; then
        echo -e "${red}下载 docker-compose.yml 失败，请检查网络${plain}"
        exit 1
    fi
    
    curl -o setup.sh "${GITHUB_URL}/setup.sh"
    if [ $? -ne 0 ]; then
        echo -e "${red}下载 setup.sh 失败，请检查网络${plain}"
        exit 1
    fi
    chmod +x setup.sh

    # 获取 Tailscale 密钥
    echo -e "${yellow}请输入 Tailscale 认证密钥 (从 https://login.tailscale.com/admin/settings/keys 获取)：${plain}"
    read -p "密钥: " auth_key
    
    if [[ -z "${auth_key}" ]]; then
        echo -e "${red}错误：密钥不能为空${plain}"
        exit 1
    fi

    # 运行安装脚本
    ./setup.sh "${auth_key}"
}

# 主程序
echo -e "${green}开始安装...${plain}"

# 检查系统
os_check
install_dependencies
install_docker
deploy_service
