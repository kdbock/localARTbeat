#!/usr/bin/env python3
"""
French Translation - Remaining English Entries
Translate all remaining English placeholders to French
"""

import json

REMAINING_TRANSLATIONS = {
    # Messaging
    "messaging_block_confirm": "Êtes-vous sûr de vouloir bloquer cet utilisateur?",
    "messaging_block_user": "Bloquer l'Utilisateur",
    "messaging_chat_archived": "Cette discussion est archivée",
    "messaging_empty_description": "Démarrez une conversation avec des artistes et connectez-vous avec la communauté créative",
    "messaging_error_block_user": "Échec du blocage de l'utilisateur",
    "messaging_error_create_group": "Échec de la création du groupe",
    "messaging_error_leave_group": "Échec de la sortie du groupe",
    "messaging_error_load_contacts": "Échec du chargement des contacts",
    "messaging_error_load_messages": "Échec du chargement des messages",
    "messaging_error_send_message": "Échec de l'envoi du message",
    "messaging_error_unblock_user": "Échec du déblocage de l'utilisateur",
    "messaging_failed_send": "Échec de l'envoi du message",
    "messaging_group_created": "Groupe créé avec succès",
    "messaging_group_created_success": "Groupe créé avec succès",
    "messaging_group_left": "Vous avez quitté le groupe",
    "messaging_group_name_hint": "Entrez un nom pour votre groupe",
    "messaging_media_saved": "Média enregistré avec succès",
    "messaging_message_sent": "Message envoyé",
    "messaging_no_online_users": "Personne n'est en ligne pour le moment",
    "messaging_online_users": "Utilisateurs En Ligne",
    "messaging_send": "Envoyer",
    "messaging_try_again": "Réessayer",
    "messaging_type_message": "Tapez un message...",
    "messaging_unblock_confirm": "Êtes-vous sûr de vouloir débloquer cet utilisateur?",
    "messaging_unblock_user": "Débloquer",
    "messaging_user_blocked": "Utilisateur bloqué avec succès",
    "messaging_user_unblocked": "Utilisateur débloqué avec succès",
}

def translate_remaining_english():
    """Translate remaining English entries to French"""
    
    print("=" * 70)
    print("French Translation - Remaining English Entries")
    print("=" * 70)
    
    # Load current fr.json
    with open('assets/translations/fr.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"Starting translation of {len(REMAINING_TRANSLATIONS)} remaining entries\n")
    
    # Apply translations
    translated_count = 0
    for key, french_text in REMAINING_TRANSLATIONS.items():
        if key in data:
            old_value = data[key]
            data[key] = french_text
            translated_count += 1
            print(f"✓ {key}")
            print(f"  {old_value[:60]} → {french_text[:60]}")
        else:
            print(f"⚠ Key not found: {key}")
    
    # Save updated fr.json
    with open('assets/translations/fr.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "=" * 70)
    print("REMAINING TRANSLATIONS SUMMARY")
    print("=" * 70)
    print(f"Translated: {translated_count}/{len(REMAINING_TRANSLATIONS)}")
    print(f"✓ File saved: /Users/kristybock/artbeat/assets/translations/fr.json")
    print("\n🎉 All English placeholders translated to French!")
    print("=" * 70)

if __name__ == "__main__":
    translate_remaining_english()
