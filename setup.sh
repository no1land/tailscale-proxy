#!/bin/bash

# 颜色设置
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
NC="\033[0m"

# 检查是否提供了 Tailscale 认证密钥
if [ -z "$1" ]; then
    echo -e "${RED}错误: 请提供 Tailscale 认证密钥${NC}"
    echo "使用方法: $0 <TAILSCALE_AUTH_KEY>"
    exit 1
fi

# 检查 Docker 是否已安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}错误: Docker 未安装${NC}"
        exit 1
    fi
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}错误: Docker Compose 未安装${NC}"
        exit 1
    fi
}

# 创建必要的目录和文件
setup_directories() {
    # 创建 Tailscale 数据目录
    mkdir -p tailscale
    
    # 生成随机用户名和密码
    PROXY_USER="user_$(openssl rand -hex 4)"
    PROXY_PASS="$(openssl rand -base64 12)"
    
    # 创建 .env 文件
    cat > .env << EOL
TAILSCALE_AUTH_KEY=$1
PROXY_USER=$PROXY_USER
PROXY_PASS=$PROXY_PASS
EOL
}

# 启动服务
start_services() {
    echo -e "${YELLOW}正在启动服务...${NC}"
    docker-compose down &>/dev/null || true
    docker-compose up -d
    
    # 等待服务启动
    echo -e "${YELLOW}等待服务启动...${NC}"
    sleep 10
}

# 检查服务状态
check_services() {
    echo -e "${YELLOW}检查服务状态...${NC}"
    
    # 检查容器状态
    if [ "$(docker-compose ps -q | wc -l)" -ne "2" ]; then
        echo -e "${RED}错误: 部分服务未能正常启动${NC}"
        docker-compose logs
        exit 1
    fi
    
    # 检查 Tailscale 状态
    local max_attempts=12
    local attempt=1
    local tailscale_ok=false
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose exec tailscale tailscale status &>/dev/null; then
            tailscale_ok=true
            break
        fi
        echo -e "${YELLOW}等待 Tailscale 就绪... ($attempt/$max_attempts)${NC}"
        sleep 5
        attempt=$((attempt + 1))
    done
    
    if [ "$tailscale_ok" = false ]; then
        echo -e "${RED}错误: Tailscale 未能成功启动${NC}"
        docker-compose logs tailscale
        exit 1
    fi
}

# 显示配置信息
show_config() {
    echo -e "${GREEN}\n部署完成！${NC}"
    echo -e "\n代理配置信息："
    echo "------------------------"
    echo "代理类型: SOCKS5"
    echo "代理端口: 1080"
    echo "用户名: $PROXY_USER"
    echo "密码: $PROXY_PASS"
    echo "------------------------"
    echo -e "\n代理管理命令："
    echo "查看状态: docker-compose ps"
    echo "查看日志: docker-compose logs"
    echo "重启服务: docker-compose restart"
    echo "停止服务: docker-compose down"
    echo "启动服务: docker-compose up -d"
}

# 主函数
main() {
    echo -e "${GREEN}开始部署 Tailscale + GOST 代理服务...${NC}"
    
    check_docker
    setup_directories "$1"
    start_services
    check_services
    show_config
}

# 执行主函数
main "$1"
