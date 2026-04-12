import os
import re

ROOT = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Features/ProfileSettings"
symbols = ["safari", "book", "chevron.right", "checkmark.circle.fill", "target", "speedometer", "arrow.down", "pencil", "plus", "gearshape", "lock.fill", "play.circle.fill", "xmark.circle.fill", "star.fill", "arrow.right", "arrow.left", "book.closed", "text.book.closed", "exclamationmark.triangle.fill", "person.crop.circle", "bell", "shield", "globe", "moon", "sun.max", "trash", "power", "info.circle", "doc.text", "questionmark.circle", "arrow.up.right.square"]

unique = set()
for root, _, files in os.walk(ROOT):
    for f in files:
        if f.endswith(".swift"):
            path = os.path.join(root, f)
            with open(path, "r") as p:
                content = p.read()
            found = re.findall(r'"([^"\\]*?)"', content)
            for s in found:
                if len(s) > 1 and "." not in s and s not in symbols and '_' not in s and re.search(r'[A-Za-z]', s):
                    unique.add((f, s))

for f, s in sorted(list(unique), key=lambda x: x[0]):
    print(f"{f}: '{s}'")
