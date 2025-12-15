#!/usr/bin/env python3
"""
French Translation - Main Script
Translates English placeholders to French
"""

import json
import re
from pathlib import Path

FR_JSON_PATH = Path(__file__).parent.parent / 'assets' / 'translations' / 'fr.json'

# Comprehensive French translations
TRANSLATIONS = {
    # Common actions
    "Take Action": "Prendre des Mesures",
    "View Details": "Voir les Détails",
    "Approve": "Approuver",
    "Reject": "Rejeter",
    "Delete": "Supprimer",
    "Edit": "Modifier",
    "Save": "Enregistrer",
    "Cancel": "Annuler",
    "Submit": "Soumettre",
    "Confirm": "Confirmer",
    "Close": "Fermer",
    "Back": "Retour",
    "Next": "Suivant",
    "Previous": "Précédent",
    "Continue": "Continuer",
    "Skip": "Passer",
    "Done": "Terminé",
    "Finish": "Terminer",
    "Create": "Créer",
    "Add": "Ajouter",
    "Remove": "Retirer",
    "Update": "Mettre à Jour",
    "Upload": "Télécharger",
    "Download": "Télécharger",
    "Share": "Partager",
    "Send": "Envoyer",
    "Reply": "Répondre",
    "Forward": "Transférer",
    "Mark": "Marquer",
    "Flag": "Signaler",
    "Block": "Bloquer",
    "Unblock": "Débloquer",
    "Mute": "Mettre en Sourdine",
    "Unmute": "Réactiver le Son",
    "Follow": "Suivre",
    "Unfollow": "Ne Plus Suivre",
    "Like": "Aimer",
    "Unlike": "Ne Plus Aimer",
    "Comment": "Commenter",
    "Report": "Signaler",
    "Login": "Connexion",
    "Logout": "Déconnexion",
    "Sign In": "Se Connecter",
    "Sign Out": "Se Déconnecter",
    "Sign Up": "S'Inscrire",
    "Register": "S'Inscrire",
    "Search": "Rechercher",
    "Filter": "Filtrer",
    "Sort": "Trier",
    "Refresh": "Actualiser",
    "Reload": "Recharger",
    "Retry": "Réessayer",
    "Try Again": "Réessayer",
    
    # Common nouns
    "All": "Tout",
    "None": "Aucun",
    "Error": "Erreur",
    "Success": "Succès",
    "Warning": "Avertissement",
    "Info": "Information",
    "Message": "Message",
    "Messages": "Messages",
    "Notification": "Notification",
    "Notifications": "Notifications",
    "Alert": "Alerte",
    "Alerts": "Alertes",
    "Settings": "Paramètres",
    "Profile": "Profil",
    "Account": "Compte",
    "User": "Utilisateur",
    "Users": "Utilisateurs",
    "Artist": "Artiste",
    "Artists": "Artistes",
    "Artwork": "Œuvre d'Art",
    "Artworks": "Œuvres d'Art",
    "Gallery": "Galerie",
    "Galleries": "Galeries",
    "Event": "Événement",
    "Events": "Événements",
    "Comment": "Commentaire",
    "Comments": "Commentaires",
    "Review": "Avis",
    "Reviews": "Avis",
    "Rating": "Évaluation",
    "Ratings": "Évaluations",
    "Category": "Catégorie",
    "Categories": "Catégories",
    "Tag": "Étiquette",
    "Tags": "Étiquettes",
    "Description": "Description",
    "Title": "Titre",
    "Name": "Nom",
    "Email": "E-mail",
    "Password": "Mot de Passe",
    "Phone": "Téléphone",
    "Address": "Adresse",
    "Location": "Emplacement",
    "Date": "Date",
    "Time": "Heure",
    "Price": "Prix",
    "Total": "Total",
    "Subtotal": "Sous-Total",
    "Tax": "Taxe",
    "Shipping": "Livraison",
    "Discount": "Réduction",
    "Payment": "Paiement",
    "Order": "Commande",
    "Orders": "Commandes",
    "Cart": "Panier",
    "Checkout": "Passer Commande",
    "Status": "Statut",
    "Type": "Type",
    "Level": "Niveau",
    "Points": "Points",
    "Score": "Score",
    "Rank": "Rang",
    "Badge": "Badge",
    "Badges": "Badges",
    "Achievement": "Réalisation",
    "Achievements": "Réalisations",
    "Reward": "Récompense",
    "Rewards": "Récompenses",
    
    # Status messages
    "Loading": "Chargement",
    "Loading...": "Chargement...",
    "Saving": "Enregistrement",
    "Saving...": "Enregistrement...",
    "Processing": "Traitement",
    "Processing...": "Traitement...",
    "Uploading": "Téléchargement",
    "Downloading": "Téléchargement",
    "Sending": "Envoi",
    "Pending": "En Attente",
    "Pending Review": "En Attente de Révision",
    "Approved": "Approuvé",
    "Rejected": "Rejeté",
    "Flagged": "Signalé",
    "Active": "Actif",
    "Inactive": "Inactif",
    "Enabled": "Activé",
    "Disabled": "Désactivé",
    "Online": "En Ligne",
    "Offline": "Hors Ligne",
    "Available": "Disponible",
    "Unavailable": "Indisponible",
    "Open": "Ouvert",
    "Closed": "Fermé",
    "Public": "Public",
    "Private": "Privé",
    "Draft": "Brouillon",
    "Published": "Publié",
    "Archived": "Archivé",
    "Deleted": "Supprimé",
    "Verified": "Vérifié",
    "Unverified": "Non Vérifié",
    "Featured": "En Vedette",
    "New": "Nouveau",
    "Popular": "Populaire",
    "Trending": "Tendances",
    "Recommended": "Recommandé",
    
    # Empty states
    "No flagged ads": "Aucune annonce signalée",
    "No ads pending review": "Aucune annonce en attente de révision",
    "No pending reports": "Aucun rapport en attente",
    "No results": "Aucun résultat",
    "No data": "Aucune donnée",
    "No items": "Aucun élément",
    "No content": "Aucun contenu",
    "No messages": "Aucun message",
    "No notifications": "Aucune notification",
    "No alerts": "Aucune alerte",
    "No events": "Aucun événement",
    "No users": "Aucun utilisateur",
    "No artists": "Aucun artiste",
    "No artworks": "Aucune œuvre d'art",
    "No galleries": "Aucune galerie",
    "No comments": "Aucun commentaire",
    "No reviews": "Aucun avis",
    
    # Admin and management
    "Advertisement Management": "Gestion des Publicités",
    "Content Moderation": "Modération du Contenu",
    "User Management": "Gestion des Utilisateurs",
    "Analytics": "Analytique",
    "Dashboard": "Tableau de Bord",
    "Reports": "Rapports",
    "Statistics": "Statistiques",
    "Overview": "Aperçu",
    "Details": "Détails",
    "History": "Historique",
    "Activity": "Activité",
    "Logs": "Journaux",
    "Admin": "Administrateur",
    "Moderator": "Modérateur",
    "Manager": "Gestionnaire",
    "Administrator": "Administrateur",
}

