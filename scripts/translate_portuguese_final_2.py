#!/usr/bin/env python3
"""
Portuguese Translation - Final Pass 2
Comprehensive remaining entries
"""

import json

PT_FINAL_2_TRANSLATIONS = {
    # Success messages
    '"${artwork.title}" has been deleted successfully': '"${artwork.title}" foi excluído com sucesso',
    "Artist profile created successfully!": "Perfil de artista criado com sucesso!",
    "Artist profile saved successfully": "Perfil de artista salvo com sucesso",
    "Artist removed from gallery successfully": "Artista removido da galeria com sucesso",
    "Broadcast message sent successfully": "Mensagem transmitida enviada com sucesso",
    "Capture approved successfully": "Captura aprovada com sucesso",
    "Capture deleted permanently": "Captura excluída permanentemente",
    "Capture deleted successfully": "Captura excluída com sucesso",
    "Capture rejected": "Captura rejeitada",
    "Capture updated successfully": "Captura atualizada com sucesso",
    "Chat deleted": "Chat excluído",
    "Chat history cleared": "Histórico de chat limpo",
    
    # UI Elements
    "+${artist.mediums.length - 2}": "+${artist.mediums.length - 2}",
    "Accept & Continue": "Aceitar e Continuar",
    "Account Type": "Tipo de Conta",
    "Add Payment Method": "Adicionar Método de Pagamento",
    "Add Post": "Adicionar Postagem",
    "Add new artwork to your portfolio": "Adicionar nova obra de arte ao seu portfólio",
    "All Time": "Todo o Tempo",
    "Announce upcoming events": "Anunciar eventos futuros",
    "Approve Capture": "Aprovar Captura",
    "Art Capture": "Captura de Arte",
    "Art Captured!": "Arte Capturada!",
    "Artist": "Artista",
    "Artist Dashboard": "Painel do Artista",
    "Artist Profile": "Perfil do Artista",
    "Artist profile not found": "Perfil de artista não encontrado",
    "Artist: ${capture.artistName!}": "Artista: ${capture.artistName!}",
    "Artwork Post": "Postagem de Obra de Arte",
    "Artwork Sold": "Obra de Arte Vendida",
    "Artwork Views": "Visualizações de Obra de Arte",
    "Automatically download photos and videos": "Baixar fotos e vídeos automaticamente",
    "Back": "Voltar",
    "Become an Artist": "Tornar-se Artista",
    "Block User": "Bloquear Usuário",
    "Blocked Users": "Usuários Bloqueados",
    "Broadcast": "Transmitir",
    "Business Plan": "Plano Empresarial",
    "Cancel Invitation": "Cancelar Convite",
    "Capture Details": "Detalhes da Captura",
    "Captures": "Capturas",
    "Chat Notifications": "Notificações de Chat",
    "Chat Settings": "Configurações de Chat",
    "Chat Theme": "Tema do Chat",
    "Clear Chat History": "Limpar Histórico de Chat",
    "Clear Filters": "Limpar Filtros",
    "Clear Search": "Limpar Pesquisa",
    "Commission": "Comissão",
    "Commission Hub": "Central de Comissões",
    "Commission Request": "Solicitação de Comissão",
    "Commission Wizard": "Assistente de Comissão",
    "Community Views": "Visualizações da Comunidade",
    "Content Moderation": "Moderação de Conteúdo",
    "Cover Image": "Imagem de Capa",
    "Create Event": "Criar Evento",
    "Create Group Chat": "Criar Chat em Grupo",
    "Creator Plan": "Plano Criador",
    "Dark": "Escuro",
    "Dashboard": "Painel",
    "Delete Capture": "Excluir Captura",
    "Delete Chat": "Excluir Chat",
    "Deleting artwork...": "Excluindo obra de arte...",
    "Discover and join art communities": "Descobrir e participar de comunidades de arte",
    "Discover art captures near you": "Descobrir capturas de arte perto de você",
    "Edit Artist Feed": "Editar Feed do Artista",
    "Edit Capture": "Editar Captura",
    
    # Confirmations
    "Are you sure you want to approve this capture?": "Tem certeza de que deseja aprovar esta captura?",
    "Are you sure you want to delete this capture?": "Tem certeza de que deseja excluir esta captura?",
    "Are you sure you want to delete this chat?": "Tem certeza de que deseja excluir este chat?",
    "Are you sure you want to reject this capture?": "Tem certeza de que deseja rejeitar esta captura?",
    
    # Error messages - Art Walk
    "Error abandoning walk: $e": "Erro ao abandonar caminhada: $e",
    "Error advancing navigation: $e": "Erro ao avançar navegação: $e",
    "Error completing walk: $e": "Erro ao concluir caminhada: $e",
    "Error deleting walk: $e": "Erro ao excluir caminhada: $e",
    "Error marking as visited: $e": "Erro ao marcar como visitado: $e",
    "Error pausing walk: $e": "Erro ao pausar caminhada: $e",
    "Error resuming walk: $e": "Erro ao retomar caminhada: $e",
    "Error stopping navigation: $e": "Erro ao parar navegação: $e",
    "Error unsaving walk: $e": "Erro ao remover salvamento da caminhada: $e",
    "Error with previous step: $e": "Erro na etapa anterior: $e",
    
    # Error messages - Artist & Profile
    "Error creating artist profile: $e": "Erro ao criar perfil de artista: $e",
    "Error getting location: ${e.toString()}": "Erro ao obter localização: ${e.toString()}",
    "Error loading analytics data: ${e.toString()}": "Erro ao carregar dados de análise: ${e.toString()}",
    "Error loading analytics: $e": "Erro ao carregar análises: $e",
    "Error loading art pieces: $e": "Erro ao carregar peças de arte: $e",
    "Error loading artist profile: $e": "Erro ao carregar perfil de artista: $e",
    "Error loading artists: $e": "Erro ao carregar artistas: $e",
    "Error loading blocked users: $e": "Erro ao carregar usuários bloqueados: $e",
    "Error loading captures: $e": "Erro ao carregar capturas: $e",
    "Error loading data: $e": "Erro ao carregar dados: $e",
    "Error loading featured artists: $e": "Erro ao carregar artistas em destaque: $e",
    "Error loading feed: $e": "Erro ao carregar feed: $e",
    "Error loading participants: $e": "Erro ao carregar participantes: $e",
    "Error loading profile: $e": "Erro ao carregar perfil: $e",
    "Error loading verified artists: $e": "Erro ao carregar artistas verificados: $e",
    "Error saving profile: $e": "Erro ao salvar perfil: $e",
    "Error searching artists: ${e.toString()}": "Erro ao pesquisar artistas: ${e.toString()}",
    "Error selecting image: ${e.toString()}": "Erro ao selecionar imagem: ${e.toString()}",
    "Error submitting review: $e": "Erro ao enviar revisão: $e",
    "Error unblocking user: $e": "Erro ao desbloquear usuário: $e",
    
    # More UI
    "Event": "Evento",
    "Event Notifications": "Notificações de Evento",
    "Event Organizer": "Organizador de Evento",
    "Events": "Eventos",
    "Events & Galleries": "Eventos e Galerias",
    "Events Feed": "Feed de Eventos",
    "Exhibition": "Exposição",
    "Expired": "Expirado",
    "Explore": "Explorar",
    "Explore Art": "Explorar Arte",
    "Export": "Exportar",
    "Featured Artist": "Artista em Destaque",
    "Featured Artists": "Artistas em Destaque",
    "Feed": "Feed",
    "Filter": "Filtrar",
    "Find": "Encontrar",
    "Find Artists": "Encontrar Artistas",
    "Flag": "Sinalizar",
    "Flagged": "Sinalizado",
    "Follow": "Seguir",
    "Followers": "Seguidores",
    "Following": "Seguindo",
    "Free": "Grátis",
    "Gallery": "Galeria",
    "Genre": "Gênero",
    "Group": "Grupo",
    "Group Chat": "Chat em Grupo",
    "Hide": "Ocultar",
    "History": "Histórico",
    "Home": "Início",
    "Invitation": "Convite",
    "Invite": "Convidar",
    "Join": "Participar",
    "Leave": "Sair",
    "Light": "Claro",
    "Like": "Curtir",
    "Likes": "Curtidas",
    "Link": "Link",
    "List": "Lista",
    "Loading": "Carregando",
    "Manage": "Gerenciar",
    "Map": "Mapa",
    "Medium": "Médio",
    "Message": "Mensagem",
    "Messages": "Mensagens",
    "More": "Mais",
    "New": "Novo",
    "Next": "Próximo",
    "None": "Nenhum",
    "Notifications": "Notificações",
    "Online": "Online",
    "Open": "Abrir",
    "Options": "Opções",
    "Overview": "Visão Geral",
    "Participant": "Participante",
    "Participants": "Participantes",
    "Pause": "Pausar",
    "Payment": "Pagamento",
    "Permissions": "Permissões",
    "Photo": "Foto",
    "Photos": "Fotos",
    "Popular": "Popular",
    "Portfolio": "Portfólio",
    "Post": "Postagem",
    "Posts": "Postagens",
    "Premium": "Premium",
    "Preview": "Visualizar",
    "Previous": "Anterior",
    "Privacy": "Privacidade",
    "Private": "Privado",
    "Profile": "Perfil",
    "Public": "Público",
    "Recent": "Recente",
    "Reject": "Rejeitar",
    "Reply": "Responder",
    "Report": "Relatar",
    "Request": "Solicitação",
    "Resume": "Retomar",
    "Review": "Revisão",
    "Reviews": "Avaliações",
    "Send": "Enviar",
    "Settings": "Configurações",
    "Share": "Compartilhar",
    "Show": "Mostrar",
    "Start": "Iniciar",
    "Stop": "Parar",
    "Subscribe": "Inscrever-se",
    "Tags": "Tags",
    "Unblock": "Desbloquear",
    "Unfollow": "Deixar de Seguir",
    "Upcoming": "Próximo",
    "Video": "Vídeo",
    "View": "Ver",
    "Views": "Visualizações",
    "Visit": "Visitar",
    "Visited": "Visitado",
    "Waiting": "Aguardando",
    "Website": "Site",
}

