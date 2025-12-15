#!/usr/bin/env python3
"""
Final comprehensive fix for all partial translations in de.json
"""
import json
import re

def comprehensive_fix(value):
    """Apply comprehensive fixes to partially translated strings"""
    if not isinstance(value, str):
        return value
    
    original = value
    
    # Fix "Fehler beim X" patterns - need proper German nouns
    fixes_map = {
        "remove profile image": "Entfernen des Profilbilds",
        "update profile": "Aktualisieren des Profils",
        "update featured status": "Aktualisieren des Featured-Status",
        "update user type": "Aktualisieren des Benutzertyps",
        "update verification status": "Aktualisieren des Verifizierungsstatus",
        "check migration status": "Überprüfen des Migrationsstatus",
        "load migration status": "Laden des Migrationsstatus",
        "approve content": "Genehmigen des Inhalts",
        "clear review": "Löschen der Überprüfung",
        "delete content": "Löschen des Inhalts",
        "reject content": "Ablehnen des Inhalts",
        "update content": "Aktualisieren des Inhalts",
        "post ad": "Veröffentlichen der Anzeige",
        "upload image": "Hochladen des Bildes",
        "post achievement": "Veröffentlichen des Erfolgs",
        "start navigation": "Starten der Navigation",
        "save review": "Speichern der Bewertung",
        "load artists": "Laden der Künstler",
        "cancel invitation": "Stornieren der Einladung",
        "remove artist from gallery": "Entfernen des Künstlers aus der Galerie",
        "resend invitation": "Erneutes Senden der Einladung",
        "send invitation": "Senden der Einladung",
        "delete artwork": "Löschen des Kunstwerks",
        "approve capture": "Genehmigen des Captures",
        "clear reports": "Löschen der Berichte",
        "delete capture": "Löschen des Captures",
        "reject capture": "Ablehnen des Captures",
        "update capture": "Aktualisieren des Captures",
        "get location": "Abrufen des Standorts",
        "report user": "Melden des Benutzers",
        "send message": "Senden der Nachricht",
        "send image": "Senden des Bildes",
        "send voice message": "Senden der Sprachnachricht",
        "delete chat": "Löschen des Chats",
        "archive chat": "Archivieren des Chats",
        "restore chat": "Wiederherstellen des Chats",
        "clear chat": "Löschen des Chats",
        "create group": "Erstellen der Gruppe",
        "load contacts": "Laden der Kontakte",
        "load messages": "Laden der Nachrichten",
        "download media": "Herunterladen der Medien",
        "send reply": "Senden der Antwort",
        "block user": "Blockieren des Benutzers",
        "unblock user": "Entsperren des Benutzers",
        "mute chat": "Stummschalten des Chats",
        "unmute chat": "Stummschaltung des Chats aufheben",
        "pin chat": "Anheften des Chats",
        "unpin chat": "Lösen des Chats",
        "mark as read": "Als gelesen markieren",
        "load user": "Laden des Benutzers",
        "search users": "Suchen von Benutzern",
        "load more": "Mehr laden",
        "refresh": "Aktualisieren",
    }
    
    # Apply fixes
    for eng, ger in fixes_map.items():
        value = value.replace(f"Fehler beim {eng}", f"Fehler beim {ger}")
        value = value.replace(f"Failed {eng}", f"Fehler beim {ger}")
        value = value.replace(f"Unable {eng}", f"Nicht möglich, {ger}")
        value = value.replace(f"Failed to {eng}", f"Fehler beim {ger}")
        value = value.replace(f"Unable to {eng}", f"Nicht möglich, {ger}")
    
    # Fix common partial translations
    value = value.replace("Are you sure you want Löschen", "Möchten Sie dies wirklich löschen")
    value = value.replace("Are you sure you want Entfernen", "Möchten Sie dies wirklich entfernen")
    value = value.replace("Unable Laden", "Laden nicht möglich")
    value = value.replace("Failed Erstellen", "Fehler beim Erstellen")
    value = value.replace("Failed Laden", "Fehler beim Laden")
    
    # Fix "to load/create/etc" patterns
    value = re.sub(r'to (\w+)', lambda m: translate_infinitive(m.group(1)), value)
    
    return value

def translate_infinitive(verb):
    """Translate English infinitive verbs to German"""
    translations = {
        'load': 'Laden',
        'save': 'Speichern',
        'delete': 'Löschen',
        'create': 'Erstellen',
        'update': 'Aktualisieren',
        'remove': 'Entfernen',
        'add': 'Hinzufügen',
        'edit': 'Bearbeiten',
        'upload': 'Hochladen',
        'download': 'Herunterladen',
        'send': 'Senden',
        'receive': 'Empfangen',
        'post': 'Veröffentlichen',
        'share': 'Teilen',
        'like': 'Liken',
        'comment': 'Kommentieren',
        'follow': 'Folgen',
        'unfollow': 'Entfolgen',
        'block': 'Blockieren',
        'unblock': 'Entsperren',
        'report': 'Melden',
        'archive': 'Archivieren',
        'restore': 'Wiederherstellen',
        'search': 'Suchen',
        'filter': 'Filtern',
        'sort': 'Sortieren',
    }
    return translations.get(verb, verb)

def main():
    input_file = '/Users/kristybock/artbeat/assets/translations/de.json'
    
    print("Loading de.json...")
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"Applying comprehensive fixes...")
    
    fixed_count = 0
    
    for key, value in data.items():
        new_value = comprehensive_fix(value)
        if new_value != value:
            data[key] = new_value
            fixed_count += 1
            if fixed_count <= 30:  # Show first 30
                print(f"  {key}:")
                print(f"    {value}")
                print(f"    -> {new_value}")
    
    print(f"\n{'='*60}")
    print(f"Fixed {fixed_count} entries")
    print(f"{'='*60}\n")
    
    print("Saving updated de.json...")
    with open(input_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("✓ All fixes applied!")

if __name__ == '__main__':
    main()
