#!/usr/bin/env python3
"""
French Translation - Ultra Final Comprehensive Script
Handles ALL remaining French translations with massive dictionary
"""

import json
from pathlib import Path

FR_JSON_PATH = Path(__file__).parent.parent / 'assets' / 'translations' / 'fr.json'

# ULTRA COMPREHENSIVE FRENCH TRANSLATIONS - ALL REMAINING PATTERNS
ULTIMATE_FR = {
    # Transaction and payment details
    "CSV content copied to clipboard": "Contenu CSV copié dans le presse-papiers",
    "Date Range": "Plage de Dates",
    "Total Revenue": "Revenu Total",
    "Update Status": "Mettre à Jour le Statut",
    "Item: ${transaction.itemTitle}": "Article: ${transaction.itemTitle}",
    
    # Email and alerts
    "Email Alerts": "Alertes par E-mail",
    "Send email notifications for threats": "Envoyer des notifications par e-mail pour les menaces",
    "Additional Details: Success": "Détails Supplémentaires: Succès",
    
    # Network and IP
    "10.0.0.0/8": "10.0.0.0/8",
    "192.168.1.0/24": "192.168.1.0/24",
    "IP Address: 192.168.1.${100 + index}": "Adresse IP: 192.168.1.${100 + index}",
    "IP range added to whitelist": "Plage IP ajoutée à la liste blanche",
    "Office Network": "Réseau de Bureau",
    "VPN Network": "Réseau VPN",
    
    # Audit and logging
    "Audit Log Details": "Détails du Journal d'Audit",
    "Log ID: LOG_${1000 + index}": "ID de Journal: LOG_${1000 + index}",
    
    # Security and monitoring
    "Automated Threat Response": "Réponse Automatique aux Menaces",
    "Automatically block suspicious activity": "Bloquer automatiquement l'activité suspecte",
    "Disable Account": "Désactiver le Compte",
    "Edit Permissions": "Modifier les Permissions",
    "Monitor security events in real-time": "Surveiller les événements de sécurité en temps réel",
    "Real-time Monitoring": "Surveillance en Temps Réel",
    "Recommended Actions:": "Actions Recommandées:",
    "Resolve": "Résoudre",
    "Danger Zone": "Zone de Danger",
    "Security Score": "Score de Sécurité",
    "Access Control": "Contrôle d'Accès",
    "Audit Logs": "Journaux d'Audit",
    
    # Migration and system
    "Run Migration": "Exécuter la Migration",
    "Rollback": "Annuler",
    "Migrate": "Migrer",
    "Data Migration": "Migration des Données",
    
    # Admin actions
    "Approving content...": "Approbation du contenu...",
    "Failed login attempt blocked": "Tentative de connexion échouée bloquée",
    "Password policy updated": "Politique de mot de passe mise à jour",
    "Security scan completed": "Analyse de sécurité terminée",
    "Suspicious data access detected": "Accès aux données suspect détecté",
    "Blocked IPs": "IPs Bloquées",
    "Failed Logins": "Connexions Échouées",
    
    # Messaging and UI
    "New Group": "Nouveau Groupe",
    "Select sorting": "Sélectionner le tri",
    "Auto-download Media": "Téléchargement Automatique des Médias",
    "Dark": "Sombre",
    "Light": "Clair",
    "Select Theme": "Sélectionner un Thème",
    "System": "Système",
    "Select Wallpaper": "Sélectionner un Fond d'Écran",
    "Feed Name": "Nom du Flux",
    "Moderate": "Modéré",
    "Moderation features coming soon": "Fonctionnalités de modération à venir",
    "Quiet hours": "Heures silencieuses",
    "Initializing voice recorder...": "Initialisation de l'enregistreur vocal...",
    "Auto-delete spam": "Suppression automatique des spams",
    "Go to message": "Aller au message",
    "Navigate to message in chat": "Naviguer vers le message dans le chat",
    
    # Art walk and navigation
    "Abandon": "Abandonner",
    "Level up your art journey!": "Montez en niveau dans votre parcours artistique!",
    "Walk paused. You can resume anytime!": "Promenade en pause. Vous pouvez reprendre à tout moment!",
    "Would you like to finish now or continue exploring?": "Souhaitez-vous terminer maintenant ou continuer à explorer?",
    "• You can still claim other rewards": "• Vous pouvez toujours réclamer d'autres récompenses",
    "⬅️ At first step of this segment": "⬅️ À la première étape de ce segment",
    "⬅️ Showing previous navigation step": "⬅️ Affichage de l'étape de navigation précédente",
    "  ✓ Photo documentation bonus (+30 XP)": "  ✓ Bonus de documentation photo (+30 XP)",
    "• +$completionBonus XP total": "• +$completionBonus XP au total",
    "• ${widget.progress.totalPointsEarned} points earned": "• ${widget.progress.totalPointsEarned} points gagnés",
    
    # Artist features
    "Gift Received": "Cadeau Reçu",
    "Host exhibitions and gatherings": "Organiser des expositions et des rassemblements",
    "Manage your commissions": "Gérer vos commissions",
    "Photo Post": "Publication Photo",
    "Set up commission settings": "Configurer les paramètres de commission",
    "Showcase your latest creation": "Montrez votre dernière création",
    "Text Post": "Publication Texte",
    "Track your performance": "Suivre vos performances",
    "Please log in to follow artists": "Veuillez vous connecter pour suivre des artistes",
    "Please log in to send gifts": "Veuillez vous connecter pour envoyer des cadeaux",
    "You cannot send gifts to yourself": "Vous ne pouvez pas vous envoyer de cadeaux",
    "Invitation cancelled": "Invitation annulée",
    "Invitation reminder sent": "Rappel d'invitation envoyé",
    "Please select a plan": "Veuillez sélectionner un plan",
    "Set as Default": "Définir par Défaut",
    
    # Media and content
    "Mediums": "Médiums",
    "Medium: $_selectedMedium": "Médium: $_selectedMedium",
    "Could not open $url": "Impossible d'ouvrir $url",
    "Public Art Disclaimer": "Avertissement sur l'Art Public",
    "Nearby Art": "Art à Proximité",
    "See trending art discoveries": "Voir les découvertes artistiques tendance",
    "See trending conversations": "Voir les conversations tendance",
    "Terms & Conditions": "Conditions Générales",
    "Unable to load artist feed": "Impossible de charger le flux de l'artiste",
    
    # User dashboard (translate like Spanish)
    "Art Walks": "Promenades Artistiques",
    "Browse": "Parcourir",
    "Captures": "Captures",
    "Community": "Communauté",
    "Community Feed": "Flux de la Communauté",
    "completed": "terminé",
    "Connect artists": "Connecter des artistes",
    "Connect with artists": "Connecter avec des artistes",
    "Daily Challenge": "Défi Quotidien",
    "Discover Local ARTbeat": "Découvrir Local ARTbeat",
    "Explore beautiful artworks from Local ARTbeat talented artists around you": "Explorez de magnifiques œuvres d'art de talentueux artistes de Local ARTbeat près de chez vous",
    "Discover new art": "Découvrir de nouveaux arts",
    "Explore More": "Explorer Plus",
    "Explore nearby": "Explorer à proximité",
    "Find art": "Trouver de l'art",
    "Join Conversation": "Rejoindre la Conversation",
    "Join events": "Rejoindre des événements",
    "Loading...": "Chargement...",
    "Nearby Art Walks": "Promenades Artistiques à Proximité",
    "Quick Actions": "Actions Rapides",
    "Ready to explore some art?": "Prêt à explorer de l'art?",
    "Recent Captures": "Captures Récentes",
    "Start Capturing": "Commencer à Capturer",
    "View All": "Voir Tout",
    "Walks": "Promenades",
    "Welcome, {0}!": "Bienvenue, {0}!",
    "Welcome to Local ARTbeat": "Bienvenue sur Local ARTbeat",
    "Your Journey": "Votre Voyage",
    "Your Progress": "Votre Progression",
    
    # Authentication
    "Access denied. Admin privileges required.": "Accès refusé. Privilèges d'administrateur requis.",
    "Invalid email address.": "Adresse e-mail invalide.",
    "This account has been disabled.": "Ce compte a été désactivé.",
    "No user found with this email.": "Aucun utilisateur trouvé avec cet e-mail.",
    "Invalid password.": "Mot de passe invalide.",
    "Please enter a valid email": "Veuillez entrer un e-mail valide",
    "Password must be at least 6 characters": "Le mot de passe doit contenir au moins 6 caractères",
    "Authentication failed: ${message}": "Échec de l'authentification: ${message}",
    "An unexpected error occurred: ${error}": "Une erreur inattendue s'est produite: ${error}",
    
    # System and monitoring
    "Avg Session": "Session Moyenne",
    "CPU Usage": "Utilisation CPU",
    "Memory Usage": "Utilisation de la Mémoire",
    "Critical Alerts": "Alertes Critiques",
    "Warning Alerts": "Alertes d'Avertissement",
    "No system alerts": "Aucune alerte système",
    "Featured": "En Vedette",
    "Verified": "Vérifié",
    "Artbeat Home": "Accueil Artbeat",
    "Return to main app": "Retour à l'application principale",
    "Admin Panel": "Panneau d'Administration",
    "Transaction & refund management": "Gestion des transactions et des remboursements",
    "Standalone development environment": "Environnement de développement autonome",
}

