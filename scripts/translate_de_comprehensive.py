#!/usr/bin/env python3
"""
Comprehensive German translation script for de.json
Translates all [English] placeholders to proper German
"""
import json
import re

# Comprehensive German translation dictionary
TRANSLATIONS = {
    # Common Actions/Buttons
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
    "View": "Ansehen",
    "Show": "Anzeigen",
    "Hide": "Ausblenden",
    "Enable": "Aktivieren",
    "Disable": "Deaktivieren",
    "Select": "Auswählen",
    "Choose": "Wählen",
    "Download": "Herunterladen",
    "Upload": "Hochladen",
    "Send": "Senden",
    "Receive": "Empfangen",
    "Search": "Suchen",
    "Filter": "Filtern",
    "Sort": "Sortieren",
    "Refresh": "Aktualisieren",
    "Reload": "Neu laden",
    "Load More": "Mehr laden",
    "Expand": "Erweitern",
    "Collapse": "Einklappen",
    "Next": "Weiter",
    "Previous": "Zurück",
    "Back": "Zurück",
    "Forward": "Vorwärts",
    "Done": "Fertig",
    "Finish": "Abschließen",
    "Complete": "Vollständig",
    "Pending": "Ausstehend",
    "Processing": "Verarbeitung läuft",
    "Loading": "Lädt",
    "Saving": "Speichert",
    "Deleting": "Löscht",
    "Yes": "Ja",
    "No": "Nein",
    "OK": "OK",
    "Got it": "Verstanden",
    
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
    "Disable Account": "Konto deaktivieren",
    "Edit Permissions": "Berechtigungen bearbeiten",
    "Monitor security events in real-time": "Sicherheitsereignisse in Echtzeit überwachen",
    
    # Settings & Admin
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
    
    # Messages & Success/Error
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
    "User Type": "Benutzertyp",
    "User Status": "Benutzerstatus",
    "User Profile": "Benutzerprofil",
    "Profile Picture": "Profilbild",
    "Profile Information": "Profilinformationen",
    
    # Coupons
    "Create New Coupon": "Neuen Gutschein erstellen",
    "Edit Coupon": "Gutschein bearbeiten",
    "Coupon Management": "Gutscheinverwaltung",
    "Create and manage discount coupons": "Rabattgutscheine erstellen und verwalten",
    "Coupon Code": "Gutscheincode",
    "Discount Amount": "Rabattbetrag",
    "Expiration Date": "Ablaufdatum",
    "Active": "Aktiv",
    "Inactive": "Inaktiv",
    
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
    "Dashboard": "Dashboard",
    "Overview": "Übersicht",
    "Statistics": "Statistiken",
    "Reports": "Berichte",
    "Activity": "Aktivität",
    "History": "Verlauf",
    "Logs": "Protokolle",
    
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
    "Login": "Anmelden",
    "Logout": "Abmelden",
    "Sign In": "Anmelden",
    "Sign Out": "Abmelden",
    "Sign Up": "Registrieren",
    "Register": "Registrieren",
    "Forgot Password": "Passwort vergessen",
    "Reset Password": "Passwort zurücksetzen",
    "Change Password": "Passwort ändern",
    "Email": "E-Mail",
    "Password": "Passwort",
    "Username": "Benutzername",
    "Remember Me": "Angemeldet bleiben",
    
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
    "Migration": "Migration",
    "Database Migration": "Datenbankmigration",
    "Data Migration": "Datenmigration",
    
    # Moderation
    "Pending Review": "Überprüfung ausstehend",
    "Approved": "Genehmigt",
    "Rejected": "Abgelehnt",
    "Flagged": "Gekennzeichnet",
    "Review": "Überprüfen",
    "Moderate": "Moderieren",
    "Moderation": "Moderation",
    "Moderation Status": "Moderationsstatus",
    "Content Status": "Inhaltsstatus",
    "Report": "Melden",
    "Reports": "Meldungen",
    "Flag": "Melden",
    "Unflag": "Markierung entfernen",
    "Block": "Blockieren",
    "Unblock": "Entsperren",
    "Ban": "Sperren",
    "Unban": "Entsperren",
    "Suspend": "Suspendieren",
    "Unsuspend": "Freigeben",
    "Approve": "Genehmigen",
    "Reject": "Ablehnen",
    
    # Payments
    "Payment": "Zahlung",
    "Payments": "Zahlungen",
    "Transaction": "Transaktion",
    "Transactions": "Transaktionen",
    "Refund": "Rückerstattung",
    "Refunds": "Rückerstattungen",
    "Amount": "Betrag",
    "Total": "Gesamt",
    "Subtotal": "Zwischensumme",
    "Tax": "Steuer",
    "Fee": "Gebühr",
    "Currency": "Währung",
    "Status": "Status",
    "Date": "Datum",
    "Time": "Zeit",
    "Payment Method": "Zahlungsmethode",
    "Credit Card": "Kreditkarte",
    "Debit Card": "Debitkarte",
    "PayPal": "PayPal",
    "Bank Transfer": "Banküberweisung",
    "Cash": "Bargeld",
    "Pending": "Ausstehend",
    "Completed": "Abgeschlossen",
    "Failed": "Fehlgeschlagen",
    "Cancelled": "Storniert",
    "Processing": "In Bearbeitung",
    
    # Content
    "Title": "Titel",
    "Description": "Beschreibung",
    "Content": "Inhalt",
    "Message": "Nachricht",
    "Comment": "Kommentar",
    "Comments": "Kommentare",
    "Reply": "Antworten",
    "Replies": "Antworten",
    "Like": "Gefällt mir",
    "Likes": "Gefällt mir",
    "Share": "Teilen",
    "Shares": "Teilungen",
    "View": "Ansicht",
    "Views": "Aufrufe",
    "Post": "Beitrag",
    "Posts": "Beiträge",
    "Image": "Bild",
    "Images": "Bilder",
    "Photo": "Foto",
    "Photos": "Fotos",
    "Video": "Video",
    "Videos": "Videos",
    "Audio": "Audio",
    "File": "Datei",
    "Files": "Dateien",
    "Attachment": "Anhang",
    "Attachments": "Anhänge",
    "Link": "Link",
    "Links": "Links",
    "URL": "URL",
    "Tag": "Tag",
    "Tags": "Tags",
    "Category": "Kategorie",
    "Categories": "Kategorien",
    
    # Time & Dates
    "Today": "Heute",
    "Yesterday": "Gestern",
    "Tomorrow": "Morgen",
    "This Week": "Diese Woche",
    "Last Week": "Letzte Woche",
    "This Month": "Dieser Monat",
    "Last Month": "Letzter Monat",
    "This Year": "Dieses Jahr",
    "Last Year": "Letztes Jahr",
    "All Time": "Gesamt",
    "Recent": "Kürzlich",
    "New": "Neu",
    "Old": "Alt",
    "Latest": "Neueste",
    "Oldest": "Älteste",
    
    # Common Phrases
    "Role:": "Rolle:",
    "Severity:": "Schweregrad:",
    "User:": "Benutzer:",
    "By:": "Von:",
    "Reason:": "Grund:",
    "User Type:": "Benutzertyp:",
    "User Status:": "Benutzerstatus:",
    "Are you sure?": "Sind Sie sicher?",
    "Are you sure you want to delete this?": "Möchten Sie dies wirklich löschen?",
    "This action cannot be undone": "Diese Aktion kann nicht rückgängig gemacht werden",
    "This action cannot be undone.": "Diese Aktion kann nicht rückgängig gemacht werden.",
    "Are you absolutely sure?": "Sind Sie absolut sicher?",
    "Please confirm": "Bitte bestätigen",
    "Confirmation required": "Bestätigung erforderlich",
    "Success": "Erfolg",
    "Error": "Fehler",
    "Warning": "Warnung",
    "Info": "Info",
    "Information": "Information",
    "Notice": "Hinweis",
    "Alert": "Warnung",
    "Notification": "Benachrichtigung",
    "Notifications": "Benachrichtigungen",
    "No data": "Keine Daten",
    "No results": "Keine Ergebnisse",
    "No items": "Keine Elemente",
    "Empty": "Leer",
    "None": "Keine",
    "All": "Alle",
    "Any": "Beliebig",
    "Other": "Andere",
    "More": "Mehr",
    "Less": "Weniger",
    "Show More": "Mehr anzeigen",
    "Show Less": "Weniger anzeigen",
    "Details": "Details",
    "More Details": "Weitere Details",
    "Additional Details": "Zusätzliche Details",
    "Advanced": "Erweitert",
    "Advanced Options": "Erweiterte Optionen",
    "Basic": "Einfach",
    "Simple": "Einfach",
    "Custom": "Benutzerdefiniert",
    "Default": "Standard",
    "Required": "Erforderlich",
    "Optional": "Optional",
    "Recommended": "Empfohlen",
    "Not Recommended": "Nicht empfohlen",
    
    # Messaging & Communication
    "Message": "Nachricht",
    "Messages": "Nachrichten",
    "Chat": "Chat",
    "Conversation": "Konversation",
    "Conversations": "Konversationen",
    "Send Message": "Nachricht senden",
    "New Message": "Neue Nachricht",
    "Reply": "Antworten",
    "Forward": "Weiterleiten",
    "Inbox": "Posteingang",
    "Sent": "Gesendet",
    "Draft": "Entwurf",
    "Drafts": "Entwürfe",
    "Trash": "Papierkorb",
    "Archive": "Archiv",
    "Unread": "Ungelesen",
    "Read": "Gelesen",
    "Mark as Read": "Als gelesen markieren",
    "Mark as Unread": "Als ungelesen markieren",
    
    # Technical Terms (keep some in English or translate appropriately)
    "IP": "IP",
    "API": "API",
    "URL": "URL",
    "HTTP": "HTTP",
    "HTTPS": "HTTPS",
    "SSL": "SSL",
    "Database": "Datenbank",
    "Server": "Server",
    "Client": "Client",
    "Cache": "Cache",
    "Cookie": "Cookie",
    "Cookies": "Cookies",
    "Session": "Sitzung",
    "Token": "Token",
    "Key": "Schlüssel",
    "Value": "Wert",
    "Parameter": "Parameter",
    "Configuration": "Konfiguration",
    "Version": "Version",
    "Build": "Build",
    "Debug": "Debug",
    "Production": "Produktion",
    "Development": "Entwicklung",
    "Test": "Test",
    "Staging": "Staging",
}

