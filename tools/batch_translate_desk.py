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
    if re.fullmatch(r'[\{\}\<\>\s\d\.\,\:\;\-\_\/\\\|\@\#\$\%\^\&\*\(\)\+]+', text):
        return key, text
    prot, tokens = protect(text)
    url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=zh-CN&dt=t&q=" + urllib.parse.quote(prot)
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                res = "".join([item[0] for item in data[0] if item and item[0]])
                return key, restore(res, tokens)
        except Exception:
            time.sleep(0.3)
    return key, text

def main():
    missing_desk = json.loads(Path("missing_desk.json").read_text(encoding="utf-8"))
    print(f"Translating {len(missing_desk)} missing desktop items...")

    results = {}
    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = {executor.submit(translate_item, k, v): k for k, v in missing_desk.items()}
        completed = 0
        for f in as_completed(futures):
            k, trans = f.result()
            results[k] = trans
            completed += 1
            if completed % 50 == 0 or completed == len(missing_desk):
                print(f"Progress: {completed}/{len(missing_desk)}")

    Path("translated_desk.json").write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
    print("Desktop translation completed successfully!")

if __name__ == "__main__":
    main()
