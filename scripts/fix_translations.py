#!/usr/bin/env python3
"""
Fix remaining German translation issues - handle variable placeholders properly
"""
import json
import re

# Specific fixes for entries with variables
MANUAL_FIXES = {
    "Role: ${roles[index]}": "Rolle: ${roles[index]}",
    "Severity: $severity": "Schweregrad: $severity",
    "User: user_${index + 1}": "Benutzer: user_${index + 1}",
    "Fehlgeschlagen to save settings: $e": "Fehler beim Speichern der Einstellungen: $e",
    "By: ${_currentUser.suspendedBy}": "Von: ${_currentUser.suspendedBy}",
    "Reason: ${_currentUser.suspensionReason}": "Grund: ${_currentUser.suspensionReason}",
    "User type updated to ${newType.name}": "Benutzertyp aktualisiert auf ${newType.name}",
    "Are you sure you want to remove this profile Bild?": "Möchten Sie dieses Profilbild wirklich entfernen?",
    "Fehlgeschlagen to create coupon: {error}": "Fehler beim Erstellen des Gutscheins: {error}",
    "Fehlgeschlagen to update coupon: {error}": "Fehler beim Aktualisieren des Gutscheins: {error}",
    "Authentication fehlgeschlagen: ${message}": "Authentifizierung fehlgeschlagen: ${message}",
    "An unexpected Fehler occurred: ${error}": "Ein unerwarteter Fehler ist aufgetreten: ${error}",
}

# Additional translations needed
ADDITIONAL_TRANSLATIONS = [
    # Patterns with "Failed to" - translate properly
    (r'^Fehlgeschlagen to (.+): \$e$', r'Fehler beim \1: $e'),
    (r'^Fehlgeschlagen to (.+): \{error\}$', r'Fehler beim \1: {error}'),
    
    # Authentication errors
    (r'Authentication fehlgeschlagen', 'Authentifizierung fehlgeschlagen'),
    (r'unexpected Fehler occurred', 'unerwarteter Fehler ist aufgetreten'),
    
    # Common patterns
    (r'Are you sure you want to (.+) this (.+)\?', r'Möchten Sie dies\2 wirklich \1?'),
]

def fix_translation(value):
    """Fix partially translated or incorrectly translated values"""
    if not isinstance(value, str):
        return value
    
    # Direct replacements
    if value in MANUAL_FIXES:
        return MANUAL_FIXES[value]
    
    # Pattern-based fixes
    original = value
    
    # Fix common mistranslations
    value = value.replace("Fehlgeschlagen to", "Fehler beim")
    value = value.replace("fehlgeschlagen to", "Fehler beim")
    value = value.replace("Authentication fehlgeschlagen", "Authentifizierung fehlgeschlagen")
    value = value.replace("unexpected Fehler", "unerwarteter Fehler")
    value = value.replace("profile Bild", "Profilbild")
    
    # Fix verb forms
    replacements = {
        "to remove": "Entfernen",
        "to save": "Speichern",
        "to update": "Aktualisieren",
        "to create": "Erstellen",
        "to delete": "Löschen",
        "to load": "Laden",
        "to upload": "Hochladen",
        "to download": "Herunterladen",
    }
    
    for eng, ger in replacements.items():
        value = value.replace(eng, ger)
    
    return value

def main():
    input_file = '/Users/kristybock/artbeat/assets/translations/de.json'
    
    print("Loading de.json...")
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"Fixing translation issues...")
    
    fixed_count = 0
    
    for key, value in data.items():
        new_value = fix_translation(value)
        if new_value != value:
            data[key] = new_value
            fixed_count += 1
            print(f"  Fixed: {key}")
            print(f"    {value} -> {new_value}")
    
    print(f"\n{'='*60}")
    print(f"Fixed {fixed_count} translation issues")
    print(f"{'='*60}\n")
    
    print("Saving updated de.json...")
    with open(input_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("✓ Fixes applied!")

if __name__ == '__main__':
    main()
