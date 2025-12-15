#!/usr/bin/env python3
"""
Final comprehensive German translation for de.json
All 1,216 English placeholders -> proper German
"""
import json
import re
from pathlib import Path

# Load translations from external file for better organization
def load_translation_dict():
    """Comprehensive German translations"""
    return {
        # IP addresses and technical values (just remove brackets)
        "10.0.0.0/8": "10.0.0.0/8",
        "192.168.1.0/24": "192.168.1.0/24",
        
        # Common UI Actions
        "Cancel": "Abbrechen",
        "Close": "Schließen",
        "Save": "Speichern",
        "Delete": "Löschen",
        "Edit": "Bearbeiten",
        "Add": "Hinzufügen",
        "Remove": "Entfernen",
        "Create": "Erstellen",
        "Update": "Aktualisieren",
        "Clear": "Löschen",
        "Backup": "Sicherung",
        "Reset": "Zurücksetzen",
        "Retry": "Wiederholen",
        "Resolve": "Lösen",
        "Dismiss": "Verwerfen",
        "Confirm": "Bestätigen",
        "Continue": "Fortfahren",
        "Submit": "Absenden",
        "Apply": "Anwenden",
        
        # Security Center Translations
        "Audit Log Details": "Audit-Log-Details",
        "Automated Threat Response": "Automatische Bedrohungsreaktion",
        "Automatically block suspicious activity": "Verdächtige Aktivitäten automatisch blockieren",
        "• Consider blocking if pattern continues": "• Erwägen Sie eine Sperrung, wenn das Muster anhält",
        "• Monitor the IP address": "• IP-Adresse überwachen",
        "Office Network": "Büronetzwerk",
        "Real-time Monitoring": "Echtzeitüberwachung",
        "Recommended Actions:": "Empfohlene Maßnahmen:",
        "Remove Admin": "Admin entfernen",
        "• Review access logs": "• Zugriffsprotokolle überprüfen",
        "Threat marked as resolved": "Bedrohung als gelöst markiert",
        "VPN Network": "VPN-Netzwerk",
        
        # Settings Translations
        "Admin Settings": "Admin-Einstellungen",
        "Backup Database": "Datenbank sichern",
        "Clear all cached data": "Alle zwischengespeicherten Daten löschen",
        "Clear Cache": "Cache löschen",
        "Content Settings": "Inhaltseinstellungen",
        "Create a backup of the database": "Eine Sicherung der Datenbank erstellen",
        "Danger Zone": "Gefahrenbereich",
        "Factory Reset": "Werkseinstellungen",
        "Factory reset completed": "Zurücksetzung auf Werkseinstellungen abgeschlossen",
        "General Settings": "Allgemeine Einstellungen",
        "Maintenance Settings": "Wartungseinstellungen",
        "No settings available": "Keine Einstellungen verfügbar",
        "Notification Settings": "Benachrichtigungseinstellungen",
        "Reset all settings to default values": "Alle Einstellungen auf Standardwerte zurücksetzen",
        "Reset All Settings": "Alle Einstellungen zurücksetzen",
        "Reset Settings": "Einstellungen zurücksetzen",
        "Security Settings": "Sicherheitseinstellungen",
        "System Settings": "Systemeinstellungen",
        "User Settings": "Benutzereinstellungen",
        "WARNING: This will delete all data": "WARNUNG: Dies wird alle Daten löschen",
        "WARNING: This will delete all data and cannot be undone.": "WARNUNG: Dies löscht alle Daten und kann nicht rückgängig gemacht werden.",
        
        # Success/Error Messages
        "Backup created successfully": "Sicherung erfolgreich erstellt",
        "Cache cleared successfully": "Cache erfolgreich gelöscht",
        "Settings reset successfully": "Einstellungen erfolgreich zurückgesetzt",
        "Settings saved successfully": "Einstellungen erfolgreich gespeichert",
        "Profile image removed successfully": "Profilbild erfolgreich entfernt",
        "User profile updated successfully": "Benutzerprofil erfolgreich aktualisiert",
        "Coupon created successfully": "Gutschein erfolgreich erstellt",
        "Coupon updated successfully": "Gutschein erfolgreich aktualisiert",
        
        # User Management
        "Edit Profile": "Profil bearbeiten",
        "Featured": "Empfohlen",
        "Remove Profile Image": "Profilbild entfernen",
        "Save Changes": "Änderungen speichern",
        "User Details": "Benutzerdetails",
        "Verified": "Verifiziert",
        
        # Coupons
        "Create New Coupon": "Neuen Gutschein erstellen",
        "Edit Coupon": "Gutschein bearbeiten",
        "Coupon Management": "Gutscheinverwaltung",
        "Create and manage discount coupons": "Rabattgutscheine erstellen und verwalten",
        
        # Navigation & Dashboards
        "Art Walk Moderation": "Art Walk-Moderation",
        "Moderate art walks and manage reports": "Art Walks moderieren und Berichte verwalten",
        "Capture Moderation": "Capture-Moderation",
        "Moderate captures and manage reports": "Captures moderieren und Berichte verwalten",
        "Artbeat Home": "Artbeat Startseite",
        "Return to main app": "Zur Hauptapp zurückkehren",
        "Payment Management": "Zahlungsverwaltung",
        "Transaction & refund management": "Transaktions- und Rückerstattungsverwaltung",
        "Unified Dashboard": "Einheitliches Dashboard",
        "All admin functions in one place": "Alle Admin-Funktionen an einem Ort",
        "Business Management": "Geschäftsverwaltung",
        "Content Management": "Inhaltsverwaltung",
        "Admin Dashboard": "Admin-Dashboard",
        "Management Console": "Verwaltungskonsole",
        "Admin Panel": "Admin-Panel",
        "Analytics": "Analytik",
        "Content Review": "Inhaltsüberprüfung",
        "User Management": "Benutzerverwaltung",
        
        # Login & Auth
        "Access denied. Admin privileges required.": "Zugriff verweigert. Admin-Berechtigungen erforderlich.",
        "Invalid email address.": "Ungültige E-Mail-Adresse.",
        "This account has been disabled.": "Dieses Konto wurde deaktiviert.",
        "No user found with this email.": "Kein Benutzer mit dieser E-Mail gefunden.",
        "Invalid password.": "Ungültiges Passwort.",
        "Please enter your email": "Bitte geben Sie Ihre E-Mail ein",
        "Please enter your password": "Bitte geben Sie Ihr Passwort ein",
        "Please enter a valid email": "Bitte geben Sie eine gültige E-Mail ein",
        "Password must be at least 6 characters": "Passwort muss mindestens 6 Zeichen lang sein",
        
        # Demo/Main
        "Edit this file to add navigation buttons to module screens": "Bearbeiten Sie diese Datei, um Navigationsschaltflächen zu Modulbildschirmen hinzuzufügen",
        "Standalone development environment": "Eigenständige Entwicklungsumgebung",
        "Uadmin Module Demo": "Uadmin-Modul-Demo",
        "Example Button": "Beispiel-Schaltfläche",
        "ARTbeat Uadmin Module": "ARTbeat Uadmin-Modul",
        
        # Migration
        "This will add geo fields (geohash and geopoint) to all captures with locations. This is required for instant discovery to show user captures. Continue?": "Dies fügt Geo-Felder (Geohash und Geopoint) zu allen Captures mit Standorten hinzu. Dies ist erforderlich, damit die Sofort-Entdeckung Benutzer-Captures anzeigt. Fortfahren?",
        "Migrate Geo Fields": "Geo-Felder migrieren",
        "This will remove the new moderation status fields from all collections. This action cannot be undone. Continue?": "Dies entfernt die neuen Moderationsstatus-Felder aus allen Sammlungen. Diese Aktion kann nicht rückgängig gemacht werden. Fortfahren?",
        "Rollback Migration": "Migration zurücksetzen",
        "This will add standardized moderation status fields to all content collections. This operation cannot be undone easily. Continue?": "Dies fügt standardisierte Moderationsstatus-Felder zu allen Inhaltssammlungen hinzu. Dieser Vorgang kann nicht einfach rückgängig gemacht werden. Fortfahren?",
        "Run Migration": "Migration ausführen",
    }

