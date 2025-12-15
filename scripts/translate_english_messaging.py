#!/usr/bin/env python3
"""
Portuguese Translation - Translate Remaining English Messaging Entries
"""

import json

ENGLISH_TO_PORTUGUESE = {
    # Messaging errors
    "Failed to block user": "Falha ao bloquear usuário",
    "Error loading chat": "Erro ao carregar chat",
    "Failed to create group": "Falha ao criar grupo",
    "Failed to leave group": "Falha ao sair do grupo",
    "Failed to load contacts": "Falha ao carregar contatos",
    "Failed to load messages": "Falha ao carregar mensagens",
    "Error loading chats": "Erro ao carregar chats",
    "Failed to send message": "Falha ao enviar mensagem",
    "Failed to unblock user": "Falha ao desbloquear usuário",
    
    # Files and filters
    "Files": "Arquivos",
    "All": "Todos",
    "Artists": "Artistas",
    "Collectors": "Colecionadores",
    "Galleries": "Galerias",
    
    # Group chat
    "Group Chat": "Chat em Grupo",
    "Group created successfully": "Grupo criado com sucesso",
    "Create Group": "Criar Grupo",
    "Group Description (optional)": "Descrição do Grupo (opcional)",
    "Group Info": "Informações do Grupo",
    "Group Name": "Nome do Grupo",
    "Groups": "Grupos",
    "Leave Group": "Sair do Grupo",
    
    # Chat
    "Chat Info": "Informações do Chat",
    "Chat not found": "Chat não encontrado",
    "Chat Settings": "Configurações de Chat",
    "New Chat": "Novo Chat",
    "Recent Chats": "Chats Recentes",
    
    # Messages
    "Messages": "Mensagens",
    "Message": "Mensagem",
    "Message sent": "Mensagem enviada",
    "New Message": "Nova Mensagem",
    "No messages yet": "Ainda sem mensagens",
    "Search Messages": "Pesquisar Mensagens",
    "Video Message": "Mensagem de Vídeo",
    "Voice Message": "Mensagem de Voz",
    
    # Users and blocking
    "Allow Messages": "Permitir Mensagens",
    "Block User": "Bloquear Usuário",
    "Blocked Users": "Usuários Bloqueados",
    "Are you sure you want to block this user?": "Tem certeza de que deseja bloquear este usuário?",
    "Are you sure you want to unblock this user?": "Tem certeza de que deseja desbloquear este usuário?",
    "Unblock": "Desbloquear",
    "User blocked successfully": "Usuário bloqueado com sucesso",
    "User unblocked successfully": "Usuário desbloqueado com sucesso",
    "No blocked users": "Nenhum usuário bloqueado",
    "No contacts found": "Nenhum contato encontrado",
    "Online Users": "Usuários Online",
    
    # Loading and searching
    "Loading conversations...": "Carregando conversas...",
    "Search contacts...": "Pesquisar contatos...",
    "Media saved successfully": "Mídia salva com sucesso",
}

def translate_english_messaging():
    """Translate remaining English messaging entries to Portuguese"""
    
    print("=" * 70)
    print("Portuguese Translation - ENGLISH MESSAGING CLEANUP")
    print("=" * 70)
    
    with open('assets/translations/pt.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    translated_count = 0
    for key, value in data.items():
        if isinstance(value, str) and value in ENGLISH_TO_PORTUGUESE:
            portuguese_text = ENGLISH_TO_PORTUGUESE[value]
            data[key] = portuguese_text
            translated_count += 1
            if translated_count <= 50:
                print(f"✓ {value[:50]} → {portuguese_text[:50]}")
    
    with open('assets/translations/pt.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "=" * 70)
    print("ENGLISH MESSAGING CLEANUP SUMMARY")
    print("=" * 70)
    print(f"Translated: {translated_count}")
    print(f"✓ File saved")
    print("=" * 70)

if __name__ == "__main__":
    translate_english_messaging()
