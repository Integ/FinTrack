# 自定义域名配置指南

## 🌐 配置 FinTrack 的自定义域名

### 📋 前置条件
- 已拥有自定义域名（如：fintrack.yourdomain.com）
- 能够修改域名的 DNS 设置
- 已在 GitHub Pages 中启用了自定义域名

### 🔧 GitHub Pages 设置

1. **进入仓库设置**
   - 打开您的 GitHub 仓库
   - 点击 **Settings** 选项卡
   - 在左侧菜单中找到 **Pages**

2. **配置自定义域名**
   - 在 "Custom domain" 输入框中输入您的域名
   - 例如：`fintrack.yourdomain.com` 或 `www.yourdomain.com`
   - 点击 **Save**

3. **获取 DNS 配置信息**
   - GitHub 会显示需要配置的 DNS 记录
   - 通常有两种选择：
     - **A 记录**：指向 GitHub 的 IP 地址
     - **CNAME 记录**：指向 `[您的用户名].github.io`

### 🌍 DNS 配置

#### 方法一：使用 CNAME（推荐用于子域名）

在您的域名提供商后台添加：
```
类型: CNAME
主机: fintrack (或 www)
值: [您的用户名].github.io
TTL: 3600 (或自动)
```

#### 方法二：使用 A 记录（推荐用于根域名）

在您的域名提供商后台添加：
```
类型: A
主机: @ (或留空)
值: 185.199.108.153
值: 185.199.109.153  
值: 185.199.110.153
值: 185.199.111.153
TTL: 3600 (或自动)
```

### 📁 项目配置

#### 方法一：通过 GitHub Pages 管理界面
最简单的方法是在 GitHub 的 Pages 设置中配置，GitHub 会自动创建 CNAME 文件。

#### 方法二：手动创建 CNAME 文件
如果您想通过代码管理域名：

1. **创建 CNAME 文件**
```bash
echo "fintrack.yourdomain.com" > CNAME
git add CNAME
git commit -m "添加自定义域名配置"
git push origin main
```

2. **触发重新部署**
   - 推送代码后会自动触发 GitHub Actions
   - 新的部署会包含您的自定义域名

### 🛡️ HTTPS 配置

GitHub Pages 会自动为自定义域名配置 SSL 证书：

1. **等待证书生成**
   - 通常需要几分钟到几小时
   - 在 Pages 设置中查看状态

2. **强制 HTTPS**
   - 在 Pages 设置中勾选 "Enforce HTTPS"
   - 确保所有访问都通过安全的 HTTPS 连接

### ✅ 验证配置

配置完成后，检查以下项目：

1. **DNS 传播**
```bash
# 检查 CNAME 记录
dig CNAME fintrack.yourdomain.com

# 或使用在线工具
# https://www.whatsmydns.net/
```

2. **GitHub Pages 状态**
   - Settings > Pages 查看域名状态
   - 应显示 "Your site is published at..."

3. **访问测试**
   - 在浏览器中访问您的自定义域名
   - 检查证书是否有效（绿色锁图标）

### 🔧 常见域名提供商配置示例

#### Cloudflare
1. 登录 Cloudflare 面板
2. 选择您的域名
3. 添加 CNAME 记录：
   - Type: CNAME
   - Name: fintrack
   - Target: `[您的用户名].github.io`
   - Proxy status: DNS Only (灰云)

#### GoDaddy
1. 登录 GoDaddy 控制面板
2. 找到 DNS Management
3. 添加 CNAME 记录：
   - Type: CNAME
   - Name: fintrack
   - Value: `[您的用户名].github.io`
   - TTL: 1 Hour

#### Namecheap
1. 登录 Namecheap Dashboard
2. 选择 "Domain List" → "Manage"
3. 找到 "Advanced DNS"
4. 添加 CNAME 记录：
   - Type: CNAME Record
   - Host: fintrack
   - Value: `[您的用户名].github.io`
   - TTL: Automatic

### ⚠️ 注意事项

1. **DNS 传播时间**
   - 全球 DNS 更新可能需要 24-48 小时
   - 大多数情况下几分钟内生效

2. **子域名 vs 根域名**
   - 子域名（如 fintrack.yourdomain.com）推荐使用 CNAME
   - 根域名（如 yourdomain.com）必须使用 A 记录

3. **HTTPS 证书**
   - GitHub 自动提供 Let's Encrypt 证书
   - 证书每 3 个月自动续期

4. **重定向配置**
   - 建议同时配置 www 重定向到主域名
   - GitHub Pages 通常会自动处理

### 🚨 故障排除

#### 域名无法访问
1. 检查 DNS 记录是否正确配置
2. 使用 `dig` 或在线工具验证 DNS 解析
3. 确认 GitHub Pages 域名设置正确

#### HTTPS 证书问题
1. 等待证书生成完成（可能需要数小时）
2. 确认 DNS 记录指向正确的 GitHub 地址
3. 检查是否有其他证书冲突

#### 404 错误
1. 确认项目已成功部署
2. 检查 GitHub Actions 构建状态
3. 验证 CNAME 文件是否在构建目录中

### 📞 技术支持

如果遇到问题：
1. 查看 GitHub Pages 官方文档
2. 检查域名提供商的帮助文档
3. 在项目仓库中提交 Issue

---

**🎉 配置完成后，您的 FinTrack 应用将在自定义域名上运行！**