def translate_placeholder(text):
    """
    Translate text that is in [brackets]
    Returns the translated text without brackets
    """
    if not text or not isinstance(text, str):
        return text
    
    # Check if it's bracketed
    if not (text.startswith('[') and text.endswith(']')):
        return text
    
    # Extract inner text
    inner = text[1:-1]
    
    # Skip if it's just numbers, IPs, or technical values
    if re.match(r'^[\d\.\/:]+$', inner):
        return inner  # Remove brackets but keep value
    
    # Direct lookup
    if inner in TRANSLATIONS:
        return TRANSLATIONS[inner]
    
    # Handle text with variables (preserve $var, ${var}, {var})
    # Extract variables
    variables = re.findall(r'\$\{[^}]+\}|\{[^}]+\}|\$\w+', inner)
    
    # Try to find match with or without variables
    for key, value in TRANSLATIONS.items():
        # Check if the pattern matches (ignoring variables)
        key_pattern = re.escape(key)
        for var in variables:
            key_pattern = key_pattern.replace(re.escape(var), '.*')
        
        if re.fullmatch(key_pattern, inner):
            result = value
            # Preserve variables in output
            for var in variables:
                if var not in result:
                    result = result + ' ' + var
            return result
    
    # Check for partial matches
    for key, value in TRANSLATIONS.items():
        if key in inner:
            # Replace the translatable part, keep the rest
            result = inner.replace(key, value)
            return result
    
    # If starts with • (bullet), try without it
    if inner.startswith('• '):
        rest = inner[2:]
        if rest in TRANSLATIONS:
            return '• ' + TRANSLATIONS[rest]
    
    # No translation found - log and return without brackets
    # (this allows for manual review later)
    return inner

