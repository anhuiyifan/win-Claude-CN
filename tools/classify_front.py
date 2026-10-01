import json
import re
from pathlib import Path

def main():
    front_missing = json.loads(Path("missing_front.json").read_text(encoding="utf-8"))
    print("Total missing frontend keys:", len(front_missing))

    # 分类：短文本（菜单、按钮、标题、标签，通常 <= 60 字符且不含换行）
    short_items = {}
    long_items = {}

    for k, v in front_missing.items():
        if len(v) <= 60 and "\n" not in v:
            short_items[k] = v
        else:
            long_items[k] = v

    print(f"Short UI elements (menus, buttons, tabs, labels): {len(short_items)}")
    print(f"Long text (paragraphs, error messages, legal text): {len(long_items)}")

    Path("short_front_items.json").write_text(json.dumps(short_items, ensure_ascii=False, indent=2), encoding="utf-8")
    Path("long_front_items.json").write_text(json.dumps(long_items, ensure_ascii=False, indent=2), encoding="utf-8")

if __name__ == "__main__":
    main()
