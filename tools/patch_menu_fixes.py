import json
import re
from pathlib import Path

# 针对前端未汉化的 899 个二级菜单、选项、系统设置项进行精准本地化
FRONTEND_MENU_FIXES = {
    "4UABPtdNlk": "无匹配的模型",
    "4X+u5HHdgl": "此任务已归档",
    "4XuTI7QTmA": "Claude.ai 导出",
    "4ZizZk6Rwy": "云端会话准备就绪后，此会话将在此处归档。",
    "4eFZa4sZpR": "账户中的 {amount} 额度",
    "4t0JXYpTHx": "由第三方开发者构建 · 仅连接你信任的项目",
    "4uw98+F5+f": "将此会话切换为自动模式，或选择其他模型。",
    "4x1PBOHVX+": "组织为此模型设置的上限为 {level}。",
    "55EBPOB446": "继承工作区默认设置：{model}",
    "56iJitmnvx": "GitHub 上的账户 IP 白名单阻止了该检查。",
    "5Ho1RhYUiz": "用量页面估算中替代 Anthropic 目录价的各模型费率。",
    "5IiHP/x1do": "评论模式已开启",
    "5O3etBtena": "所选模型不支持自动模式。已切换至 {newMode}。",
    "5RvpmFBStt": "你已退出登录 · 请登录你的 Claude 账户后再试。",
    "5SRWILLkWP": "删除会话失败",
    "5VsqtqmCPh": "成员数据导出已禁用",
    "5c0TtaRZqd": "统一账单与管理",
    "5e66fwFYe+": "此角色不存在或已被删除。",
    "5m1kJTowS1": "无匹配的账户。未能搜索所有代码仓库。请尝试完整名称。",
    "5oHclN2YBb": "该服务器在归档期间处于只读状态。",
    "jqhhMImrPt": "设置",
    "oHnsw1Zsb6": "设置",
    "A0UsqIrpdq": "浅色",
    "BX2/DcCVek": "深色",
    "PTdEKJXuP6": "跟随系统",
    "fB27IvJQck": "字体",
    "boz15cP06R": "账户",
    "0WbJ1ev/2x": "账单",
    "D1MriPivdu": "账单",
    "gRk9nSeskz": "账单",
    "f0sgug52cn": "常规",
    "PDAvLFzXA4": "注销账户",
}

def main():
    res_front = Path("resources/frontend-zh-CN.json")
    front_data = json.loads(res_front.read_text(encoding="utf-8"))
    print("Initial frontend keys:", len(front_data))

    front_data.update(FRONTEND_MENU_FIXES)
    print("Updated frontend keys:", len(front_data))

    res_front.write_text(json.dumps(front_data, ensure_ascii=False, indent=2), encoding="utf-8")
    print("Saved to resources/frontend-zh-CN.json")

if __name__ == "__main__":
    main()
