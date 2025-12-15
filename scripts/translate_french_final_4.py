#!/usr/bin/env python3
"""
French Translation - FINAL PASS 4 (COMPREHENSIVE)
All remaining entries: art walks, artist dashboard, messaging, captures, analytics
"""

import json

FINAL_4_TRANSLATIONS = {
    # Walk progress indicators
    "• $photosCount photos taken": "• $photosCount photos prises",
    "• Red markers = not yet visited": "• Marqueurs rouges = pas encore visités",
    "Resume Walk": "Reprendre la Promenade",
    "Review Walk": "Examiner la Promenade",
    "  ✓ Speed bonus (+25 XP)": "  ✓ Bonus de vitesse (+25 XP)",
    "Stop Navigation": "Arrêter la Navigation",
    "View Progress": "Voir la Progression",
    "🎉 Walk Completed!": "🎉 Promenade Terminée!",
    "Walk Progress": "Progression de la Promenade",
    
    # Saved walks
    "No saved walks yet": "Aucune promenade sauvegardée pour l'instant",
    "Saved": "Sauvegardé",
    "Complete your first art walk to see it here": "Terminez votre première promenade artistique pour la voir ici",
    "Create Walk": "Créer une Promenade",
    "Created": "Créé",
    "Delete Walk?": "Supprimer la Promenade?",
    "In Progress": "En Cours",
    "Log In": "Se Connecter",
    "My Art Walks": "Mes Promenades Artistiques",
    "No completed walks yet": "Aucune promenade terminée pour l'instant",
    "No walks created yet": "Aucune promenade créée pour l'instant",
    "No walks in progress": "Aucune promenade en cours",
    "• Perfect walk - all art found!": "• Promenade parfaite - tout l'art trouvé!",
    "Submit Review": "Soumettre l'Examen",
    "🎉 You discovered all nearby art!": "🎉 Vous avez découvert tout l'art à proximité!",
    "Weekly Goals": "Objectifs Hebdomadaires",
    
    # Analytics
    "Analytics Dashboard": "Tableau de Bord Analytique",
    "No artwork data available": "Aucune donnée d'œuvre disponible",
    "No location data available": "Aucune donnée de localisation disponible",
    "No referral data available": "Aucune donnée de parrainage disponible",
    "No visitor data available": "Aucune donnée de visiteur disponible",
    "Unknown Artwork": "Œuvre Inconnue",
    "Upgrade Now": "Mettre à Niveau Maintenant",
    
    # Ad management
    "Ad Campaign Management": "Gestion de Campagne Publicitaire",
    "Ad Performance Analytics": "Analyses de Performance Publicitaire",
    "Approval Status Tracking": "Suivi du Statut d'Approbation",
    "Artist Approved Ads": "Publicités Approuvées par l'Artiste",
    "Revenue Tracking": "Suivi des Revenus",
    "Apply": "Appliquer",
    
    # Artist filtering
    "+${artist.mediums.length - 2}": "+${artist.mediums.length - 2}",
    "Filter Artists": "Filtrer les Artistes",
    "No artists found": "Aucun artiste trouvé",
    "Style: $_selectedStyle": "Style: $_selectedStyle",
    "Filter Verified Artists": "Filtrer les Artistes Vérifiés",
    
    # Artist dashboard
    "Add new artwork to your portfolio": "Ajouter une nouvelle œuvre à votre portfolio",
    "Add Post": "Ajouter une Publication",
    "Announce upcoming events": "Annoncer les événements à venir",
    "Artist Dashboard": "Tableau de Bord Artiste",
    "Artwork Post": "Publication d'Œuvre",
    "Artwork Sold": "Œuvre Vendue",
    "Commission Hub": "Centre de Commissions",
    "Commission Request": "Demande de Commission",
    "Commission Wizard": "Assistant de Commission",
    "Create Event": "Créer un Événement",
    "Event Post": "Publication d'Événement",
    "Share photos from your studio": "Partagez des photos de votre atelier",
    "Share updates with your community": "Partagez des mises à jour avec votre communauté",
    "Share your thoughts and updates": "Partagez vos pensées et mises à jour",
    "Upload Artwork": "Télécharger une Œuvre",
    "View All Activity": "Voir Toute l'Activité",
    "View Analytics": "Voir les Analyses",
    
    # Account types
    "Account Type": "Type de Compte",
    "Become an Artist": "Devenir un Artiste",
    "Business Plan": "Plan d'Entreprise",
    "Creator Plan": "Plan Créateur",
    "Free Plan": "Plan Gratuit",
    "Starter Plan": "Plan de Démarrage",
    
    # Artist profile
    "Artist profile created successfully!": "Profil d'artiste créé avec succès!",
    "Artist profile saved successfully": "Profil d'artiste enregistré avec succès",
    "Individual Artist": "Artiste Individuel",
    "Styles": "Styles",
    "Artist Profile": "Profil d'Artiste",
    "Artist profile not found": "Profil d'artiste introuvable",
    "No artwork available": "Aucune œuvre disponible",
    
    # Events
    "Event saved successfully": "Événement enregistré avec succès",
    "Public Event": "Événement Public",
    "Upgrade to Pro": "Passer à Pro",
    
    # Gallery analytics
    "Artwork Views": "Vues d'Œuvres",
    "Commission": "Commission",
    "Export Report": "Exporter le Rapport",
    "Gallery Analytics": "Analyses de Galerie",
    "Last 12 Months": "12 Derniers Mois",
    "Last 30 Days": "30 Derniers Jours",
    "Last 7 Days": "7 Derniers Jours",
    "Last 90 Days": "90 Derniers Jours",
    "No artist performance data available": "Aucune donnée de performance d'artiste disponible",
    "No revenue data available for selected time period": "Aucune donnée de revenu disponible pour la période sélectionnée",
    "Paid Commissions": "Commissions Payées",
    "Pending Commissions": "Commissions en Attente",
    "Revenue": "Revenu",
    "Sales": "Ventes",
    "Total Commissions": "Total des Commissions",
    "Upgrade to Gallery Plan": "Passer au Plan Galerie",
    
    # Gallery management
    "Artist removed from gallery successfully": "Artiste retiré de la galerie avec succès",
    "Invitation sent successfully": "Invitation envoyée avec succès",
    "Cancel Invitation": "Annuler l'Invitation",
    "Gallery Artists": "Artistes de la Galerie",
    "Welcome! Setting up your profile...": "Bienvenue! Configuration de votre profil...",
    
    # Artwork management
    "\"${artwork.title}\" has been deleted successfully": "\"${artwork.title}\" a été supprimé avec succès",
    "Deleting artwork...": "Suppression de l'œuvre...",
    "My Artwork": "Mes Œuvres",
    
    # Subscription
    "Subscribe to ${_getTierName(widget.tier)}": "S'abonner à ${_getTierName(widget.tier)}",
    "Add Payment Method": "Ajouter un Moyen de Paiement",
    "Subscription Successful": "Abonnement Réussi",
    "Payment Amount:": "Montant du Paiement:",
    "Payment ID:": "ID de Paiement:",
    "Refund Request Submitted": "Demande de Remboursement Soumise",
    "Submit Refund Request": "Soumettre une Demande de Remboursement",
    "All Time": "Tout le Temps",
    "Manage Subscription": "Gérer l'Abonnement",
    "No data available for the selected period": "Aucune donnée disponible pour la période sélectionnée",
    "Subscription Analytics": "Analyses d'Abonnement",
    "This Year": "Cette Année",
    
    # Captures
    "Type: ${capture.artType!}": "Type: ${capture.artType!}",
    "Artist: ${capture.artistName!}": "Artiste: ${capture.artistName!}",
    "Capture approved successfully": "Capture approuvée avec succès",
    "Approve Capture": "Approuver la Capture",
    "Capture deleted permanently": "Capture supprimée définitivement",
    "Capture rejected": "Capture rejetée",
    "Delete Capture": "Supprimer la Capture",
    "Reject Capture": "Rejeter la Capture",
    "Capture Details": "Détails de la Capture",
    "Save Capture": "Sauvegarder la Capture",
    "Capture deleted successfully": "Capture supprimée avec succès",
    "Are you sure you want to delete this capture?": "Êtes-vous sûr de vouloir supprimer cette capture?",
    "No capture found": "Aucune capture trouvée",
    "Capture updated successfully": "Capture mise à jour avec succès",
    "Edit Capture": "Modifier la Capture",
    
    # Capture upload
    "GestureDetector was tapped!": "GestureDetector a été touché!",
    "Art Captured!": "Art Capturé!",
    "Go to Dashboard": "Aller au Tableau de Bord",
    "Location permissions are denied": "Les permissions de localisation sont refusées",
    "Location services are disabled.": "Les services de localisation sont désactivés.",
    "Please accept the public art disclaimer": "Veuillez accepter l'avertissement sur l'art public",
    "Upload Capture": "Télécharger la Capture",
    
    # Capture search
    "Local Captures": "Captures Locales",
    "Find art captures by location or type": "Trouver des captures d'art par emplacement ou type",
    "Search Captures": "Rechercher des Captures",
    "Search for artists and their captures": "Rechercher des artistes et leurs captures",
    "Art Capture": "Capture d'Art",
    "Community Views": "Vues de la Communauté",
    "Discover art captures near you": "Découvrir des captures d'art près de vous",
    "Popular Captures": "Captures Populaires",
    "My Captures": "Mes Captures",
    "Accept & Continue": "Accepter et Continuer",
    
    # Loading states
    "Loading artist feed...": "Chargement du flux d'artiste...",
    "Load More": "Charger Plus",
    
    # Filters
    "Clear Filters": "Effacer les Filtres",
    
    # Messaging - search
    "Search Conversations": "Rechercher des Conversations",
    "Search for artists and community members": "Rechercher des artistes et membres de la communauté",
    "Find messages and chat history": "Trouver des messages et l'historique des discussions",
    
    # Messaging - settings
    "Message Settings": "Paramètres de Messages",
    "Blocked Users": "Utilisateurs Bloqués",
    "Discover and join art communities": "Découvrir et rejoindre des communautés artistiques",
    "Find People": "Trouver des Personnes",
    "Join Groups": "Rejoindre des Groupes",
    "Manage blocked contacts": "Gérer les contacts bloqués",
    "Messaging Help": "Aide de Messagerie",
    "Popular Chats": "Discussions Populaires",
    "Privacy and notification preferences": "Préférences de confidentialité et de notification",
    "Tips and support for messaging": "Conseils et support pour la messagerie",
    
    # Messaging - reporting
    "Report ${user.displayName} for inappropriate behavior?": "Signaler ${user.displayName} pour comportement inapproprié?",
    "User reported successfully": "Utilisateur signalé avec succès",
    "Chat deleted": "Discussion supprimée",
    
    # Messaging - settings toggles
    "Show Message Previews": "Afficher les Aperçus de Messages",
    "Mute Notifications": "Couper les Notifications",
    "No messages found.": "Aucun message trouvé.",
    "No results.": "Aucun résultat.",
    "Get notified about new messages": "Être notifié des nouveaux messages",
    "Automatically download photos and videos": "Télécharger automatiquement photos et vidéos",
    "Chat history cleared": "Historique des discussions effacé",
    "Sending media...": "Envoi du média...",
    
    # Broadcast
    "Send Broadcast Message": "Envoyer un Message Diffusé",
    "Broadcast message sent successfully": "Message diffusé envoyé avec succès",
    
    # Messaging dashboard
    "Messaging Dashboard": "Tableau de Bord de Messagerie",
    "Messaging Settings": "Paramètres de Messagerie",
    "No users online": "Aucun utilisateur en ligne",
    "Push Notifications": "Notifications Push",
    "Unable to start chat: User ID not found": "Impossible de démarrer la discussion: ID utilisateur introuvable",
    "Create Group Chat": "Créer une Discussion de Groupe",
    
    # Feed management
    "Feed settings saved!": "Paramètres de flux enregistrés!",
    "Edit Artist Feed": "Modifier le Flux d'Artiste",
    "Feed Image (Coming soon)": "Image du Flux (Bientôt disponible)",
    "Posts Management (Coming soon)": "Gestion des Publications (Bientôt disponible)",
    
    # Message thread
    "Media saved to ${file.path}": "Média enregistré dans ${file.path}",
    "No messages in this thread": "Aucun message dans cette discussion",
    "Message unstarred": "Message non favori",
    "Starred Messages": "Messages Favoris",
    "Remove star": "Retirer le favori",
    
    # Reporting
    "Reporting functionality coming soon.": "Fonctionnalité de signalement bientôt disponible.",
    "User blocked": "Utilisateur bloqué",
}

