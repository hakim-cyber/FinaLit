import os

for lang in ["en", "az"]:
    path = f"/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/{lang}.lproj/Localizable.strings"
    with open(path, "r") as f:
        content = f.read()
    
    content = content.replace('"aichat.tryExample" = "Try: "Why am I overspending this month?"";', '"aichat.tryExample" = "Try: \\"Why am I overspending this month?\\"";')
    content = content.replace('"aichat.orExample" = "Or: "Which goal should I focus on first?"";', '"aichat.orExample" = "Or: \\"Which goal should I focus on first?\\"";')
    content = content.replace('"aichat.tryExample" = "Yoxlayın: "Niyə bu ay büdcəmi aşıram?"";', '"aichat.tryExample" = "Yoxlayın: \\"Niyə bu ay büdcəmi aşıram?\\"";')
    content = content.replace('"aichat.orExample" = "Və ya: "Hansı hədəfə öncəlik verməliyəm?"";', '"aichat.orExample" = "Və ya: \\"Hansı hədəfə öncəlik verməliyəm?\\"";')

    with open(path, "w") as f:
        f.write(content)
print("Fix executed")
