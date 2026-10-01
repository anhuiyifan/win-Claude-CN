import json
import re
from pathlib import Path

# 经典界面的核心翻译字典（涵盖设置、账户、账单、外观、快捷键、模型、上下文、对话管理等）
UI_DICTIONARY = {
    # 常用操作 & 状态
    "Settings": "设置",
    "General": "常规",
    "Appearance": "外观",
    "Account": "账户",
    "Profile": "个人资料",
    "Billing": "账单与订阅",
    "Notifications": "通知",
    "Privacy": "隐私",
    "Security": "安全",
    "Developer": "开发者",
    "Keyboard shortcuts": "键盘快捷键",
    "Keyboard Shortcuts": "键盘快捷键",
    "Shortcuts": "快捷键",
    "Language": "语言",
    "Font": "字体",
    "Color mode": "颜色模式",
    "Theme": "主题",
    "Light": "浅色",
    "Dark": "深色",
    "System": "跟随系统",
    "Auto": "自动",
    "Default": "默认",
    "Enabled": "已启用",
    "Disabled": "已禁用",
    "Enable": "启用",
    "Disable": "禁用",
    "Save": "保存",
    "Save changes": "保存更改",
    "Cancel": "取消",
    "Confirm": "确认",
    "Delete": "删除",
    "Remove": "移除",
    "Edit": "编辑",
    "Close": "关闭",
    "Back": "返回",
    "Next": "下一步",
    "Done": "完成",
    "Apply": "应用",
    "Reset": "重置",
    "Clear": "清除",
    "Copy": "复制",
    "Copied": "已复制",
    "Search": "搜索",
    "Search…": "搜索…",
    "Filter": "筛选",
    "Sort": "排序",
    "View": "查看",
    "Preview": "预览",
    "Download": "下载",
    "Upload": "上传",
    "Export": "导出",
    "Import": "导入",
    "Share": "分享",
    "Rename": "重命名",
    "Archive": "归档",
    "Unarchive": "取消归档",
    "Archived": "已归档",
    "Active": "活跃",
    "Status": "状态",
    "Details": "详情",
    "More": "更多",
    "Options": "选项",
    "Help": "帮助",
    "Support": "支持",
    "About": "关于",
    "Version": "版本",
    "Check for updates": "检查更新",
    "Checking for updates…": "正在检查更新…",
    "Update available": "有可用更新",
    "Restart to update": "重启以更新",
    "Up to date": "已是最新版本",
    "Sign out": "退出登录",
    "Log out": "退出登录",
    "Sign in": "登录",
    "Log in": "登录",
    "Delete account": "注销账户",
    "Manage subscription": "管理订阅",
    "Upgrade": "升级",
    "Upgrade plan": "升级计划",
    "Current plan": "当前计划",
    "Usage": "用量",
    "Usage limits": "用量限制",
    "Credits": "额度",
    "Billing history": "账单历史",
    "Payment method": "支付方式",
    "Invoices": "发票",

    # 对话与侧边栏
    "New chat": "新聊天",
    "New Chat": "新聊天",
    "New session": "新建会话",
    "New task": "新建任务",
    "New project": "新建项目",
    "Recent chats": "最近聊天",
    "Recent sessions": "最近会话",
    "Chat history": "聊天记录",
    "History": "历史记录",
    "Pinned": "已固定",
    "Pin": "固定",
    "Unpin": "取消固定",
    "Favorites": "收藏夹",
    "Starred": "已加星标",
    "All chats": "所有聊天",
    "Archived chats": "已归档聊天",
    "Clear history": "清除历史记录",
    "Delete chat": "删除聊天",
    "Delete session": "删除会话",
    "Rename chat": "重命名聊天",
    "Rename session": "重命名会话",
    "Export chat": "导出聊天",
    "Move to…": "移动到…",
    "Move to project": "移动到项目",

    # 模型与推理
    "Model": "模型",
    "Models": "模型",
    "Default model": "默认模型",
    "Choose a model": "选择模型",
    "Claude 3.7 Sonnet": "Claude 3.7 Sonnet",
    "Claude 3.5 Sonnet": "Claude 3.5 Sonnet",
    "Claude 3.5 Haiku": "Claude 3.5 Haiku",
    "Claude 3 Opus": "Claude 3 Opus",
    "Extended thinking": "深度思考",
    "Thinking": "思考中",
    "Thought process": "思考过程",
    "Thinking budget": "思考预算",
    "Tokens": "Token",
    "Context": "上下文",
    "Context window": "上下文窗口",
    "Memory": "记忆",
    "Artifacts": "工件",
    "Code execution": "代码执行",
    "Analysis tool": "分析工具",
    "Connectors": "连接器",
    "Integrations": "集成",
    "Extensions": "扩展",
    "Custom instructions": "自定义指令",
    "System prompt": "系统提示词",

    # 快捷键与导航
    "Command Palette": "命令面板",
    "Quick actions": "快捷操作",
    "Zoom in": "放大",
    "Zoom out": "缩小",
    "Actual size": "实际大小",
    "Toggle sidebar": "切换侧边栏",
    "Toggle full screen": "切换全屏",
    "Full screen": "全屏",
    "Split view": "分屏视图",
    "Close window": "关闭窗口",
    "Minimize": "最小化",
    "Quit Claude": "退出 Claude",

    # 二级设置页详细条目
    "Appearance settings": "外观设置",
    "Account settings": "账户设置",
    "Notification settings": "通知设置",
    "Developer settings": "开发者设置",
    "Claude Code settings": "Claude Code 设置",
    "Cowork settings": "Cowork 协作设置",
    "Desktop app settings": "桌面应用设置",
    "Open in default browser": "在默认浏览器中打开",
    "Open logs folder": "打开日志文件夹",
    "Open config folder": "打开配置文件夹",
    "Hardware acceleration": "硬件加速",
    "Disable hardware acceleration": "禁用硬件加速",
    "Enable hardware acceleration": "启用硬件加速",
    "Run at startup": "开机自启动",
    "Keep running in system tray": "在系统托盘保持运行",
    "Show dock icon": "显示程序图标",
    "Show tray icon": "显示托盘图标",
    "Send feedback": "发送反馈",
    "Documentation": "开发文档",
    "Release notes": "更新日志",
    "Terms of service": "服务条款",
    "Privacy policy": "隐私政策",
}

