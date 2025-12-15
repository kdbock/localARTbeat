#!/usr/bin/env python3
"""
Portuguese Translation - MEGA COMPREHENSIVE PASS
All remaining translations in one go
"""

import json

PT_MEGA_TRANSLATIONS = {
    # Common UI
    "Details": "Detalhes",
    "Export Selected": "Exportar Selecionados",
    "Mark as Completed": "Marcar como Concluído",
    "Mark as Pending": "Marcar como Pendente",
    "Payment Management": "Gerenciamento de Pagamentos",
    "Payment Method: ${transaction.paymentMethod}": "Método de Pagamento: ${transaction.paymentMethod}",
    "Process Bulk Refunds": "Processar Reembolsos em Massa",
    "Process Refund": "Processar Reembolso",
    "Select All": "Selecionar Tudo",
    "Total Revenue": "Receita Total",
    "Update Status": "Atualizar Status",
    "Item: ${transaction.itemTitle}": "Item: ${transaction.itemTitle}",
    "Transaction ID: ${transaction.id}": "ID da Transação: ${transaction.id}",
    "Transaction: ${transaction.id}": "Transação: ${transaction.id}",
    "\\$${entry.value.toStringAsFixed(2)}": "\\$${entry.value.toStringAsFixed(2)}",
    
    # Email and alerts
    "Email Alerts": "Alertas por E-mail",
    "Send email notifications for threats": "Enviar notificações por e-mail para ameaças",
    "Additional Details: Success": "Detalhes Adicionais: Sucesso",
    
    # IP and network
    "10.0.0.0/8": "10.0.0.0/8",
    "192.168.1.0/24": "192.168.1.0/24",
    "Audit Log Details": "Detalhes do Registro de Auditoria",
    "Automated Threat Response": "Resposta Automática a Ameaças",
    "Automatically block suspicious activity": "Bloquear automaticamente atividade suspeita",
    "Disable Account": "Desabilitar Conta",
    "Edit Permissions": "Editar Permissões",
    "IP Address: 192.168.1.${100 + index}": "Endereço IP: 192.168.1.${100 + index}",
    "IP range added to whitelist": "Faixa de IP adicionada à lista branca",
    "Log ID: LOG_${1000 + index}": "ID do Registro: LOG_${1000 + index}",
    "Monitor security events in real-time": "Monitorar eventos de segurança em tempo real",
    "Office Network": "Rede do Escritório",
    "Real-time Monitoring": "Monitoramento em Tempo Real",
    "Recommended Actions:": "Ações Recomendadas:",
    "Resolve": "Resolver",
    "VPN Network": "Rede VPN",
    "Danger Zone": "Zona de Perigo",
    
    # System monitoring
    "CPU Usage": "Uso de CPU",
    "Critical Alerts": "Alertas Críticos",
    "Memory Usage": "Uso de Memória",
    "No system alerts": "Nenhum alerta de sistema",
    "Warning Alerts": "Alertas de Aviso",
    
    # Dashboard and navigation
    "Artbeat Home": "Início Artbeat",
    "Return to main app": "Voltar ao aplicativo principal",
    "Transaction & refund management": "Gerenciamento de transações e reembolsos",
    "Admin Panel": "Painel do Administrador",
    "Access denied. Admin privileges required.": "Acesso negado. Privilégios de administrador necessários.",
    
    # Authentication
    "Authentication failed: ${message}": "Falha na autenticação: ${message}",
    "Invalid email address.": "Endereço de e-mail inválido.",
    "An unexpected error occurred: ${error}": "Ocorreu um erro inesperado: ${error}",
    "This account has been disabled.": "Esta conta foi desabilitada.",
    "No user found with this email.": "Nenhum usuário encontrado com este e-mail.",
    "Invalid password.": "Senha inválida.",
    "Please enter a valid email": "Digite um e-mail válido",
    "Password must be at least 6 characters": "A senha deve ter pelo menos 6 caracteres",
    
    # Development
    "Standalone development environment": "Ambiente de desenvolvimento independente",
    "Run Migration": "Executar Migração",
    "Data Migration": "Migração de Dados",
    "Rollback": "Reverter",
    
    # Admin actions
    "Approving content...": "Aprovando conteúdo...",
    "Failed login attempt blocked": "Tentativa de login falhou bloqueada",
    "Password policy updated": "Política de senha atualizada",
    "Security scan completed": "Verificação de segurança concluída",
    "Suspicious data access detected": "Acesso suspeito a dados detectado",
    "Blocked IPs": "IPs Bloqueados",
    "Failed Logins": "Logins Falhados",
    "Security Score": "Pontuação de Segurança",
    "Access Control": "Controle de Acesso",
    "Audit Logs": "Registros de Auditoria",
    
    # Discovery and exploration
    "Explore More": "Explorar Mais",
    "Select sorting": "Selecionar ordenação",
    "Level up your art journey!": "Suba de nível em sua jornada artística!",
    "Abandon": "Abandonar",
    "⬅️ At first step of this segment": "⬅️ No primeiro passo deste segmento",
    "• +$completionBonus XP total": "• +$completionBonus XP no total",
    "  ✓ Photo documentation bonus (+30 XP)": "  ✓ Bônus de documentação fotográfica (+30 XP)",
    "⬅️ Showing previous navigation step": "⬅️ Mostrando etapa de navegação anterior",
    "Walk paused. You can resume anytime!": "Caminhada pausada. Você pode retomar a qualquer momento!",
    "Would you like to finish now or continue exploring": "Gostaria de terminar agora ou continuar explorando",
    "• You can still claim other rewards": "• Você ainda pode reivindicar outras recompensas",
    "• ${widget.progress.totalPointsEarned} points earn": "• ${widget.progress.totalPointsEarned} pontos ganhados",
    "Medium: $_selectedMedium": "Meio: $_selectedMedium",
    
    # Artist features
    "Gift Received": "Presente Recebido",
    "Host exhibitions and gatherings": "Realizar exposições e reuniões",
    "Manage your commissions": "Gerenciar suas comissões",
    "Photo Post": "Postagem de Foto",
    "Set up commission settings": "Configurar configurações de comissão",
    "Showcase your latest creation": "Mostre sua última criação",
    "Text Post": "Postagem de Texto",
    "Track your performance": "Acompanhe seu desempenho",
    "Mediums": "Meios",
    
    # Errors and messages
    "Could not open $url": "Não foi possível abrir $url",
    "Please log in to follow artists": "Faça login para seguir artistas",
    "Please log in to send gifts": "Faça login para enviar presentes",
    "You cannot send gifts to yourself": "Você não pode enviar presentes para si mesmo",
    "Invitation cancelled": "Convite cancelado",
    "Invitation reminder sent": "Lembrete de convite enviado",
    "Please select a plan": "Selecione um plano",
    "Set as Default": "Definir como Padrão",
    "Public Art Disclaimer": "Aviso de Arte Pública",
    "Nearby Art": "Arte Próxima",
    "See trending art discoveries": "Veja descobertas de arte em alta",
    "Terms & Conditions": "Termos e Condições",
    "Unable to load artist feed": "Não foi possível carregar feed do artista",
    "See trending conversations": "Veja conversas em alta",
    
    # Settings and preferences  
    "Auto-download Media": "Download Automático de Mídia",
    "Initializing voice recorder...": "Inicializando gravador de voz...",
    "Auto-delete spam": "Excluir spam automaticamente",
    "Moderate": "Moderar",
    "Moderation features coming soon": "Recursos de moderação em breve",
    "Quiet hours": "Horário de silêncio",
    "Feed Name": "Nome do Feed",
    "Go to message": "Ir para mensagem",
    "Navigate to message in chat": "Navegar para mensagem no chat",
    
    # User dashboard (matching Spanish)
    "Browse": "Explorar",
    "Explore": "Descobrir",
    "Community": "Comunidade",
    "Your Journey": "Sua Jornada",
    "Community Feed": "Feed da Comunidade",
    
    # Art walks and quests
    "Art Walk": "Caminhada de Arte",
    "My Art Walks": "Minhas Caminhadas de Arte",
    "Create Art Walk": "Criar Caminhada de Arte",
    "Start Art Walk": "Iniciar Caminhada de Arte",
    "Complete Walk": "Completar Caminhada",
    "Pause Walk": "Pausar Caminhada",
    "Resume Walk": "Retomar Caminhada",
    "Abandon Walk": "Abandonar Caminhada",
    "View Progress": "Ver Progresso",
    "Walk Progress": "Progresso da Caminhada",
    
    # Navigation
    "Start Navigation": "Iniciar Navegação",
    "Stop Navigation": "Parar Navegação",
    "Navigation stopped": "Navegação parada",
    "Navigation Error": "Erro de Navegação",
    "Navigation not active": "Navegação não ativa",
    "Navigation paused while app is in background": "Navegação pausada enquanto o aplicativo está em segundo plano",
    "Navigation resumed": "Navegação retomada",
    "Navigation stopped.": "Navegação parada.",
    "No navigation step available": "Nenhuma etapa de navegação disponível",
    
    # Discovery
    "Explore art collections and galleries": "Explorar coleções de arte e galerias",
    "Find Artists": "Encontrar Artistas",
    "Getting your location...": "Obtendo sua localização...",
    "Local Scene": "Cena Local",
    "No art nearby. Try moving to a different location!": "Nenhuma arte próxima. Tente mover para um local diferente!",
    "Popular artists and trending art": "Artistas populares e arte em alta",
    "View and edit your profile": "Ver e editar seu perfil",
    "Your Location": "Sua Localização",
    "Error: ${e.toString()}": "Erro: ${e.toString()}",
    
    # Art walk completion
    "Art walk completed! 🎉": "Caminhada de arte concluída! 🎉",
    "Art Walk Details": "Detalhes da Caminhada de Arte",
    "Art Walk Not Found": "Caminhada de Arte Não Encontrada",
    "The requested art walk could not be found.": "A caminhada de arte solicitada não pôde ser encontrada.",
    "Art walk not found": "Caminhada de arte não encontrada",
    "Unable to start navigation. No art pieces found.": "Não foi possível iniciar a navegação. Nenhuma obra de arte encontrada.",
    "You earned new achievements!": "Você ganhou novas conquistas!",
    "You must be logged in to complete art walks": "Você deve estar conectado para completar caminhadas de arte",
    "Artwork added to art walk successfully": "Obra adicionada à caminhada de arte com sucesso",
    "Add Artwork": "Adicionar Obra",
    "Edit Art Walk": "Editar Caminhada de Arte",
    "Make this art walk visible to other users": "Tornar esta caminhada de arte visível para outros usuários",
    "Public Art Walk": "Caminhada de Arte Pública",
    "This artwork is already in your art walk": "Esta obra já está em sua caminhada de arte",
    
    # Search and filters
    "Search Art Walks": "Pesquisar Caminhadas de Arte",
    "Apply Filters": "Aplicar Filtros",
    "Load More Art Walks": "Carregar Mais Caminhadas de Arte",
    "Select difficulty": "Selecionar dificuldade",
    "Art Walk Map": "Mapa da Caminhada de Arte",
    "No captures found nearby": "Nenhuma captura encontrada próxima",
    "Review Your Art Walk": "Revisar Sua Caminhada de Arte",
    "View Quest History": "Ver Histórico de Missões",
    "SCREEN_TITLE": "TÍTULO_TELA",
    
    # Art walk creation
    "Art Walk created successfully!": "Caminhada de arte criada com sucesso!",
    "Art Walk updated successfully!": "Caminhada de arte atualizada com sucesso!",
    "Leave": "Sair",
    "Leave Art Walk Creation?": "Sair da Criação de Caminhada de Arte?",
    "No art pieces available.": "Nenhuma obra de arte disponível.",
    "Please select at least one art piece": "Selecione pelo menos uma obra de arte",
    "Stay": "Ficar",
    "Your progress will be lost.": "Seu progresso será perdido.",
    
    # Walk interaction
    "Abandon Walk?": "Abandonar Caminhada?",
    "Already at the beginning of the route": "Já no início da rota",
    "Claim Rewards": "Reivindicar Recompensas",
    "Complete Now": "Completar Agora",
    "Complete Walk Early?": "Completar Caminhada Mais Cedo?",
    "Got it": "Entendi",
    "How to Use": "Como Usar",
    "Keep Exploring": "Continuar Explorando",
    "Leave Walk?": "Sair da Caminhada?",
    
    # Instructions
    "• Follow the blue route line": "• Siga a linha de rota azul",
    "• ${_formatDuration(timeSpent)} duration": "• ${_formatDuration(timeSpent)} de duração",
    "• Green markers = visited": "• Marcadores verdes = visitados",
    "  ✓ Perfect completion bonus (+50 XP)": "  ✓ Bônus de conclusão perfeita (+50 XP)",
    "  ✓ Speed bonus (+25 XP)": "  ✓ Bônus de velocidade (+25 XP)",
    "• $photosCount photos taken": "• $photosCount fotos tiradas",
    "• Red markers = not yet visited": "• Marcadores vermelhos = ainda não visitados",
    "🎉 Walk Completed!": "🎉 Caminhada Concluída!",
    
    # Saved walks
    "No saved walks yet": "Nenhuma caminhada salva ainda",
    "Saved": "Salvo",
    "Complete your first art walk to see it here": "Complete sua primeira caminhada de arte para vê-la aqui",
    "Create Walk": "Criar Caminhada",
    "Created": "Criado",
    "Delete Walk?": "Excluir Caminhada?",
    "In Progress": "Em Progresso",
    "Log In": "Entrar",
    "No completed walks yet": "Nenhuma caminhada concluída ainda",
    "No walks created yet": "Nenhuma caminhada criada ainda",
    "No walks in progress": "Nenhuma caminhada em progresso",
    "• Perfect walk - all art found!": "• Caminhada perfeita - toda arte encontrada!",
    "Submit Review": "Enviar Avaliação",
    "🎉 You discovered all nearby art!": "🎉 Você descobriu toda a arte próxima!",
    "Weekly Goals": "Objetivos Semanais",
    
    # Analytics
    "Analytics Dashboard": "Painel de Análises",
    "No artwork data available": "Nenhum dado de obra disponível",
    "No location data available": "Nenhum dado de localização disponível",
    "No referral data available": "Nenhum dado de indicação disponível",
    "No visitor data available": "Nenhum dado de visitante disponível",
    "Unknown Artwork": "Obra Desconhecida",
    "Upgrade Now": "Atualizar Agora",
    
    # Ad management
    "Ad Campaign Management": "Gerenciamento de Campanha de Anúncios",
    "Ad Performance Analytics": "Análises de Desempenho de Anúncios",
    "Approval Status Tracking": "Rastreamento de Status de Aprovação",
    "Artist Approved Ads": "Anúncios Aprovados pelo Artista",
    "Revenue Tracking": "Rastreamento de Receita",
    "Apply": "Aplicar",
}

