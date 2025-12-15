#!/usr/bin/env python3
"""
French Translation - Comprehensive Script
Handles all common patterns including "Failed to" and "Error" messages
"""

import json
import re
from pathlib import Path

FR_JSON_PATH = Path(__file__).parent.parent / 'assets' / 'translations' / 'fr.json'

def smart_translate(text):
    """Apply smart pattern-based translations"""
    
    # Pattern 1: "Failed to [action]: $e" or "Failed to [action]"
    pattern = r'^Failed to (.+?)(?:: (.+))?$'
    match = re.match(pattern, text)
    if match:
        action = match.group(1)
        error_part = match.group(2) if match.group(2) else ""
        
        # Common action translations
        action_map = {
            'load': 'charger',
            'save': 'enregistrer',
            'delete': 'supprimer',
            'update': 'mettre à jour',
            'create': 'créer',
            'send': 'envoyer',
            'upload': 'télécharger',
            'download': 'télécharger',
            'approve': 'approuver',
            'reject': 'rejeter',
            'block': 'bloquer',
            'unblock': 'débloquer',
            'post': 'publier',
            'clear': 'effacer',
            'remove': 'retirer',
            'add': 'ajouter',
            'start': 'démarrer',
            'stop': 'arrêter',
            'get': 'obtenir',
            'fetch': 'récupérer',
        }
        
        french_action = action
        for eng, fr in action_map.items():
            if action.lower().startswith(eng):
                remaining = action[len(eng):].strip()
                french_action = fr + (' ' + remaining if remaining else '')
                break
        
        if error_part:
            return f"Échec de {french_action}: {error_part}"
        else:
            return f"Échec de {french_action}"
    
    # Pattern 2: "Error [action]ing [object]: $e"
    pattern = r'^Error (.+?)(?:: (.+))?$'
    match = re.match(pattern, text)
    if match:
        detail = match.group(1)
        error_var = match.group(2) if match.group(2) else ""
        
        if error_var:
            return f"Erreur {detail}: {error_var}"
        else:
            return f"Erreur {detail}"
    
    # Pattern 3: "[Action]ing..." (progressive form)
    if text.endswith('...'):
        base = text[:-3]
        if base.endswith('ing'):
            action_root = base[:-3]
            action_map = {
                'Load': 'Chargement',
                'Sav': 'Enregistrement',
                'Delet': 'Suppression',
                'Updat': 'Mise à jour',
                'Creat': 'Création',
                'Send': 'Envoi',
                'Upload': 'Téléchargement',
                'Process': 'Traitement',
                'Approv': 'Approbation',
            }
            for eng, fr in action_map.items():
                if action_root.startswith(eng):
                    return f"{fr}..."
    
    return None

def translate_comprehensive():
    """Apply comprehensive French translations"""
    print(f"{'='*70}")
    print(f"French Translation - Comprehensive Pass")
    print(f"{'='*70}\n")
    
    with open(FR_JSON_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    remaining = [(k, v) for k, v in data.items() if isinstance(v, str) and v.startswith('[') and v.endswith(']')]
    print(f"Starting with {len(remaining)} bracketed entries\n")
    
    count = 0
    pattern_count = 0
    
    for key, value in list(data.items()):
        if not isinstance(value, str) or not (value.startswith('[') and value.endswith(']')):
            continue
        
        content = value[1:-1]  # Remove brackets
        
        # Try pattern matching
        result = smart_translate(content)
        if result:
            data[key] = result
            count += 1
            pattern_count += 1
            if count <= 100:
                print(f"✓ [{content[:50]}] → {result[:50]}")
    
    # Save
    with open(FR_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    remaining_after = [(k, v) for k, v in data.items() if isinstance(v, str) and v.startswith('[') and v.endswith(']')]
    
    print(f"\n{'='*70}")
    print(f"COMPREHENSIVE PASS SUMMARY")
    print(f"{'='*70}")
    print(f"Pattern translations: {pattern_count}")
    print(f"Remaining: {len(remaining_after)}")
    print(f"✓ File saved: {FR_JSON_PATH}")
    
    total_translated = 1397 - len(remaining_after)
    percentage = (total_translated / 1397) * 100
    print(f"📊 Total progress: {total_translated}/1397 ({percentage:.1f}%)")
    print(f"{'='*70}\n")

if __name__ == "__main__":
    translate_comprehensive()