def translate_portuguese_final_2():
    """Apply final Portuguese translations - pass 2"""
    
    print("=" * 70)
    print("Portuguese Translation - FINAL PASS 2")
    print("=" * 70)
    
    with open('assets/translations/pt.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    initial_count = sum(1 for v in data.values() 
                       if isinstance(v, str) and v.startswith('[') and v.endswith(']') and not v.startswith('[PT]'))
    
    print(f"Starting with {initial_count} bracketed entries\n")
    
    translated_count = 0
    for key, value in data.items():
        if isinstance(value, str) and value.startswith('[') and value.endswith(']') and not value.startswith('[PT]'):
            english_text = value[1:-1]
            
            if english_text in PT_FINAL_2_TRANSLATIONS:
                portuguese_text = PT_FINAL_2_TRANSLATIONS[english_text]
                data[key] = portuguese_text
                translated_count += 1
                if translated_count <= 50:
                    print(f"✓ {english_text[:55]} → {portuguese_text[:55]}")
    
    remaining_count = sum(1 for v in data.values() 
                         if isinstance(v, str) and v.startswith('[') and v.endswith(']') and not v.startswith('[PT]'))
    
    with open('assets/translations/pt.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "=" * 70)
    print("FINAL PASS 2 SUMMARY")
    print("=" * 70)
    print(f"Translated: {translated_count}")
    print(f"Remaining: {remaining_count}")
    print(f"✓ File saved")
    
    total_entries = 1397
    completed = total_entries - remaining_count
    percentage = (completed / total_entries) * 100
    print(f"📊 Progress: {completed}/{total_entries} ({percentage:.1f}%)")
    print("=" * 70)

if __name__ == "__main__":
    translate_portuguese_final_2()
