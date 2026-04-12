import os
import re

ROOT = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Features/AiChat"
symbols = ["safari", "book", "chevron.right", "checkmark.circle.fill", "target", "speedometer", "arrow.down", "pencil", "plus", "gearshape", "lock.fill", "play.circle.fill", "xmark.circle.fill", "star.fill", "arrow.right", "arrow.left", "book.closed", "text.book.closed", "exclamationmark.triangle.fill", "sparkles", "arrow.up", "ellipsis", "doc.text.fill", "chart.pie.fill", "briefcase.fill", "bubble.left.and.bubble.right.fill", "xmark"]

unique = set()
for root, _, files in os.walk(ROOT):
    for f in files:
        if f.endswith(".swift"):
            path = os.path.join(root, f)
            with open(path, "r") as p:
                content = p.read()
            found = re.findall(r'"([^"\\]*?)"', content)
            for s in found:
                if len(s) > 1 and s not in symbols and '_' not in s and re.search(r'[A-Za-z]', s):
                    unique.add((f, s))

for f, s in sorted(list(unique), key=lambda x: x[0]):
    print(f"{f}: '{s}'")