def main():
    missing_front = json.loads(Path("missing_front.json").read_text(encoding="utf-8"))
    print("Total missing front keys:", len(missing_front))

    # 读取已翻译的部分（若有）
    trans_front = {}
    f_all = Path("translated_front_all.json")
    if f_all.exists():
        try:
            trans_front = json.loads(f_all.read_text(encoding="utf-8"))
        except Exception:
            pass

    # 匹配规则与自动本地化
    matched = 0
    for k, v in missing_front.items():
        if k in trans_front:
            continue
        v_str = str(v).strip()
        # 1. 精确匹配
        if v_str in UI_DICTIONARY:
            trans_front[k] = UI_DICTIONARY[v_str]
            matched += 1
            continue

        # 2. 常见模式：带有省略号或快捷键标签
        cleaned = re.sub(r"[…\.]{1,3}$", "", v_str).strip()
        if cleaned in UI_DICTIONARY:
            suffix = "…" if ("…" in v_str or "..." in v_str) else ""
            trans_front[k] = UI_DICTIONARY[cleaned] + suffix
            matched += 1
            continue

        # 3. 常见首字母大写/小写转换
        if v_str.capitalize() in UI_DICTIONARY:
            trans_front[k] = UI_DICTIONARY[v_str.capitalize()]
            matched += 1
            continue

    print(f"Matched {matched} UI items via comprehensive dictionary!")
    print(f"Total available translated frontend items: {len(trans_front)}")

    f_all.write_text(json.dumps(trans_front, ensure_ascii=False, indent=2), encoding="utf-8")

if __name__ == "__main__":
    main()
