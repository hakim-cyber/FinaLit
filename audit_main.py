import os
import re

ROOT = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Features/Main"

# Basic list of sf symbols to ignore
symbols = ["checkmark.circle.fill", "target", "speedometer", "arrow.down", "pencil", "plus", "gearshape"]

for root, _, files in os.walk(ROOT):
    for f in files:
        if f.endswith(".swift"):
            path = os.path.join(root, f)
            with open(path, "r") as p:
                content = p.read()
            # find all string literals using regex
            # handles "something" and also multi-line (but we only care about simple)
            strings = re.findall(r'"([^"\\]*?)"', content)
            unique_strings = set(strings)
            for s in unique_strings:
                if len(s) > 1 and not s.startswith("main.") and not s.startswith("profile.") and not s.startswith("common.") and s not in symbols and '_' not in s and re.search(r'[A-Za-z]', s):
                    # print only if it looks like a real phrase
                    print(f"{f}: '{s}'")
