import os
import re
import json

ROOT_DIR = "/Users/aplle/Desktop/swift learning/FinaLit/FinaLit"

# Regex for finding hardcoded strings
# Matches: Component("Some String"
# We exclude strings with \( because formatting requires special LocalizedStringKey handling
pattern = re.compile(r'(Text|Button|Label|navigationTitle|TextField|Picker|Toggle|alert|actionSheet)\(\s*"([^"\\]+)"')

# Store mapping: string -> {"category": category, "key": key}
# Also store file replacements: file_path -> [(original_match_string, replacement)]
if os.path.exists("strings_extracted.json"):
    with open("strings_extracted.json", "r") as f:
        data = json.load(f)
        strings_map = data.get("strings", {})
        # Do not load file_replacements from old run since those were already applied!
        file_replacements = {}
else:
    strings_map = {}
    file_replacements = {}

categories = ["Common", "Auth", "Error", "Profile", "Onboarding", "Admin", "AiChat", "Main"]

def get_category(path):
    if "Features/Auth" in path: return "Auth"
    if "Features/ProfileSettings" in path: return "Profile"
    if "Features/Onboarding" in path: return "Onboarding"
    if "Features/Admin" in path: return "Admin"
    if "Features/AiChat" in path: return "AiChat"
    if "Features/Main" in path: return "Main"
    return "Common"

def to_camel_case(s):
    # Remove non-alphanumeric, convert first char of words to upper, except first word
    parts = re.sub(r'[^a-zA-Z0-9 ]', '', s).split()
    if not parts:
        return "empty"
    return parts[0].lower() + ''.join(word.capitalize() for word in parts[1:])

for root, _, files in os.walk(ROOT_DIR):
    for filename in files:
        if filename.endswith(".swift") and "L10n.swift" not in filename:
            filepath = os.path.join(root, filename)
            with open(filepath, "r") as f:
                content = f.read()
            
            matches = pattern.finditer(content)
            replacements = []
            
            for match in matches:
                full_match = match.group(0) # e.g. Text("Hello"
                component = match.group(1) # e.g. Text
                string_val = match.group(2) # e.g. Hello
                
                # We skip very short/emoji strings or empty strings sometimes?
                if not string_val.strip(): continue
                # Skip emojis (rough check)
                if len(string_val) == 1 and ord(string_val[0]) > 1000: continue
                
                if string_val not in strings_map:
                    cat = get_category(filepath)
                    key = to_camel_case(string_val)
                    
                    # Ensure unique key in category
                    base_key = key
                    idx = 2
                    existing_keys = [v["key"] for v in strings_map.values() if v["category"] == cat]
                    while key in existing_keys:
                        key = f"{base_key}{idx}"
                        idx += 1
                        
                    strings_map[string_val] = {
                        "category": cat,
                        "key": key,
                        "original": string_val
                    }
                
                cat = strings_map[string_val]["category"]
                key = strings_map[string_val]["key"]
                
                replacement = f'{component}(L10n.{cat}.{key}'
                replacements.append({
                    "original_match": full_match,
                    "component": component,
                    "string_val": string_val,
                    "replacement": replacement
                })
                
            if replacements:
                file_replacements[filepath] = replacements

# Write out the maps for validation
with open("strings_extracted.json", "w") as f:
    json.dump({
        "strings": strings_map,
        "files": file_replacements
    }, f, indent=2)

print(f"Extracted {len(strings_map)} unique strings from {len(file_replacements)} files.")
