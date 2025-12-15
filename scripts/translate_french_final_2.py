#!/usr/bin/env python3
"""
French Translation - FINAL PASS 2
Targeting "No" patterns, ad system, moderation, and content management
"""

import json

FINAL_2_TRANSLATIONS = {
    # "No" patterns
    "No content found": "Aucun contenu trouvé",
    "No transactions found": "Aucune transaction trouvée",
    "No users found": "Aucun utilisateur trouvé",
    "No recent activity": "Aucune activité récente",
    "No recent ad activity": "Aucune activité publicitaire récente",
    "No results for \"${_searchController.text}\"": "Aucun résultat pour \"${_searchController.text}\"",
    
    # Migration messages
    "This will add standardized moderation status fields to all content collections. This operation cannot be undone easily. Continue?": "Cela ajoutera des champs de statut de modération standardisés à toutes les collections de contenu. Cette opération ne peut pas être annulée facilement. Continuer?",
    "Migration failed: ${error}": "Échec de la migration: ${error}",
    "Geo field migration failed: ${error}": "Échec de la migration des champs géo: ${error}",
    "Rollback failed: ${error}": "Échec de l'annulation: ${error}",
    "Moderation Status Migration": "Migration du Statut de Modération",
    "Migration completed successfully!": "Migration terminée avec succès!",
    "Geo field migration completed successfully!": "Migration des champs géo terminée avec succès!",
    "Rollback completed successfully!": "Annulation terminée avec succès!",
    "Migrate Geo Fields for Captures": "Migrer les Champs Géo pour les Captures",
    "Refresh Status": "Actualiser le Statut",
    "Migration in progress...": "Migration en cours...",
    
    # Admin actions
    "❌ Failed to approve content: $e": "❌ Échec de l'approbation du contenu: $e",
    "❌ Failed to reject content: $e": "❌ Échec du rejet du contenu: $e",
    "Admin Command Center": "Centre de Commande Administrateur",
    "Deleted \"${content.title}\" successfully": "\"${content.title}\" supprimé avec succès",
    "Updated \"${newTitle}\" successfully": "\"${newTitle}\" mis à jour avec succès",
    "Clear Review": "Effacer l'Examen",
    "Rejecting content...": "Rejet du contenu...",
    "✅ Approved: ${review.title}": "✅ Approuvé: ${review.title}",
    "❌ Rejected: ${review.title}": "❌ Rejeté: ${review.title}",
    "Navigation Error": "Erreur de Navigation",
    
    # Search
    "Search users, content, transactions...": "Rechercher utilisateurs, contenu, transactions...",
    "Admin Search": "Recherche Administrateur",
    "Selected content: {title}": "Contenu sélectionné: {title}",
    "Selected transaction: {id}": "Transaction sélectionnée: {id}",
    "New admin user added": "Nouvel utilisateur administrateur ajouté",
    
    # Security
    "Active Threats": "Menaces Actives",
    "Detection Settings": "Paramètres de Détection",
    "Recent Security Events": "Événements de Sécurité Récents",
    "Security Overview": "Aperçu de la Sécurité",
    "Threat Detection": "Détection des Menaces",
    "Suspicious Login Activity": "Activité de Connexion Suspecte",
    "Multiple failed login attempts from IP 192.168.1.100": "Plusieurs tentatives de connexion échouées depuis l'IP 192.168.1.100",
    "Unusual Data Access Pattern": "Schéma d'Accès aux Données Inhabituel",
    "User accessing large amounts of user data": "Utilisateur accédant à de grandes quantités de données utilisateur",
    "Security Center": "Centre de Sécurité",
    
    # Content management
    "Type: ${content.type} • Status: ${content.status}": "Type: ${content.type} • Statut: ${content.status}",
    "By: ${review.authorName}": "Par: ${review.authorName}",
    "Type: ${review.contentType.displayName}": "Type: ${review.contentType.displayName}",
    "Content approved successfully": "Contenu approuvé avec succès",
    "Content rejected successfully": "Contenu rejeté avec succès",
    "Chart will be implemented with fl_chart package": "Le graphique sera implémenté avec le package fl_chart",
    
    # User management
    "Edit User": "Modifier l'Utilisateur",
    "Loading stats...": "Chargement des statistiques...",
    
    # Ad system
    "Ad Migration": "Migration des Publicités",
    "Dry Run (Preview Only)": "Exécution à Blanc (Aperçu Uniquement)",
    "Migrate Ads (Overwrite Existing)": "Migrer les Publicités (Écraser les Existantes)",
    "Migrate Ads (Skip Existing)": "Migrer les Publicités (Ignorer les Existantes)",
    "⚠️ Overwrite Warning": "⚠️ Avertissement d'Écrasement",
    "Ad posted successfully!": "Publicité publiée avec succès!",
    "Create Ad": "Créer une Publicité",
    "Promote Your Art": "Promouvoir Votre Art",
    "Reach Art Lovers": "Atteindre les Amateurs d'Art",
    "Ad Content": "Contenu de la Publicité",
    "Image (Optional)": "Image (Optionnel)",
    "Where to Display": "Où Afficher",
    "Size and Duration": "Taille et Durée",
    "Select Size": "Sélectionner la Taille",
    "Select Duration": "Sélectionner la Durée",
    "Post Ad for $price": "Publier l'Annonce pour $price",
    "Browse Ads": "Parcourir les Publicités",
    "Ad deleted": "Publicité supprimée",
    "Delete Ad?": "Supprimer la Publicité?",
    "My Ads": "Mes Publicités",
    "This action cannot be undone.": "Cette action ne peut pas être annulée.",
    "Active Ads ({count})": "Publicités Actives ({count})",
    "Expired Ads ({count})": "Publicités Expirées ({count})",
    
    # Art walks
    "Art walk deleted successfully": "Promenade artistique supprimée avec succès",
    "Reports cleared successfully": "Signalements effacés avec succès",
    "Clear Reports": "Effacer les Signalements",
    "Delete Art Walk": "Supprimer la Promenade Artistique",
    "Reported": "Signalé",
    
    # Achievements and community
    "Achievement posted to community feed!": "Succès publié dans le fil de la communauté!",
    "Share Achievement": "Partager le Succès",
    
    # Discovery
    "Art events and spaces near you": "Événements et espaces artistiques près de vous",
    "Browse Artwork": "Parcourir les Œuvres",
    "Discover local and featured artists": "Découvrir les artistes locaux et en vedette",
    
    # Other patterns
    "Error: ${snapshot.error}": "Erreur: ${snapshot.error}",
    "Error: $_error": "Erreur: $_error",
    "Amount: \\${amount}": "Montant: \\${amount}",
    "Payout #${index + 1}": "Paiement #${index + 1}",
    "User Agent: Mozilla/5.0...": "Agent Utilisateur: Mozilla/5.0...",
    "\\$${entry.value.toStringAsFixed(2)}": "\\$${entry.value.toStringAsFixed(2)}",
}

def translate_french_final_2():
    """Apply FINAL_2 translations to fr.json"""
    
    print("=" * 70)
    print("French Translation - FINAL PASS 2")
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
            if english_text in FINAL_2_TRANSLATIONS:
                french_text = FINAL_2_TRANSLATIONS[english_text]
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
    print("FINAL PASS 2 SUMMARY")
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
    translate_french_final_2()
