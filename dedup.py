import os

# Deduplicate L10n.swift
l10n_path = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/Core/Localization/L10n.swift"
with open(l10n_path, "r") as f:
    lines = f.readlines()

out = []
seen = set()
current_enum = None

# Reverse traverse to keep bottom-most duplicates
lines.reverse()

for line in lines:
    if "{" in line and "}" not in line and "enum" not in line:
        # Just structural, ignore
        pass
    if "public enum" in line:
        current_enum = line.split("enum")[1].split("{")[0].strip()
        # Since we're going backwards, when we see 'public enum XYZ {',
        # we are exiting the enum. We clear the current_enum (not strictly necessary but safe).

    if "public static let" in line:
        # Since we don't have current_enum when going backwards until the very end of the block,
        # we need a different approach. Let's just traverse forwards instead, but for strings we go backwards.
        pass

# Let's do L10n.swift forwards, but just keep the first declaration we see since we injected at the TOP of the enum block.
with open(l10n_path, "r") as f:
    lines = f.readlines()

out = []
seen = set()
current_enum = None

for line in lines:
    if "public enum" in line:
        current_enum = line.split("enum")[1].split("{")[0].strip()
        
    if "public static let" in line:
        var_name = line.split("let")[1].split(":")[0].strip()
        identifier = f"{current_enum}.{var_name}"
        if identifier in seen:
            continue
        seen.add(identifier)
    out.append(line)

with open(l10n_path, "w") as f:
    f.writelines(out)

print("Deduplicated L10n.swift")

def dedup_strings(path):
    with open(path, "r") as f:
        lines = f.readlines()
    
    seen = set()
    out = []
    
    # Bottom up to keep newest translations
    for line in reversed(lines):
        if "=" in line and ";" in line and not line.strip().startswith("//"):
            key = line.split("=")[0].strip()
            if key in seen:
                continue
            seen.add(key)
        out.append(line)
        
    out.reverse()
    with open(path, "w") as f:
        f.writelines(out)

dedup_strings("/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/en.lproj/Localizable.strings")
dedup_strings("/Users/aplle/Desktop/swift learning/FinaLit/FinaLit/App/az.lproj/Localizable.strings")

print("Deduplicated Localizable.strings")
