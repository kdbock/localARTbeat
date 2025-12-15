#!/usr/bin/env python3
"""
French Translation - FINAL PASS 3
Art walks, navigation, discovery, and user interface
"""

import json

FINAL_3_TRANSLATIONS = {
    # Discovery
    "Explore art collections and galleries": "Explorer les collections d'art et les galeries",
    "Find Artists": "Trouver des Artistes",
    "Getting your location...": "Obtention de votre position...",
    "Local Scene": "Scène Locale",
    "No art nearby. Try moving to a different location!": "Aucun art à proximité. Essayez de vous déplacer vers un autre endroit!",
    "Popular artists and trending art": "Artistes populaires et art tendance",
    "View and edit your profile": "Voir et modifier votre profil",
    "Your Location": "Votre Position",
    "Error: ${e.toString()}": "Erreur: ${e.toString()}",
    
    # Art walk completion
    "Art walk completed! 🎉": "Promenade artistique terminée! 🎉",
    "Art Walk Details": "Détails de la Promenade Artistique",
    "Art Walk Not Found": "Promenade Artistique Non Trouvée",
    "The requested art walk could not be found.": "La promenade artistique demandée est introuvable.",
    "Art walk not found": "Promenade artistique introuvable",
    
    # Navigation
    "Navigation stopped": "Navigation arrêtée",
    "Start Navigation": "Démarrer la Navigation",
    "Unable to start navigation. No art pieces found.": "Impossible de démarrer la navigation. Aucune œuvre d'art trouvée.",
    "Navigation not active": "Navigation non active",
    "Navigation paused while app is in background": "Navigation en pause pendant que l'application est en arrière-plan",
    "Navigation resumed": "Navigation reprise",
    "Navigation stopped.": "Navigation arrêtée.",
    "No navigation step available": "Aucune étape de navigation disponible",
    
    # Achievements
    "You earned new achievements!": "Vous avez gagné de nouveaux succès!",
    "• Achievement progress updated": "• Progression des succès mise à jour",
    
    # Art walk management
    "You must be logged in to complete art walks": "Vous devez être connecté pour terminer les promenades artistiques",
    "Artwork added to art walk successfully": "Œuvre ajoutée à la promenade artistique avec succès",
    "Add Artwork": "Ajouter une Œuvre",
    "Edit Art Walk": "Modifier la Promenade Artistique",
    "Make this art walk visible to other users": "Rendre cette promenade artistique visible aux autres utilisateurs",
    "Public Art Walk": "Promenade Artistique Publique",
    "This artwork is already in your art walk": "Cette œuvre est déjà dans votre promenade artistique",
    
    # Search and filters
    "Search Art Walks": "Rechercher des Promenades Artistiques",
    "Apply Filters": "Appliquer les Filtres",
    "Create Art Walk": "Créer une Promenade Artistique",
    "Load More Art Walks": "Charger Plus de Promenades Artistiques",
    "Select difficulty": "Sélectionner la difficulté",
    
    # Art walk view
    "Art Walk Map": "Carte de la Promenade Artistique",
    "No captures found nearby": "Aucune capture trouvée à proximité",
    "Review Your Art Walk": "Examiner Votre Promenade Artistique",
    "View Quest History": "Voir l'Historique des Quêtes",
    "SCREEN_TITLE": "TITRE_ÉCRAN",
    
    # Art walk creation
    "Art Walk created successfully!": "Promenade artistique créée avec succès!",
    "Art Walk updated successfully!": "Promenade artistique mise à jour avec succès!",
    "Leave": "Quitter",
    "Leave Art Walk Creation?": "Quitter la Création de Promenade Artistique?",
    "No art pieces available.": "Aucune œuvre d'art disponible.",
    "Please select at least one art piece": "Veuillez sélectionner au moins une œuvre d'art",
    "Stay": "Rester",
    "Your progress will be lost.": "Votre progression sera perdue.",
    
    # Walk interaction
    "Abandon Walk": "Abandonner la Promenade",
    "Abandon Walk?": "Abandonner la Promenade?",
    "Already at the beginning of the route": "Déjà au début du parcours",
    "Claim Rewards": "Réclamer les Récompenses",
    "Complete Now": "Terminer Maintenant",
    "Complete Walk": "Terminer la Promenade",
    "Complete Walk Early?": "Terminer la Promenade Plus Tôt?",
    "Got it": "Compris",
    "How to Use": "Comment Utiliser",
    "Keep Exploring": "Continuer à Explorer",
    "Leave Walk?": "Quitter la Promenade?",
    "Pause Walk": "Mettre en Pause la Promenade",
    
    # Instructions
    "• Follow the blue route line": "• Suivez la ligne de parcours bleue",
    "• ${_formatDuration(timeSpent)} duration": "• ${_formatDuration(timeSpent)} de durée",
    "• Green markers = visited": "• Marqueurs verts = visités",
    "  ✓ Perfect completion bonus (+50 XP)": "  ✓ Bonus de complétion parfaite (+50 XP)",
}

def translate_french_final_3():
    """Apply FINAL_3 translations to fr.json"""
    
    print("=" * 70)
    print("French Translation - FINAL PASS 3")
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
            if english_text in FINAL_3_TRANSLATIONS:
                french_text = FINAL_3_TRANSLATIONS[english_text]
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
    print("FINAL PASS 3 SUMMARY")
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
    translate_french_final_3()