def translate_french_final_4():
    """Apply FINAL_4 translations to fr.json"""
    
    print("=" * 70)
    print("French Translation - FINAL PASS 4 (COMPREHENSIVE)")
    print("=" * 70)
    
    # Load current fr.json
    with open('assets/translations/fr.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Count initial bracketed entries
    initial_count = sum(1 for v in data.values() 
                       if isinstance(v, str) and v.startswith('[') and v.endswith(']') and not v.startswith('[FR]'))
    
    print(f"Starting with {initial_count} bracketed entries\n")
    
    # Apply translations
    translated_count = 0
    for key, value in data.items():
        if isinstance(value, str) and value.startswith('[') and value.endswith(']') and not value.startswith('[FR]'):
            # Extract text from brackets
            english_text = value[1:-1]
            
            # Check if we have a translation
            if english_text in FINAL_4_TRANSLATIONS:
                french_text = FINAL_4_TRANSLATIONS[english_text]
                data[key] = french_text
                translated_count += 1
                print(f"✓ {english_text[:60]} → {french_text[:60]}")
    
    # Count remaining bracketed entries
    remaining_count = sum(1 for v in data.values() 
                         if isinstance(v, str) and v.startswith('[') and v.endswith(']') and not v.startswith('[FR]'))
    
    # Save updated fr.json
    with open('assets/translations/fr.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "=" * 70)
    print("FINAL PASS 4 SUMMARY")
    print("=" * 70)
    print(f"Translated in this pass: {translated_count}")
    print(f"Remaining: {remaining_count}")
    print(f"✓ File saved: /Users/kristybock/artbeat/assets/translations/fr.json")
    
    # Calculate total progress
    total_entries = 1397  # Known total from initial analysis
    completed = total_entries - remaining_count
    percentage = (completed / total_entries) * 100
    print(f"📊 Total progress: {completed}/{total_entries} ({percentage:.1f}%)")
    print("=" * 70)

if __name__ == "__main__":
    translate_french_final_4()
