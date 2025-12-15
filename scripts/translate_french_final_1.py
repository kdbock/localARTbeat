#!/usr/bin/env python3
"""
French Translation - FINAL PASS 1
Targeting remaining 663 entries with comprehensive patterns
"""

import json

FINAL_1_TRANSLATIONS = {
    # Common admin/settings patterns
    "Admin Settings": "Paramètres d'Administration",
    "General Settings": "Paramètres Généraux",
    "Maintenance Settings": "Paramètres de Maintenance",
    "Notification Settings": "Paramètres de Notification",
    "Security Settings": "Paramètres de Sécurité",
    "Content Settings": "Paramètres de Contenu",
    "Reset Settings": "Réinitialiser les Paramètres",
    "Save Changes": "Enregistrer les Modifications",
    
    # Backup and cache
    "Backup Database": "Sauvegarder la Base de Données",
    "Clear Cache": "Vider le Cache",
    "Clear all cached data": "Effacer toutes les données mises en cache",
    "Cache cleared successfully": "Cache vidé avec succès",
    "Create a backup of the database": "Créer une sauvegarde de la base de données",
    "Are you sure you want to clear all cached data?": "Êtes-vous sûr de vouloir effacer toutes les données mises en cache?",
    "Settings saved successfully": "Paramètres enregistrés avec succès",
    "Settings reset successfully": "Paramètres réinitialisés avec succès",
    "Factory reset completed": "Réinitialisation d'usine terminée",
    
    # Warnings
    "WARNING: This will delete all data": "ATTENTION: Cela supprimera toutes les données",
    "WARNING: This will delete all data and cannot be undone.": "ATTENTION: Cela supprimera toutes les données et ne peut pas être annulé.",
    
    # User management
    "User Details": "Détails de l'Utilisateur",
    "Active Users": "Utilisateurs Actifs",
    "Online Users": "Utilisateurs en Ligne",
    "Peak Today": "Pic Aujourd'hui",
    "Response Time": "Temps de Réponse",
    "User profile updated successfully": "Profil utilisateur mis à jour avec succès",
    "Profile image removed successfully": "Image de profil supprimée avec succès",
    "User type updated to ${newType.name}": "Type d'utilisateur mis à jour en ${newType.name}",
    "By: ${_currentUser.suspendedBy}": "Par: ${_currentUser.suspendedBy}",
    "Reason: ${_currentUser.suspensionReason}": "Raison: ${_currentUser.suspensionReason}",
    
    # Coupons
    "Create New Coupon": "Créer un Nouveau Coupon",
    "Edit Coupon": "Modifier le Coupon",
    "Coupon created successfully": "Coupon créé avec succès",
    "Coupon updated successfully": "Coupon mis à jour avec succès",
    "Coupon Management": "Gestion des Coupons",
    "Create and manage discount coupons": "Créer et gérer les coupons de réduction",
    
    # Moderation
    "Art Walk Moderation": "Modération des Promenades Artistiques",
    "Moderate art walks and manage reports": "Modérer les promenades artistiques et gérer les signalements",
    "Capture Moderation": "Modération des Captures",
    "Moderate captures and manage reports": "Modérer les captures et gérer les signalements",
    "Content Review": "Révision du Contenu",
    
    # Dashboard
    "Admin Dashboard": "Tableau de Bord Administrateur",
    "Unified Dashboard": "Tableau de Bord Unifié",
    "All admin functions in one place": "Toutes les fonctions d'administration en un seul endroit",
    "Business Management": "Gestion d'Entreprise",
    "Content Management": "Gestion du Contenu",
    "Management Console": "Console de Gestion",
    
    # Auth
    "Please enter your email": "Veuillez entrer votre e-mail",
    "Please enter your password": "Veuillez entrer votre mot de passe",
    
    # Migration
    "Migrate Geo Fields": "Migrer les Champs Géo",
    "Rollback Migration": "Annuler la Migration",
    "This will add geo fields (geohash and geopoint) to all captures with locations. This is required for instant discovery to show user captures. Continue?": "Cela ajoutera des champs géo (geohash et geopoint) à toutes les captures avec des emplacements. Ceci est requis pour que la découverte instantanée affiche les captures des utilisateurs. Continuer?",
    "This will remove the new moderation status fields from all collections. This action cannot be undone. Continue?": "Cela supprimera les nouveaux champs de statut de modération de toutes les collections. Cette action ne peut pas être annulée. Continuer?",
    
    # Demo/Module
    "Edit this file to add navigation buttons to module screens": "Modifier ce fichier pour ajouter des boutons de navigation aux écrans de module",
    "Uadmin Module Demo": "Démo du Module Uadmin",
    "Example Button": "Bouton d'Exemple",
    "ARTbeat Uadmin Module": "Module Uadmin ARTbeat",
    
    # Security
    "Threat marked as resolved": "Menace marquée comme résolue",
    "Severity: $severity": "Gravité: $severity",
    
    # Common actions
    "Download $fileName": "Télécharger $fileName",
    "Artwork status updated to $newStatus": "Statut de l'œuvre mis à jour en $newStatus",
    
    # Transaction details (with variables)
    "User: ${transaction.userName}": "Utilisateur: ${transaction.userName}",
    "Description: ${transaction.description}": "Description: ${transaction.description}",
    "Amount: ${transaction.formattedAmount}": "Montant: ${transaction.formattedAmount}",
    "Payment Method: ${transaction.paymentMethod}": "Méthode de Paiement: ${transaction.paymentMethod}",
    "Transaction ID: ${transaction.id}": "ID de Transaction: ${transaction.id}",
    "Transaction: ${transaction.id}": "Transaction: ${transaction.id}",
    
    # Roles and users
    "Role: ${roles[index]}": "Rôle: ${roles[index]}",
    "User: user_${index + 1}": "Utilisateur: user_${index + 1}",
    
    # Error patterns
    "Error: $e": "Erreur: $e",
    
    # Bullet points
    "• Review access logs": "• Consulter les journaux d'accès",
}

def translate_french_final_1():
    """Apply FINAL_1 translations to fr.json"""
    
    print("=" * 70)
    print("French Translation - FINAL PASS 1")
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
            if english_text in FINAL_1_TRANSLATIONS:
                french_text = FINAL_1_TRANSLATIONS[english_text]
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
    print("FINAL PASS 1 SUMMARY")
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
    translate_french_final_1()
