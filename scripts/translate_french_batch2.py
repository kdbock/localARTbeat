#!/usr/bin/env python3
"""
French Translation - Batch 2
Handles error messages, complex phrases, and common patterns
"""

import json
import re
from pathlib import Path

FR_JSON_PATH = Path(__file__).parent.parent / 'assets' / 'translations' / 'fr.json'

# Additional French translations - complex phrases and patterns
ADDITIONAL_TRANSLATIONS = {
    # Error messages with "Failed to"
    "Failed to approve ad: {error}": "Échec de l'approbation de l'annonce: {error}",
    "Failed to reject ad: {error}": "Échec du rejet de l'annonce: {error}",
    "Failed to load ad management data: {error}": "Échec du chargement des données de gestion des annonces: {error}",
    
    # Common phrases
    "Approved via admin dashboard": "Approuvé via le tableau de bord administrateur",
    "Action taken by admin": "Action prise par l'administrateur",
    "Report dismissed by admin": "Rapport rejeté par l'administrateur",
    
    # Art Walk related
    "Art Walk": "Promenade Artistique",
    "Art Walks": "Promenades Artistiques",
    "Walk": "Promenade",
    "Walks": "Promenades",
    "Nearby Art Walks": "Promenades Artistiques à Proximité",
    "Start an Art Walk": "Commencer une Promenade Artistique",
    "Complete your first art walk": "Complétez votre première promenade artistique",
    
    # Settings and configuration
    "Clear": "Effacer",
    "Clear Search": "Effacer la Recherche",
    "Clear All": "Tout Effacer",
    "Clear Chat": "Effacer le Chat",
    "Clear History": "Effacer l'Historique",
    "Reset": "Réinitialiser",
    "Reset All": "Tout Réinitialiser",
    "Factory Reset": "Réinitialisation d'Usine",
    
    # View and display
    "View": "Voir",
    "View All": "Voir Tout",
    "View Profile": "Voir le Profil",
    "View Details": "Voir les Détails",
    
    # User and profile
    "User": "Utilisateur",
    "Users": "Utilisateurs",
    "Profile": "Profil",
    "My Profile": "Mon Profil",
    "Edit Profile": "Modifier le Profil",
    "User Profile": "Profil de l'Utilisateur",
    "Block User": "Bloquer l'Utilisateur",
    "Unblock User": "Débloquer l'Utilisateur",
    "Report User": "Signaler l'Utilisateur",
    
    # Capture related
    "Capture": "Capture",
    "Captures": "Captures",
    "Recent Captures": "Captures Récentes",
    "Start Capturing": "Commencer à Capturer",
    "Take Photo": "Prendre une Photo",
    "Upload Image": "Télécharger une Image",
    "Change Cover Image": "Changer l'Image de Couverture",
    "Select Image": "Sélectionner une Image",
    "Tap to select image": "Appuyez pour sélectionner une image",
    
    # Chat and messaging
    "Chat": "Chat",
    "Chats": "Chats",
    "New Chat": "Nouveau Chat",
    "New Group": "Nouveau Groupe",
    "Group Chat": "Chat de Groupe",
    "Chat Settings": "Paramètres du Chat",
    "Chat Theme": "Thème du Chat",
    "Chat Notifications": "Notifications du Chat",
    "Delete Chat": "Supprimer le Chat",
    "Clear Chat History": "Effacer l'Historique du Chat",
    "Messaging": "Messagerie",
    "Send Message": "Envoyer un Message",
    "New Message": "Nouveau Message",
    "Broadcast": "Diffusion",
    "Participants": "Participants",
    
    # Navigation and actions
    "Navigation": "Navigation",
    "Next": "Suivant",
    "Previous": "Précédent",
    "Continue": "Continuer",
    "Skip": "Passer",
    "Back": "Retour",
    "Done": "Terminé",
    "Finish": "Terminer",
    "Go Back": "Retour",
    "Try Again": "Réessayer",
    
    # Select and choose
    "Select": "Sélectionner",
    "Select All": "Tout Sélectionner",
    "Select Zone": "Sélectionner une Zone",
    "Select Theme": "Sélectionner un Thème",
    "Select Wallpaper": "Sélectionner un Fond d'Écran",
    
    # Image and media
    "Image": "Image",
    "Images": "Images",
    "Photo": "Photo",
    "Photos": "Photos",
    "Video": "Vidéo",
    "Videos": "Vidéos",
    "Media": "Médias",
    "Cover Image": "Image de Couverture",
    "Profile Image": "Image de Profil",
    
    # Refund and payment
    "Refund": "Remboursement",
    "Refunds": "Remboursements",
    "Request Refund": "Demander un Remboursement",
    "Process Refund": "Traiter le Remboursement",
    "Process Bulk Refunds": "Traiter les Remboursements en Masse",
    "Total Refunds": "Remboursements Totaux",
    "Total Transactions": "Transactions Totales",
    
    # Confirmations
    "Are you sure?": "Êtes-vous sûr?",
    "Are you sure you want to delete this?": "Êtes-vous sûr de vouloir supprimer ceci?",
    "Are you sure you want to delete this chat?": "Êtes-vous sûr de vouloir supprimer ce chat?",
    "Are you sure you want to approve this capture?": "Êtes-vous sûr de vouloir approuver cette capture?",
    "Are you sure you want to reject this capture?": "Êtes-vous sûr de vouloir rejeter cette capture?",
    
    # Loading states
    "Loading": "Chargement",
    "Loading...": "Chargement...",
    "Loading data": "Chargement des données",
    "Loading artists": "Chargement des artistes",
    "Loading captures": "Chargement des captures",
    
    # Success messages
    "successfully": "avec succès",
    "Success": "Succès",
    "Created successfully": "Créé avec succès",
    "Updated successfully": "Mis à jour avec succès",
    "Deleted successfully": "Supprimé avec succès",
    "Saved successfully": "Enregistré avec succès",
    
    # Common UI elements
    "Welcome": "Bienvenue",
    "Home": "Accueil",
    "Dashboard": "Tableau de Bord",
    "Browse": "Parcourir",
    "Explore": "Explorer",
    "Discover": "Découvrir",
    "Search": "Rechercher",
    "Filter": "Filtrer",
    "Sort": "Trier",
    "Settings": "Paramètres",
    "Help": "Aide",
    "About": "À Propos",
    "Contact": "Contact",
    "Terms": "Conditions",
    "Privacy": "Confidentialité",
    
    # Time related
    "Today": "Aujourd'hui",
    "Yesterday": "Hier",
    "Tomorrow": "Demain",
    "This Week": "Cette Semaine",
    "Last Week": "Semaine Dernière",
    "This Month": "Ce Mois-ci",
    "Last Month": "Mois Dernier",
    
    # Artwork specific
    "Artwork": "Œuvre d'Art",
    "Artworks": "Œuvres d'Art",
    "Artist": "Artiste",
    "Artists": "Artistes",
    "Gallery": "Galerie",
    "Galleries": "Galeries",
    "Exhibition": "Exposition",
    "Exhibitions": "Expositions",
    
    # Theme and appearance  
    "Dark": "Sombre",
    "Light": "Clair",
    "System": "Système",
    "Auto": "Auto",
    "Theme": "Thème",
    
    # Status
    "Active": "Actif",
    "Inactive": "Inactif",
    "Online": "En Ligne",
    "Offline": "Hors Ligne",
    "Pending": "En Attente",
    "Approved": "Approuvé",
    "Rejected": "Rejeté",
    "Completed": "Terminé",
}

def translate_batch2():
    """Apply additional French translations"""
    print(f"{'='*70}")
    print(f"French Translation - Batch 2")
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
        
        # Direct match
        if content in ADDITIONAL_TRANSLATIONS:
            data[key] = ADDITIONAL_TRANSLATIONS[content]
            count += 1
            if count <= 100:
                print(f"✓ {content[:40]} → {data[key][:40]}")
    
    # Save
    with open(FR_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    remaining_after = [(k, v) for k, v in data.items() if isinstance(v, str) and v.startswith('[') and v.endswith(']')]
    
    print(f"\n{'='*70}")
    print(f"BATCH 2 SUMMARY")
    print(f"{'='*70}")
    print(f"Translated: {count}")
    print(f"Remaining: {len(remaining_after)}")
    print(f"✓ File saved: {FR_JSON_PATH}")
    print(f"📊 Total progress: {2624 - len(remaining_after) - (2624 - 1397)}/1397")
    print(f"{'='*70}\n")

if __name__ == "__main__":
    translate_batch2()
