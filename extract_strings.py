import os
import re
import json

def extract_hardcoded_strings(directory):
    hardcoded = set()
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # Find all Text('string') or Text("string")
                    matches = re.findall(r"Text\(\s*['\"]([^'\"]*)['\"]\s*\)", content)
                    for match in matches:
                        string = match.strip()
                        # Check if the line contains .tr()
                        # Since the match is the string, check the context
                        # But to simplify, since we have the content, find the position
                        # For simplicity, if the string is not empty and not already in translated, add
                        # But to be accurate, find the full match and check after
                        # Let's find all Text( ... ) and check if .tr() is after
                        for m in re.finditer(r"Text\(\s*['\"]([^'\"]*)['\"]\s*\)", content):
                            string = m.group(1).strip()
                            end_pos = m.end()
                            # Check if .tr( follows
                            if end_pos < len(content) and content[end_pos:end_pos+4] == '.tr(':
                                continue
                            hardcoded.add(string)
                except Exception as e:
                    print(f"Error: {e}")
    
    return sorted(list(hardcoded))

if __name__ == "__main__":
    dirs = [
        "/workspaces/artbeat-app/packages/artbeat_core/lib/src/screens",
        "/workspaces/artbeat-app/packages/artbeat_core/lib/src/widgets"
    ]
    all_strings = set()
    for d in dirs:
        all_strings.update(extract_hardcoded_strings(d))
    
    print("Extracted strings:")
    for s in sorted(all_strings):
        print(repr(s))
    
    # Create JSON
    data = {}
    for s in all_strings:
        # Create key
        key = "art_walk_" + re.sub(r'[^a-zA-Z0-9]', '_', s).lower().strip('_')
        if key in data:
            i = 1
            while f"{key}_{i}" in data:
                i += 1
            key = f"{key}_{i}"
        data[key] = s
    
    with open("/workspaces/artbeat-app/packages/artbeat_core/artbeat_core_texts_data.json", "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    print(f"\nExtracted {len(all_strings)} unique strings")
    print("Created artbeat_core_texts_data.json")