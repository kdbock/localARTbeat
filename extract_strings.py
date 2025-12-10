import os
import re
import json

def extract_hardcoded_strings(directory):
    hardcoded = set()
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Find all Text( followed by 'string' not followed by .tr()
                # Pattern: Text\('([^']+)'\)(?!\.tr\(\))
                matches = re.findall(r"Text\(\s*'([^']+)'\s*\)(?!\.tr\(\))", content)
                for match in matches:
                    hardcoded.add(match.strip())
                
                # Also find const Text('string')
                const_matches = re.findall(r"const Text\(\s*'([^']+)'\s*\)", content)
                for match in const_matches:
                    hardcoded.add(match.strip())
    
    return sorted(list(hardcoded))

if __name__ == "__main__":
    directory = "/workspaces/artbeat-app/packages/artbeat_art_walk/lib/src"
    strings = extract_hardcoded_strings(directory)
    
    # Create JSON
    data = {}
    for i, s in enumerate(strings):
        key = f"art_walk_{s.lower().replace(' ', '_').replace('(', '').replace(')', '').replace('<', '').replace('>', '').replace(':', '').replace(',', '').replace('.', '').replace('?', '').replace('!', '').replace('-', '_').replace('/', '_').replace('\'', '').replace('"', '')}_{i}"
        data[key] = s
    
    with open("/workspaces/artbeat-app/artbeat_art_walk_texts_data.json", "w") as f:
        json.dump(data, f, indent=2)
    
    print(f"Extracted {len(strings)} strings")
    print("Created artbeat_art_walk_texts_data.json")