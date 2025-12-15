#!/usr/bin/env python3
"""
French Translation - Remove [FR] Prefixes
Translate all entries with [FR] prefix to proper French translations
"""

import json

FR_PREFIX_TRANSLATIONS = {
    # Admin dashboard
    "Active Users": "Utilisateurs Actifs",
    "All systems operational": "Tous les systèmes opérationnels",
    "Analytics": "Analyses",
    "API": "API",
    "Artists": "Artistes",
    "Artworks": "Œuvres",
    "Business Analytics": "Analyses d'Entreprise",
    "Configure App": "Configurer l'Application",
    "Content Moderation": "Modération du Contenu",
    "Database": "Base de Données",
    "Detailed Insights": "Informations Détaillées",
    "Key Metrics": "Métriques Clés",
    "Manage Users": "Gérer les Utilisateurs",
    "Management Actions": "Actions de Gestion",
    "Monitoring": "Surveillance",
    "Monthly Performance": "Performance Mensuelle",
    "Normal": "Normal",
    "Online": "En Ligne",
    "Pending": "En Attente",
    "Pending Reviews": "Examens en Attente",
    "Pending Verification": "Vérification en Attente",
    "Recent Alerts": "Alertes Récentes",
    "Reports": "Rapports",
    "Revenue": "Revenu",
    "Revenue Growth": "Croissance du Revenu",
    "Review Reports": "Examiner les Rapports",
    "Server Load": "Charge du Serveur",
    "Servers": "Serveurs",
    "Storage": "Stockage",
    "Storage capacity reaching maximum": "La capacité de stockage atteint le maximum",
    "Storage Warning": "Avertissement de Stockage",
    "System Health": "Santé du Système",
    "System Overview": "Aperçu du Système",
    "System Settings": "Paramètres du Système",
    "System Status": "Statut du Système",
    "Total Users": "Total des Utilisateurs",
    "User Management": "Gestion des Utilisateurs",
    "View All": "Voir Tout",
    "Welcome back, Admin": "Bon retour, Admin",
    
    # Loading states
    "Loading dashboard...": "Chargement du tableau de bord...",
    "Preparing your personalized experience": "Préparation de votre expérience personnalisée",
    "Loading...": "Chargement...",
    
    # Onboarding
    "Add bio and profile photo": "Ajouter une biographie et une photo de profil",
    "Art Walks": "Promenades Artistiques",
    "Follow guided art experiences and discover hidden gems": "Suivez des expériences artistiques guidées et découvrez des trésors cachés",
    "{count} artists online": "{count} artistes en ligne",
    "Begin your artistic journey today": "Commencez votre voyage artistique aujourd'hui",
    "Capture a beautiful moment": "Capturer un beau moment",
    "Captures": "Captures",
    "Share your artistic perspective with photo captures": "Partagez votre perspective artistique avec des captures photo",
    "Community": "Communauté",
    "Connect with artists and art lovers worldwide": "Connectez-vous avec des artistes et des amateurs d'art du monde entier",
    "Connect with thousands of artists and art enthusiasts": "Connectez-vous avec des milliers d'artistes et d'amateurs d'art",
    "Complete Your Profile": "Compléter Votre Profil",
    "Connect with fellow artists": "Connectez-vous avec d'autres artistes",
    "Browse, commission, and collect from local artists. Support creativity by gifting promo credits that help artists shine.": "Parcourez, commissionnez et collectionnez auprès d'artistes locaux. Soutenez la créativité en offrant des crédits promotionnels qui aident les artistes à briller.",
    "Connect with Artists": "Connectez-vous avec des Artistes",
    "Continue": "Continuer",
    "Share your art, spark conversations, and connect through a creative feed. Chat 1-on-1 or in groups—where inspiration meets community.": "Partagez votre art, démarrez des conversations et connectez-vous via un flux créatif. Discutez en tête-à-tête ou en groupe—là où l'inspiration rencontre la communauté.",
    "Create & Share": "Créer et Partager",
    "Discover, Create, Connect": "Découvrir, Créer, Connecter",
    "Discover Features": "Découvrir les Fonctionnalités",
    "Turn every mural into a mission—complete quests, earn badges, and level up your art adventure.": "Transformez chaque murale en mission—terminez des quêtes, gagnez des badges et montez de niveau dans votre aventure artistique.",
    "Explore art nearby": "Explorer l'art à proximité",
    "Discover. Capture. Explore.": "Découvrir. Capturer. Explorer.",
    "Find Friends": "Trouver des Amis",
    "Get Started": "Commencer",
    "Join the Community": "Rejoindre la Communauté",
    "members joined": "membres inscrits",
    "Add your bio, photo, and preferences to get started": "Ajoutez votre biographie, photo et préférences pour commencer",
    "Quick Setup": "Configuration Rapide",
    "Ready to Start?": "Prêt à Commencer?",
    "Let's get you set up": "Configurons votre profil",
    "Start an Art Walk": "Commencer une Promenade Artistique",
    "Step {step} of {total}": "Étape {step} sur {total}",
    "Take Your First Photo": "Prenez Votre Première Photo",
    "Discover, create, and connect with art lovers worldwide": "Découvrez, créez et connectez-vous avec des amateurs d'art du monde entier",
    "Welcome to Artbeat": "Bienvenue sur Artbeat",
    "Welcome to Local ARTbeat": "Bienvenue sur Local ARTbeat",
    "Welcome, {username}!": "Bienvenue, {username}!",
    "Your Journey": "Votre Voyage",
    
    # Dashboard navigation
    "Achievements": "Succès",
    "Browse": "Parcourir",
    "Community Feed": "Fil de la Communauté",
    "completed": "terminé",
    "Connect artists": "Connecter les artistes",
    "Connect with artists": "Connectez-vous avec des artistes",
    "Daily Challenge": "Défi Quotidien",
    "Discover Local ARTbeat": "Découvrir Local ARTbeat",
    "Explore beautiful artworks from Local ARTbeat talented artists around you": "Explorez de belles œuvres d'artistes talentueux de Local ARTbeat autour de vous",
    "Discover new art": "Découvrir de nouveaux arts",
    "Events": "Événements",
    "Explore More": "Explorer Plus",
    "Explore nearby": "Explorer à proximité",
    "Find art": "Trouver de l'art",
    "Join Conversation": "Rejoindre la Conversation",
    "Join events": "Rejoindre des événements",
    "Level": "Niveau",
    "Nearby Art Walks": "Promenades Artistiques à Proximité",
    "Quick Actions": "Actions Rapides",
    "Ready to explore some art?": "Prêt à explorer de l'art?",
    "Recent Captures": "Captures Récentes",
    "Start Capturing": "Commencer à Capturer",
    "Walks": "Promenades",
    "Welcome, {0}!": "Bienvenue, {0}!",
    "Your Progress": "Votre Progression",
}

