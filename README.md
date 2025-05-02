# Tailscale + GOST 代理服务一键部署

使用 Docker 快速部署基于 Tailscale 的 SOCKS5 代理服务，支持多平台，配置简单，自动维护。

## 特点

- 🚀 一键部署：单行命令完成所有配置
- 🔒 安全可靠：基于 Tailscale 的安全网络
- 🔑 自动认证：随机生成安全的认证信息
- 🐳 容器化部署：基于 Docker，跨平台兼容
- 🔄 自动重启：服务意外停止自动恢复
- 📝 完整日志：便于问题诊断和监控


## 快速开始

### Linux 一键部署
```bash
wget -N --no-check-certificate "https://raw.githubusercontent.com/no1land/tailscale-proxy/main/install.sh" && chmod +x install.sh && ./install.sh
```

### macOS 一键部署
```bash
curl -o install.sh "https://raw.githubusercontent.com/no1land/tailscale-proxy/main/install.sh" && chmod +x install.sh && ./install.sh
```

### 前置条件

1. 一个 Tailscale 账号（从 [Tailscale官网](https://tailscale.com) 注册）
2. Tailscale 认证密钥（从 [密钥页面](https://login.tailscale.com/admin/settings/keys) 获取）
3. 支持的操作系统：
   - macOS 10.15+（需要安装 Docker Desktop）
   - Ubuntu 16.04+
   - Debian 9+
   - CentOS 7+

### macOS 用户注意事项

1. 确保已安装 Docker Desktop
   - 如果未安装，请访问 [Docker Desktop 官网](https://www.docker.com/products/docker-desktop) 下载安装
   - 安装完成后启动 Docker Desktop
2. 无需 root 权限，直接在终端运行一键部署命令
3. 如果提示 Docker 未运行，请先启动 Docker Desktop

## 使用指南

### 1. 获取 Tailscale 密钥
1. 登录 [Tailscale控制台](https://login.tailscale.com)
2. 访问 Settings -> Keys
3. 生成新的认证密钥（建议使用可重用的密钥）

### 2. 运行安装脚本
1. 执行一键部署命令
2. 根据提示输入 Tailscale 认证密钥
3. 等待安装完成，获取代理配置信息

### 3. 使用代理
安装完成后，会显示以下信息：
```
代理配置信息：
------------------------
代理类型: SOCKS5
代理端口: 1080
用户名: [自动生成]
密码: [自动生成]
Tailscale IP: [自动分配]
------------------------
```

同时会提供一个测试命令，可直接使用：
```bash
curl -4 --socks5 用户名:密码@Tailscale_IP:1080 http://ip.gs
```

## 管理命令

```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 启动服务
docker-compose up -d

# 查看ip
docker exec -it tailscale-proxy-tailscale-1 tailscale ip
or
docker exec -it tailscale-proxy-tailscale-1 tailscale status

# 登陆
docker exec -it tailscale-proxy-tailscale-1 tailscale up

```




## 故障排除

1. 如果安装失败：
   ```bash
   # 查看详细日志
   docker-compose logs
   ```

2. 如果需要重新安装：
   ```bash
   # 完全清理 Docker
   docker-compose down
   rm -rf /opt/tailscale-proxy
   ./install.sh
   ```

3. 如果需要更新认证密钥：
   ```bash
   # 编辑配置文件
   nano /opt/tailscale-proxy/.env
   # 更新 TAILSCALE_AUTH_KEY 后重启服务
   docker-compose restart
   ```

## 安全建议

1. 使用强密码策略（脚本会自动生成随机密码）
2. 定期更新 Tailscale 密钥
3. 只分享必要的代理信息给可信用户
4. 定期检查服务日志

## 卸载

如需完整卸载所有组件：

```bash
# 停止和删除容器
docker-compose down

# 删除项目文件
rm -rf /opt/tailscale-proxy

# 可选：卸载 Docker
apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
apt-get autoremove -y
```
## 测试
This project is tested with BrowserStack.

## 项目结构

```
.
├── install.sh          # 一键安装脚本
├── setup.sh           # 配置脚本
├── docker-compose.yml # Docker 服务配置
└── .env.example      # 环境变量示例
```

## 许可证

MIT License

## 致谢

- [Tailscale](https://tailscale.com/)
- [GOST](https://github.com/ginuerzh/gost)
- [Docker](https://www.docker.com/)
