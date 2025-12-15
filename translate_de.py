#!/usr/bin/env python3
"""
Script to translate English placeholders in de.json to German
"""
import json
import re

# German translations mapping
translations = {
    # Common UI
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
    
    # Security Center
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
    
    # Settings
    "Failed to save settings: $e": "Fehler beim Speichern der Einstellungen: $e",
    "Backup created successfully": "Sicherung erfolgreich erstellt",
    "Cache cleared successfully": "Cache erfolgreich gelöscht",
    "Settings reset successfully": "Einstellungen erfolgreich zurückgesetzt",
    "Settings saved successfully": "Einstellungen erfolgreich gespeichert",
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
    
    # System Monitoring
    "Error loading system data: $e": "Fehler beim Laden der Systemdaten: $e",
    
    # User Details
    "Failed to remove profile image: $e": "Fehler beim Entfernen des Profilbilds: $e",
    "Failed to update profile: $e": "Fehler beim Aktualisieren des Profils: $e",
    "Failed to update featured status: $e": "Fehler beim Aktualisieren des Featured-Status: $e",
    "Failed to update user type: $e": "Fehler beim Aktualisieren des Benutzertyps: $e",
    "Failed to update verification status: $e": "Fehler beim Aktualisieren des Verifizierungsstatus: $e",
    "Profile image removed successfully": "Profilbild erfolgreich entfernt",
    "User profile updated successfully": "Benutzerprofil erfolgreich aktualisiert",
    "Edit Profile": "Profil bearbeiten",
    "Featured": "Empfohlen",
    "Remove Profile Image": "Profilbild entfernen",
    "Save Changes": "Änderungen speichern",
    "User Details": "Benutzerdetails",
    "Verified": "Verifiziert",
    
    # Coupons
    "Create New Coupon": "Neuen Gutschein erstellen",
    "Edit Coupon": "Gutschein bearbeiten",
    "Failed to create coupon: {error}": "Fehler beim Erstellen des Gutscheins: {error}",
    "Failed to update coupon: {error}": "Fehler beim Aktualisieren des Gutscheins: {error}",
    "Coupon created successfully": "Gutschein erfolgreich erstellt",
    "Coupon updated successfully": "Gutschein erfolgreich aktualisiert",
    
    # Admin Navigation
    "Art Walk Moderation": "Art Walk-Moderation",
    "Moderate art walks and manage reports": "Art Walks moderieren und Berichte verwalten",
    "Capture Moderation": "Capture-Moderation",
    "Moderate captures and manage reports": "Captures moderieren und Berichte verwalten",
    "Coupon Management": "Gutscheinverwaltung",
    "Create and manage discount coupons": "Rabattgutscheine erstellen und verwalten",
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
    
    # Login
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

def translate_value(value):
    """Translate a value if it's an English placeholder"""
    if not isinstance(value, str):
        return value
    
    # Check if it's a bracketed placeholder
    if value.startswith('[') and value.endswith(']'):
        # Remove brackets
        inner = value[1:-1]
        
        # Direct translation lookup
        if inner in translations:
            return translations[inner]
        
        # Handle special cases with variables
        # Keep variable placeholders intact
        for eng, ger in translations.items():
            if eng == inner:
                return ger
        
        # If no translation found, return without brackets (assume it's technical like IP)
        # But keep user-facing text
        if any(char.isalpha() for char in inner) and not inner.replace('.', '').replace('/', '').replace('0', '').replace(':', '').isdigit():
            # Has letters, likely needs translation
            # Try partial matches
            for eng, ger in translations.items():
                if eng.replace('$e', '').strip() in inner or inner.replace('$e', '').strip() in eng:
                    # Variable substitution
                    result = ger
                    # Preserve any $ or {} variables
                    for var in re.findall(r'\$\w+|\$\{[^}]+\}|\{[^}]+\}', inner):
                        result = result.replace(eng.split(var)[0] if var in eng else '', inner.split(var)[0] if var in inner else '')
                    return result
            
            # Return as-is for now, will need manual review
            return value
        else:
            # Technical value like IP, remove brackets
            return inner
    
    return value

def main():
    # Load the de.json file
    with open('/Users/kristybock/artbeat/assets/translations/de.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Translate all bracketed values
    count = 0
    for key, value in data.items():
        new_value = translate_value(value)
        if new_value != value:
            data[key] = new_value
            count += 1
            if count <= 10:  # Show first 10 changes
                print(f"{key}: {value} -> {new_value}")
    
    print(f"\nTotal translations: {count}")
    
    # Save the updated file
    with open('/Users/kristybock/artbeat/assets/translations/de.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("Translation complete!")

if __name__ == '__main__':
    main()
