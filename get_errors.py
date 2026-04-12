import subprocess

print("Running xcodebuild...")
result = subprocess.run(["xcodebuild", "-scheme", "FinaLit", "-destination", "generic/platform=iOS", "build"], capture_output=True, text=True)

errors = []
for line in result.stdout.split('\n'):
    if "error:" in line or "note:" in line:
        errors.append(line)

print("ERRORS FOUND:")
for e in errors[:30]:
    print(e)