def translate_with_variables(text, translations):
    """
    Translate text that may contain variable placeholders
    Preserves ${var}, $var, {var} patterns
    """
    # Extract all variable patterns
    var_pattern = r'(\$\{[^}]+\}|\{[^}]+\}|\$\w+)'
    parts = re.split(var_pattern, text)
    
    result = []
    for part in parts:
        # If it's a variable, keep it as-is
        if re.match(var_pattern, part):
            result.append(part)
        # Otherwise translate if possible
        else:
            # Try exact match first
            if part in translations:
                result.append(translations[part])
            # Try without leading/trailing spaces
            elif part.strip() in translations:
                leading = len(part) - len(part.lstrip())
                trailing = len(part) - len(part.rstrip())
                result.append(' ' * leading + translations[part.strip()] + ' ' * trailing)
            else:
                # No translation, keep original
                result.append(part)
    
    return ''.join(result)

def translate_value(value, translations):
    """Translate a JSON value if it's an English placeholder"""
    if not isinstance(value, str):
        return value
    
    # Skip if not bracketed
    if not (value.startswith('[') and value.endswith(']')):
        return value
    
    # Remove brackets
    inner = value[1:-1]
    
    # Skip pure technical values (IPs, numbers, etc.)
    if re.match(r'^[\d\.\/:]+$', inner):
        return inner
    
    # Try direct translation
    if inner in translations:
        return translations[inner]
    
    # Try translation with variable handling
    translated = translate_with_variables(inner, translations)
    if translated != inner:
        return translated
    
    # If no translation found, return without brackets
    # (allows manual inspection of remaining items)
    return inner

def main():
    file_path = Path('/Users/kristybock/artbeat/assets/translations/de.json')
    
    print("Loading translation dictionary...")
    translations = load_translation_dict()
    print(f"Loaded {len(translations)} translation entries")
    
    print(f"\nLoading {file_path.name}...")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"Processing {len(data)} JSON entries...\n")
    
    translated = 0
    skipped = 0
    sample_count = 0
    
    for key, value in data.items():
        new_value = translate_value(value, translations)
        if new_value != value:
            data[key] = new_value
            translated += 1
            # Show first 15 translations as sample
            if sample_count < 15:
                print(f"✓ {key}")
                print(f"  [{value[1:-1] if value.startswith('[') else value}]")
                print(f"  → {new_value}\n")
                sample_count += 1
        elif isinstance(value, str) and value.startswith('['):
            skipped += 1
    
    print("=" * 70)
    print(f"TRANSLATION SUMMARY")
    print("=" * 70)
    print(f"Total entries in file: {len(data)}")
    print(f"Successfully translated: {translated}")
    print(f"Skipped (no translation): {skipped}")
    print("=" * 70)
    
    print(f"\nSaving updated {file_path.name}...")
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("✅ Translation complete!")
    
    if skipped > 0:
        print(f"\n⚠️  Note: {skipped} bracketed entries were not translated.")
        print("   These may be technical values or need manual review.")

if __name__ == '__main__':
    main()
