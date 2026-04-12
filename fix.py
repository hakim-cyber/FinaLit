import os
import re

ROOT_DIR = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit"

replacements = {
    "L10n.Profile.continue": "L10n.Profile.continueAction",
    "L10n.Profile.0": "L10n.Profile.zero",
    "L10n.Main.5000": "L10n.Main.num5000",
    "profile.continue": "profile.continueAction",
    "profile.0": "profile.zero",
    "main.5000": "main.num5000"
}

def fix_content(content):
    # Safe boundary replacements for Swift struct names and string indices
    # We must be careful not to just replace any "main.5000" in string, but wait, those exact strings are unique enough.
    
    # Fix L10n.Profile.continue
    # Using regex to ensure word boundary
    content = re.sub(r'\bL10n\.Profile\.continue\b', 'L10n.Profile.continueAction', content)
    content = re.sub(r'\bL10n\.Profile\.0\b', 'L10n.Profile.zero', content)
    content = re.sub(r'\bL10n\.Main\.5000\b', 'L10n.Main.num5000', content)
    
    # Fix keys in Localizable.strings and L10n.swift strings
    content = content.replace('"profile.continue"', '"profile.continueAction"')
    content = content.replace('"profile.0"', '"profile.zero"')
    content = content.replace('"main.5000"', '"main.num5000"')
    
    # Fix enum property names
    content = re.sub(r'\bpublic static let continue:', 'public static let continueAction:', content)
    content = re.sub(r'\bpublic static let 0:', 'public static let zero:', content)
    content = re.sub(r'\bpublic static let 5000:', 'public static let num5000:', content)
    
    return content

modified_count = 0
for root, _, files in os.walk(ROOT_DIR):
    for filename in files:
        if filename.endswith(".swift") or filename == "Localizable.strings":
            filepath = os.path.join(root, filename)
            with open(filepath, "r") as f:
                content = f.read()
                
            new_content = fix_content(content)
            
            if content != new_content:
                with open(filepath, "w") as f:
                    f.write(new_content)
                modified_count += 1

print(f"Fixed invalid Swift keywords in {modified_count} files.")