def remove_fr_prefixes():
    """Remove [FR] prefixes and apply French translations"""
    
    print("=" * 70)
    print("French Translation - Removing [FR] Prefixes")
    print("=" * 70)
    
    # Load current fr.json
    with open('assets/translations/fr.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Count initial [FR] entries
    initial_count = sum(1 for v in data.values() 
                       if isinstance(v, str) and v.startswith('[FR]'))
    
    print(f"Starting with {initial_count} [FR] prefix entries\n")
    
    # Apply translations and remove [FR] prefixes
    translated_count = 0
    for key, value in data.items():
        if isinstance(value, str) and value.startswith('[FR]'):
            # Extract text after '[FR] '
            english_text = value[5:].strip()
            
            # Check if we have a translation
            if english_text in FR_PREFIX_TRANSLATIONS:
                french_text = FR_PREFIX_TRANSLATIONS[english_text]
                data[key] = french_text
                translated_count += 1
                print(f"✓ [FR] {english_text[:55]} → {french_text[:55]}")
            else:
                print(f"⚠ Missing translation for: {english_text}")
    
    # Count remaining [FR] entries
    remaining_count = sum(1 for v in data.values() 
                         if isinstance(v, str) and v.startswith('[FR]'))
    
    # Save updated fr.json
    with open('assets/translations/fr.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "=" * 70)
    print("[FR] PREFIX REMOVAL SUMMARY")
    print("=" * 70)
    print(f"Translated in this pass: {translated_count}")
    print(f"Remaining [FR] entries: {remaining_count}")
    print(f"✓ File saved: /Users/kristybock/artbeat/assets/translations/fr.json")
    
    # Verify complete translation
    total_bracketed = sum(1 for v in data.values() 
                         if isinstance(v, str) and v.startswith('[') and v.endswith(']'))
    
    if total_bracketed == 0 and remaining_count == 0:
        print(f"\n🎉 FRENCH TRANSLATION 100% COMPLETE!")
        print(f"✓ All 1,397 bracketed placeholders translated")
        print(f"✓ All {initial_count} [FR] prefixes removed and translated")
    else:
        print(f"\n⚠ Remaining work:")
        print(f"  - Bracketed entries: {total_bracketed}")
        print(f"  - [FR] prefix entries: {remaining_count}")
    
    print("=" * 70)

if __name__ == "__main__":
    remove_fr_prefixes()
