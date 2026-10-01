<div align="center">

# 🌊 Claude Desktop 中文精校语言包 (Windows)
### 告别机翻味 · 深度人工精校 · 一键无损注入 · 完美支持 3P/Cowork

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-blue.svg?style=flat-square&logo=windows)](https://github.com/anhuiyifan/win-Claude-CN)
[![Claude Version](https://img.shields.io/badge/Claude%20Desktop-Latest%20Supported-purple.svg?style=flat-square&logo=anthropic)](https://claude.ai/download)
[![PRs Welcome](https://img.shields.io/badge/PRs-Welcome-brightgreen.svg?style=flat-square)](https://github.com/anhuiyifan/win-Claude-CN)
[![License](https://img.shields.io/badge/License-MIT-orange.svg?style=flat-square)](LICENSE.md)
</div>

---

## ⚡ 极速安装（只需 30 秒）

### 📥 第一步：获取文件
点击右上角绿色 **`Code` -> `Download ZIP`**（或直接在 Release 页面下载压缩包），解压到电脑任意位置。

### 🚀 第二步：一键注入
1. **完全退出** 正在运行的 Claude Desktop（请检查屏幕右下角托盘图标，确保彻底退出）。
2. 鼠标**右键点击**文件夹中的 **`一键安装中文.bat`**，选择 **【以管理员身份运行】**。
3. 脚本会自动寻找安装路径（无论你的 Claude 是从微软商店安装的还是官网下载的），自动备份原文件并完成汉化。

### 🎉 第三步：尽情体验
启动 Claude Desktop。如果已有窗口，在界面内随手按一次键盘快捷键 **`Ctrl + R`** 刷新页面，即可看到焕然一新的纯正中文！

---

## 🔄 一键恢复官方原版（无损还原）

脚本在每次注入前都会在本地自动创建官方原版备份。如果你想恢复原版英文：
1. 彻底退出 Claude Desktop。
2. 右键管理员运行 **`一键恢复官方.bat`**。
3. 重新打开 Claude，即刻恢复到官方最初状态，不留任何痕迹。


---

## 💻 兼容环境与平台

| 项目 | 说明与兼容性 |
| :--- | :--- |
| **支持系统** | Windows 10 / Windows 11 (64位) |
| **客户端来源** | 微软商店版 (`C:\Program Files\WindowsApps\Claude_*`)<br/>官网独立安装版 (`%LOCALAPPDATA%\AnthropicClaude`) 均完美自适应识别 |
| **运行时依赖** | 只要系统预装有 Python 3.10+ 与 PowerShell 即可，无需繁重的编译链 |

---

## ❓ 常见问题 (FAQ)

<details>
<summary><b>Q1: 运行 bat 脚本时提示拒绝访问或权限不足？</b></summary>
微软商店版 Claude 存放在受保护的 <code>WindowsApps</code> 目录下。请务必<b>右键选择【以管理员身份运行】</b>，在弹出的系统 UAC 提示框中点击“是”。脚本内部已内置 ACL 权限放通逻辑。
</details>

<details>
<summary><b>Q2: 提示安装成功后，打开界面为什么部分还是英文？</b></summary>
在系统右下角托盘图标彻底退出 Claude 重新打开。
</details>

<details>
<summary><b>Q3: Claude 客户端自动更新升级后，汉化没了怎么办？</b></summary>
官方客户端自动更新时会全量下载官方纯净包覆盖。遇到更新后汉化失效，只需再次双击运行一次 <b><code>一键安装中文.bat</code></b> 即可瞬间恢复中文！
</details>

---

## 📂 仓库结构速览

```text
├── resources/                     # 核心校对完成的语言包
│   ├── frontend-zh-CN.json        # 前端界面、设置、模型全量精校词条
│   ├── desktop-zh-CN.json         # 桌面外壳托盘与系统菜单词条
│   └── statsig-zh-CN.json         # 实验性功能与配置词条
├── 一键安装中文.bat                # 🚀 Windows 用户双击一键安装
├── 一键恢复官方.bat                # 🔄 一键安全还原官方英文原版
├── localize-claude.ps1            # 自动化提权与资源注入主脚本
├── restore-windowsapps-zh-cn.ps1  # 官方文件安全恢复脚本
├── patch_windowsapps_json_only.py # 核心注入引擎与白名单修补逻辑
└── README.md                      # 本说明文档
```

---

## 🤝 参与贡献 & 反馈

- 如果你在使用过程中发现了漏翻的角落、显示生硬的字句，或者 Claude 新版新增的词条，欢迎随时提交 [Issue](https://github.com/anhuiyifan/win-Claude-CN/issues) 或 [Pull Request](https://github.com/anhuiyifan/win-Claude-CN/pulls)！
- 欢迎点击右上角的 ⭐️ **Star** 收藏关注，我们将第一时间跟进官方版本的汉化适配！

---

## 📜 开源协议与免责声明

1. 本项目基于 [MIT 许可证](LICENSE.md) 开源。
2. 本项目仅供学习交流与个人研究使用，所有修改均在用户本地计算机生效，不包含任何外连上传行为。
3. Claude、Anthropic 徽标及相关商标版权均归 Anthropic PBC 所有。
