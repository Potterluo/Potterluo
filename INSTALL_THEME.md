# 主题安装指南

## 当前状态

主题下载未完成，请选择以下方式之一完成安装：

## 方法1：手动下载（最快，推荐）

### Windows用户

1. **下载主题**
   - 访问：https://github.com/chrede88/qubt/archive/refs/heads/main.zip
   - 或使用Gitee镜像：https://gitee.com/mirrors/qubt/archive/master.zip

2. **解压文件**
   - 将下载的zip文件解压
   - 找到解压后的文件夹（qubt-main 或 qubt-master）

3. **移动到正确位置**
   ```cmd
   # 在项目根目录打开命令行
   mkdir themes
   move 解压后的文件夹 themes\qubt
   ```

4. **验证安装**
   ```cmd
   dir themes\qubt\layouts
   ```
   应该看到多个目录和文件

### 使用PowerShell一键安装

```powershell
# 在项目根目录执行
cd E:\Project\keriko
Invoke-WebRequest -Uri "https://github.com/chrede88/qubt/archive/refs/heads/main.zip" -OutFile "qubt.zip"
Expand-Archive -Path "qubt.zip" -DestinationPath "themes"
Move-Item -Path "themes\qubt-main" -Destination "themes\qubt"
Remove-Item "qubt.zip"
```

## 方法2：使用Git

```bash
# 在项目根目录执行
git clone --depth 1 https://github.com/chrede88/qubt.git themes/qubt
```

## 方法3：使用Go模块

```bash
hugo mod get github.com/chrede88/qubt@latest
hugo mod tidy
```

然后修改 `config/_default/hugo.yaml`，移除 `theme: 'qubt'` 这一行。

## 验证安装

安装完成后，运行：

```bash
# 检查主题目录
ls themes/qubt/layouts

# 应该看到：
# _default/
# partials/
# 等

# 启动服务器测试
hugo server -D
```

访问 http://localhost:1313 查看网站。

## 故障排除

### 如果下载太慢

1. 使用下载工具（IDM、迅雷等）下载zip文件
2. 使用Gitee镜像（国内更快）
3. 从其他已下载的机器复制

### 如果解压失败

1. 确认zip文件完整（文件大小约200-300KB）
2. 尝试使用其他解压软件（7-Zip、WinRAR）
3. 重新下载zip文件

### 如果服务器启动失败

1. 确认主题目录存在：`ls themes/qubt/`
2. 检查权限：确保可读取主题文件
3. 清除缓存：`rm -rf resources/`
4. 查看错误信息：`hugo server -D --logLevel debug`

## 需要帮助？

如果遇到问题，请查看：
- [SETUP_STATUS.md](SETUP_STATUS.md) - 当前项目状态
- [QUICKSTART.md](QUICKSTART.md) - 快速入门指南
- [README.md](README.md) - 完整文档
