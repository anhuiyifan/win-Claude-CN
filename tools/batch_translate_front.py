import json
import re
import urllib.request
import urllib.parse
import time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

PROTECTED_RE = re.compile(r'\{[^{}]+\}|<[^>]+>|`[^`]+`|https?://\S+')

def protect(text):
    tokens = []
    def repl(m):
        tokens.append(m.group(0))
        return f"___TOK_{len(tokens)-1}___"
    return PROTECTED_RE.sub(repl, text), tokens

def restore(text, tokens):
    for i, tok in enumerate(tokens):
        pat = re.compile(rf"___\s*TOK_\s*{i}\s*___", re.IGNORECASE)
        text = pat.sub(tok, text)
    return text

def translate_item(key, text):
    if not text.strip():
        return key, text
    # 纯数字、符号跳过
    if re.fullmatch(r'[\{\}\<\>\s\d\.\,\:\;\-\_\/\\\|\@\#\$\%\^\&\*\(\)\+]+', text):
        return key, text
    prot, tokens = protect(text)
    url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=zh-CN&dt=t&q=" + urllib.parse.quote(prot)
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=12) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                res = "".join([item[0] for item in data[0] if item and item[0]])
                return key, restore(res, tokens)
        except Exception:
            time.sleep(0.2)
    return key, text

def main():
    out_file = Path("translated_front_all.json")
    results = {}
    if out_file.exists():
        try:
            results = json.loads(out_file.read_text(encoding="utf-8"))
            print(f"Loaded existing translations: {len(results)}")
        except Exception:
            results = {}

    missing = json.loads(Path("missing_front.json").read_text(encoding="utf-8"))
    remaining = {k: v for k, v in missing.items() if k not in results}
    print(f"Total missing: {len(missing)}, Remaining to translate: {len(remaining)}")

    if not remaining:
        print("All items already translated!")
        return

    # 分批并发执行，每 500 条落盘保存一次
    batch_size = 500
    rem_items = list(remaining.items())

    for idx in range(0, len(rem_items), batch_size):
        chunk = dict(rem_items[idx:idx + batch_size])
        with ThreadPoolExecutor(max_workers=16) as executor:
            futures = {executor.submit(translate_item, k, v): k for k, v in chunk.items()}
            for f in as_completed(futures):
                k, trans = f.result()
                results[k] = trans

        out_file.write_text(json.dumps(results, ensure_ascii=False), encoding="utf-8")
        done = len(results)
        print(f"Progress: {done}/{len(missing)} ({done * 100 // len(missing)}%)")

    print("Frontend translation completed!")

if __name__ == "__main__":
    main()