def translate_french():
    """Apply French translations"""
    print(f"{'='*70}")
    print(f"French Translation - Main Pass")
    print(f"{'='*70}\n")
    
    with open(FR_JSON_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"Total entries: {len(data)}")
    
    # Find bracketed entries
    bracketed = [(k, v) for k, v in data.items() if isinstance(v, str) and v.startswith('[') and v.endswith(']')]
    print(f"Bracketed entries: {len(bracketed)}\n")
    
    count = 0
    
    for key, value in list(data.items()):
        if not isinstance(value, str) or not (value.startswith('[') and value.endswith(']')):
            continue
        
        content = value[1:-1]  # Remove brackets
        
        # Direct match
        if content in TRANSLATIONS:
            data[key] = TRANSLATIONS[content]
            count += 1
            if count <= 100:
                print(f"✓ {content} → {data[key]}")
    
    # Save
    with open(FR_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    # Check remaining
    remaining = [(k, v) for k, v in data.items() if isinstance(v, str) and v.startswith('[') and v.endswith(']')]
    
    print(f"\n{'='*70}")
    print(f"SUMMARY")
    print(f"{'='*70}")
    print(f"Translated: {count}")
    print(f"Remaining: {len(remaining)}")
    print(f"✓ File saved: {FR_JSON_PATH}")
    
    percentage = ((len(bracketed) - len(remaining)) / len(bracketed)) * 100 if len(bracketed) > 0 else 0
    print(f"📊 Progress: {len(bracketed) - len(remaining)}/{len(bracketed)} ({percentage:.1f}%)")
    print(f"{'='*70}\n")

if __name__ == "__main__":
    translate_french()