def translate_portuguese_mega():
    """Apply mega Portuguese translations"""
    
    print("=" * 70)
    print("Portuguese Translation - MEGA COMPREHENSIVE PASS")
    print("=" * 70)
    
    # Load current pt.json
    with open('assets/translations/pt.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Count initial
    initial_count = sum(1 for v in data.values() 
                       if isinstance(v, str) and v.startswith('[') and v.endswith(']') and not v.startswith('[PT]'))
    
    print(f"Starting with {initial_count} bracketed entries\n")
    
    # Apply translations
    translated_count = 0
    for key, value in data.items():
        if isinstance(value, str) and value.startswith('[') and value.endswith(']') and not value.startswith('[PT]'):
            english_text = value[1:-1]
            
            if english_text in PT_MEGA_TRANSLATIONS:
                portuguese_text = PT_MEGA_TRANSLATIONS[english_text]
                data[key] = portuguese_text
                translated_count += 1
                if translated_count <= 50:  # Show first 50
                    print(f"✓ {english_text[:55]} → {portuguese_text[:55]}")
    
    # Count remaining
    remaining_count = sum(1 for v in data.values() 
                         if isinstance(v, str) and v.startswith('[') and v.endswith(']') and not v.startswith('[PT]'))
    
    # Save
    with open('assets/translations/pt.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "=" * 70)
    print("MEGA PASS SUMMARY")
    print("=" * 70)
    print(f"Translated: {translated_count}")
    print(f"Remaining: {remaining_count}")
    print(f"✓ File saved: /Users/kristybock/artbeat/assets/translations/pt.json")
    
    total_entries = 1397
    completed = total_entries - remaining_count
    percentage = (completed / total_entries) * 100
    print(f"📊 Progress: {completed}/{total_entries} ({percentage:.1f}%)")
    print("=" * 70)

if __name__ == "__main__":
    translate_portuguese_mega()
