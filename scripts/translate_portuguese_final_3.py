#!/usr/bin/env python3
"""
Portuguese Translation - Final Pass 3
Complete remaining entries
"""

import json

PT_FINAL_3_TRANSLATIONS = {
    # Event & Export
    "Event Post": "Postagem de Evento",
    "Event saved successfully": "Evento salvo com sucesso",
    "Export Report": "Exportar Relatório",
    
    # Failed messages
    "Failed to approve capture": "Falha ao aprovar captura",
    "Failed to archive chat: $e": "Falha ao arquivar chat: $e",
    "Failed to block user: $e": "Falha ao bloquear usuário: $e",
    "Failed to cancel invitation: $e": "Falha ao cancelar convite: $e",
    "Failed to clear chat: $e": "Falha ao limpar chat: $e",
    "Failed to clear reports": "Falha ao limpar relatórios",
    "Failed to create group: ${e.toString()}": "Falha ao criar grupo: ${e.toString()}",
    "Failed to delete artwork: $e": "Falha ao excluir obra de arte: $e",
    "Failed to delete capture": "Falha ao excluir captura",
    "Failed to delete capture: $e": "Falha ao excluir captura: $e",
    "Failed to delete chat: $e": "Falha ao excluir chat: $e",
    "Failed to download media": "Falha ao baixar mídia",
    "Failed to get location: $e": "Falha ao obter localização: $e",
    "Failed to load artists": "Falha ao carregar artistas",
    "Failed to reject capture": "Falha ao rejeitar captura",
    "Failed to remove artist from gallery: $e": "Falha ao remover artista da galeria: $e",
    "Failed to report user: $e": "Falha ao relatar usuário: $e",
    "Failed to resend invitation: $e": "Falha ao reenviar convite: $e",
    "Failed to restore chat: $e": "Falha ao restaurar chat: $e",
    "Failed to save review: $e": "Falha ao salvar revisão: $e",
    "Failed to send image: ${e.toString()}": "Falha ao enviar imagem: ${e.toString()}",
    "Failed to send invitation: $e": "Falha ao enviar convite: $e",
    "Failed to send message: ${e.toString()}": "Falha ao enviar mensagem: ${e.toString()}",
    "Failed to send reply": "Falha ao enviar resposta",
    "Failed to send voice message: ${e.toString()}": "Falha ao enviar mensagem de voz: ${e.toString()}",
    "Failed to update capture": "Falha ao atualizar captura",
    
    # Feed & Filter
    "Feed Image (Coming soon)": "Imagem do Feed (Em breve)",
    "Feed settings saved!": "Configurações do feed salvas!",
    "Filter Artists": "Filtrar Artistas",
    "Filter Verified Artists": "Filtrar Artistas Verificados",
    "Find People": "Encontrar Pessoas",
    "Find art captures by location or type": "Encontrar capturas de arte por localização ou tipo",
    "Find messages and chat history": "Encontrar mensagens e histórico de chat",
    "Free Plan": "Plano Gratuito",
    
    # Gallery
    "Gallery Analytics": "Análises de Galeria",
    "Gallery Artists": "Artistas da Galeria",
    "GestureDetector was tapped!": "GestureDetector foi tocado!",
    "Get notified about new messages": "Receber notificações sobre novas mensagens",
    "Go to Dashboard": "Ir para o Painel",
    
    # Individual & Invitations
    "Individual Artist": "Artista Individual",
    "Invitation sent successfully": "Convite enviado com sucesso",
    "Join Groups": "Participar de Grupos",
    
    # Time periods
    "Last 12 Months": "Últimos 12 Meses",
    "Last 90 Days": "Últimos 90 Dias",
    "This Year": "Este Ano",
    
    # Loading & Local
    "Load More": "Carregar Mais",
    "Loading artist feed...": "Carregando feed do artista...",
    "Local Captures": "Capturas Locais",
    "Location permissions are denied": "Permissões de localização negadas",
    "Location services are disabled.": "Serviços de localização desativados.",
    
    # Management
    "Manage Subscription": "Gerenciar Assinatura",
    "Manage blocked contacts": "Gerenciar contatos bloqueados",
    
    # Media & Messaging
    "Media saved to ${file.path}": "Mídia salva em ${file.path}",
    "Message Settings": "Configurações de Mensagem",
    "Message unstarred": "Mensagem desmarcada",
    "Messaging Dashboard": "Painel de Mensagens",
    "Messaging Help": "Ajuda de Mensagens",
    "Messaging Settings": "Configurações de Mensagens",
    "Mute Notifications": "Silenciar Notificações",
    
    # My items
    "My Artwork": "Minhas Obras de Arte",
    "My Captures": "Minhas Capturas",
    
    # Navigation & New
    "Navigation": "Navegação",
    "New Chat": "Novo Chat",
    "New Group": "Novo Grupo",
    "New Message": "Nova Mensagem",
    
    # No data messages
    "No artist performance data available": "Nenhum dado de desempenho de artista disponível",
    "No artists found": "Nenhum artista encontrado",
    "No artwork available": "Nenhuma obra de arte disponível",
    "No capture found": "Nenhuma captura encontrada",
    "No data available for the selected period": "Nenhum dado disponível para o período selecionado",
    "No messages found.": "Nenhuma mensagem encontrada.",
    "No messages in this thread": "Nenhuma mensagem neste tópico",
    "No results.": "Nenhum resultado.",
    "No revenue data available for selected time period": "Nenhum dado de receita disponível para o período selecionado",
    "No users online": "Nenhum usuário online",
    
    # Paid & Pending
    "Paid Commissions": "Comissões Pagas",
    "Payment Amount:": "Valor do Pagamento:",
    "Payment ID:": "ID do Pagamento:",
    "Pending Commissions": "Comissões Pendentes",
    
    # Permissions & Popular
    "Please accept the public art disclaimer": "Aceite o aviso de arte pública",
    "Popular Captures": "Capturas Populares",
    "Popular Chats": "Chats Populares",
    "Posts Management (Coming soon)": "Gerenciamento de Postagens (Em breve)",
    "Privacy and notification preferences": "Preferências de privacidade e notificação",
    
    # Profile & Public
    "Profile Image": "Imagem de Perfil",
    "Public Event": "Evento Público",
    "Push Notifications": "Notificações Push",
    
    # Refund & Reject
    "Refund Request Submitted": "Solicitação de Reembolso Enviada",
    "Reject Capture": "Rejeitar Captura",
    "Remove star": "Remover estrela",
    
    # Report
    "Report ${user.displayName} for inappropriate behavior?": "Relatar ${user.displayName} por comportamento inadequado?",
    "Report User": "Relatar Usuário",
    "Reporting functionality coming soon.": "Funcionalidade de relatório em breve.",
    "Request Refund": "Solicitar Reembolso",
    
    # Revenue & Review
    "Revenue": "Receita",
    "Review Walk": "Revisar Caminhada",
    "Sales": "Vendas",
    
    # Save & Search
    "Save Capture": "Salvar Captura",
    "Search Captures": "Pesquisar Capturas",
    "Search Conversations": "Pesquisar Conversas",
    "Search for artists and community members": "Pesquisar artistas e membros da comunidade",
    "Search for artists and their captures": "Pesquisar artistas e suas capturas",
    
    # Select & Send
    "Select Theme": "Selecionar Tema",
    "Select Wallpaper": "Selecionar Papel de Parede",
    "Send Broadcast Message": "Enviar Mensagem de Transmissão",
    "Send Message": "Enviar Mensagem",
    "Sending media...": "Enviando mídia...",
    
    # Share
    "Share photos from your studio": "Compartilhar fotos do seu estúdio",
    "Share updates with your community": "Compartilhar atualizações com sua comunidade",
    "Share your thoughts and updates": "Compartilhar seus pensamentos e atualizações",
    
    # Show & Starred
    "Show Message Previews": "Mostrar Visualizações de Mensagem",
    "Starred Messages": "Mensagens Destacadas",
    "Starter Plan": "Plano Inicial",
    
    # Style & Submit
    "Style: $_selectedStyle": "Estilo: $_selectedStyle",
    "Styles": "Estilos",
    "Submit Refund Request": "Enviar Solicitação de Reembolso",
    
    # Subscribe & Subscription
    "Subscribe to ${_getTierName(widget.tier)}": "Inscrever-se em ${_getTierName(widget.tier)}",
    "Subscription Analytics": "Análises de Assinatura",
    "Subscription Successful": "Assinatura Bem-sucedida",
    
    # System & Take
    "System": "Sistema",
    "Take Photo": "Tirar Foto",
    
    # Tips & Total
    "Tips and support for messaging": "Dicas e suporte para mensagens",
    "Total Commissions": "Total de Comissões",
    "Try Again": "Tentar Novamente",
    
    # Type & Unable
    "Type: ${capture.artType!}": "Tipo: ${capture.artType!}",
    "Unable to start chat: User ID not found": "Não foi possível iniciar o chat: ID do usuário não encontrado",
    "Unblock User": "Desbloquear Usuário",
    
    # Upgrade & Upload
    "Upgrade to Gallery Plan": "Atualizar para Plano de Galeria",
    "Upgrade to Pro": "Atualizar para Pro",
    "Upload Artwork": "Enviar Obra de Arte",
    "Upload Capture": "Enviar Captura",
    
    # User & View
    "User blocked": "Usuário bloqueado",
    "User reported successfully": "Usuário relatado com sucesso",
    "View All Activity": "Ver Toda a Atividade",
    "View Analytics": "Ver Análises",
    "View Profile": "Ver Perfil",
    
    # Welcome & Would
    "Welcome! Setting up your profile...": "Bem-vindo! Configurando seu perfil...",
    "Would you like to finish now or continue exploring?": "Gostaria de terminar agora ou continuar explorando?",
    
    # Progress
    "• ${widget.progress.totalPointsEarned} points earned": "• ${widget.progress.totalPointsEarned} pontos ganhos",
    "• Achievement progress updated": "• Progresso de conquista atualizado",
}

def translate_portuguese_final_3():
    """Apply final Portuguese translations - pass 3"""
    
    print("=" * 70)
    print("Portuguese Translation - FINAL PASS 3")
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
            
            if english_text in PT_FINAL_3_TRANSLATIONS:
                portuguese_text = PT_FINAL_3_TRANSLATIONS[english_text]
                data[key] = portuguese_text
                translated_count += 1
                if translated_count <= 50:
                    print(f"✓ {english_text[:55]} → {portuguese_text[:55]}")
    
    remaining_count = sum(1 for v in data.values() 
                         if isinstance(v, str) and v.startswith('[') and v.endswith(']') and not v.startswith('[PT]'))
    
    with open('assets/translations/pt.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "=" * 70)
    print("FINAL PASS 3 SUMMARY")
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
    translate_portuguese_final_3()