def translate_ultimate():
    """Apply ultimate comprehensive French translations"""
    print(f"{'='*70}")
    print(f"French Translation - ULTIMATE FINAL PASS")
    print(f"{'='*70}\n")
    
    with open(FR_JSON_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    remaining = [(k, v) for k, v in data.items() if isinstance(v, str) and v.startswith('[') and v.endswith(']')]
    print(f"Starting with {len(remaining)} bracketed entries\n")
    
    count = 0
    
    for key, value in list(data.items()):
        if not isinstance(value, str) or not (value.startswith('[') and value.endswith(']')):
            continue
        
        content = value[1:-1]  # Remove brackets
        
        if content in ULTIMATE_FR:
            data[key] = ULTIMATE_FR[content]
            count += 1
            if count <= 150:
                print(f"✓ {content[:50]} → {data[key][:50]}")
    
    # Save
    with open(FR_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    remaining_after = [(k, v) for k, v in data.items() if isinstance(v, str) and v.startswith('[') and v.endswith(']')]
    
    print(f"\n{'='*70}")
    print(f"ULTIMATE FINAL SUMMARY")
    print(f"{'='*70}")
    print(f"Translated in this pass: {count}")
    print(f"Remaining: {len(remaining_after)}")
    print(f"✓ File saved: {FR_JSON_PATH}")
    
    total_done = 1397 - len(remaining_after)
    percentage = (total_done / 1397) * 100
    print(f"📊 Total progress: {total_done}/1397 ({percentage:.1f}%)")
    print(f"{'='*70}\n")
    
    if len(remaining_after) > 0 and len(remaining_after) <= 50:
        print("Remaining entries:")
        for k, v in remaining_after:
            print(f"  {k}: {v}")

if __name__ == "__main__":
    translate_ultimate()
