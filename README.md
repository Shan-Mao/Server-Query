# Minecraft 服务器状态查询

PCL2 主页集成工具 —— 一键查询任意 Minecraft 服务器的在线状态、玩家信息、MOTD 等。

数据来源：[uapis.cn](https://uapis.cn)

---

## 安装

1. 将 `Custom.xaml` 放入 PCL 目录（与 `PCL.exe` 同目录）
2. 将 `Server Query` 文件夹整个放入同一目录

```
PCL 目录\
├── Custom.xaml          ← 放这里
├── Server Query\        ← 放这里
│   ├── mc-server.exe
│   ├── mc-launcher.vbs
│   ├── mc-reset.vbs
│   ├── Logo.ico
│   └── Logo.png
└── PCL.exe
```

如果你已有 `Custom.xaml`，将卡片内容合并进去即可，不要覆盖。

---

## 使用

1. 打开 PCL，主页出现 **「🌐 Minecraft 服务器状态查询」** 卡片
2. 点击 **「🔍 查询服务器状态」** → 弹出深色无边框窗口
3. 输入服务器地址（如 `mc.hypixel.net`），可选填 API 密钥
4. 点击查询，结果即时显示
5. 配置自动保存，下次打开自动查询，**1 秒出结果**

### 按钮说明

| 按钮 | 功能 |
|------|------|
| 🔍 查询服务器状态 | 打开查询窗口 |
| 🔑 获取 API 密钥 | 跳转 uapis.cn 获取免费密钥（可选） |
| 🔄 初始化配置 | 清空已保存配置，恢复默认服务器地址 |

### 查询窗口操作

- **拖拽**：按住标题栏区域拖动窗口
- **✕**：关闭窗口
- **─**：最小化窗口
- **Ctrl+C / Ctrl+V**：输入框内支持复制粘贴
- **☑ 打开时自动查询**：勾选后每次打开窗口自动查询

---

## 修改默认服务器地址

用记事本打开 `Server Query\mc-server.ahk`，修改第 8-9 行：

```autohotkey
DefaultServer := "mc.hypixel.net"   ; ← 改成你的服务器
DefaultApiKey := ""                 ; ← 填写 API 密钥（可选）
```

修改后用 `Ahk2Exe.exe` 重新编译为 `mc-server.exe`。

---

## 返回数据

| 字段 | 说明 |
|------|------|
| 在线状态 | 🟢 在线 / 🔴 离线 |
| 当前玩家 | 在线人数 / 最大人数 |
| 版本 | 服务器支持的版本范围 |
| IP 地址 | 解析后的 IP 及端口 |
| MOTD | 服务器公告（纯文本 + 彩色格式） |
| 在线玩家列表 | 前 30 名在线玩家名称 |

---

## 依赖

- **无需 AutoHotkey**：`mc-server.exe` 为独立可执行文件
- **无需浏览器**：桌面原生窗口，直连 API
- **无需额外配置**：首次运行自动生成配置文件

---

## 文件说明

| 文件 | 说明 |
|------|------|
| `Custom.xaml` | PCL 主页卡片定义 |
| `Server Query\mc-server.exe` | 查询窗口主程序 |
| `Server Query\mc-launcher.vbs` | 静默启动器（无黑窗） |
| `Server Query\mc-reset.vbs` | 配置初始化脚本 |
| `Server Query\mc-server.ahk` | AHK 源码（可修改） |
| `Server Query\Logo.ico` | 任务栏图标 |
| `Server Query\Logo.png` | 托盘图标 |

---

## 截图

（请自行补充截图）

---

## 致谢

- API 服务：[uapis.cn](https://uapis.cn)
- PCL2：[Plain Craft Launcher 2](https://github.com/Meloong-Git/PCL)