def main():
    input_file = '/Users/kristybock/artbeat/assets/translations/de.json'
    output_file = input_file
    
    print("Loading de.json...")
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"Processing {len(data)} entries...")
    
    translated_count = 0
    unchanged_count = 0
    
    for key, value in data.items():
        if isinstance(value, str) and value.startswith('[') and value.endswith(']'):
            new_value = translate_placeholder(value)
            if new_value != value:
                data[key] = new_value
                translated_count += 1
                # Show first few translations
                if translated_count <= 20:
                    print(f"  {key}:")
                    print(f"    {value} -> {new_value}")
            else:
                unchanged_count += 1
                if unchanged_count <= 10:
                    print(f"  [NO TRANSLATION] {key}: {value}")
    
    print(f"\n{'='*60}")
    print(f"Translation Summary:")
    print(f"  Total entries: {len(data)}")
    print(f"  Translated: {translated_count}")
    print(f"  Unchanged placeholders: {unchanged_count}")
    print(f"{'='*60}\n")
    
    print("Saving updated de.json...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("✓ Translation complete!")
    print(f"  File saved: {output_file}")
    
    if unchanged_count > 0:
        print(f"\n⚠ Warning: {unchanged_count} placeholders could not be translated automatically.")
        print("  These may need manual translation or might be technical values.")

if __name__ == '__main__':
    main()
