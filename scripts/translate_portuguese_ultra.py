#!/usr/bin/env python3
"""
Portuguese Translation - ULTRA COMPREHENSIVE (All Remaining)
Based on French translation patterns
"""

import json

# Comprehensive Portuguese translations for ALL remaining entries
PT_ULTRA_TRANSLATIONS = {
    # Transactions
    "Total Refunds": "Total de Reembolsos",
    "Total Transactions": "Total de Transações",
    "Transaction Details": "Detalhes da Transação",
    
    # IP Management
    "Add": "Adicionar",
    "Add IP Range": "Adicionar Faixa de IP",
    "• Consider blocking if pattern continues": "• Considere bloquear se o padrão continuar",
    "• Monitor the IP address": "• Monitorar o endereço IP",
    "Remove Admin": "Remover Administrador",
    "• Review access logs": "• Revisar registros de acesso",
    "Role: ${roles[index]}": "Função: ${roles[index]}",
    "Severity: $severity": "Gravidade: $severity",
    "Threat marked as resolved": "Ameaça marcada como resolvida",
    "User Agent: Mozilla/5.0...": "Agente do Usuário: Mozilla/5.0...",
    "User: user_${index + 1}": "Usuário: user_${index + 1}",
    
    # Settings
    "Failed to save settings: $e": "Falha ao salvar configurações: $e",
    "Backup created successfully": "Backup criado com sucesso",
    "Cache cleared successfully": "Cache limpo com sucesso",
    "Settings reset successfully": "Configurações redefinidas com sucesso",
    "Settings saved successfully": "Configurações salvas com sucesso",
    "Admin Settings": "Configurações do Administrador",
    "Are you absolutely sure you want to proceed?": "Tem certeza absoluta de que deseja prosseguir?",
    "Are you sure you want to clear all cached data?": "Tem certeza de que deseja limpar todos os dados em cache?",
    "Backup": "Backup",
    "Backup Database": "Fazer Backup do Banco de Dados",
    "Clear": "Limpar",
    "Clear all cached data": "Limpar todos os dados em cache",
    "Clear Cache": "Limpar Cache",
    "Content Settings": "Configurações de Conteúdo",
    "Create a backup of the database": "Criar um backup do banco de dados",
    "Factory Reset": "Restauração de Fábrica",
    "Factory reset completed": "Restauração de fábrica concluída",
    "General Settings": "Configurações Gerais",
    "Maintenance Settings": "Configurações de Manutenção",
    "No settings available": "Nenhuma configuração disponível",
    "Notification Settings": "Configurações de Notificação",
    "Reset": "Redefinir",
    "Reset All Settings": "Redefinir Todas as Configurações",
    "Reset all settings to default values": "Redefinir todas as configurações para valores padrão",
    "Reset Settings": "Redefinir Configurações",
    "Security Settings": "Configurações de Segurança",
    "WARNING: This will delete all data": "AVISO: Isso excluirá todos os dados",
    "WARNING: This will delete all data and cannot be undone.": "AVISO: Isso excluirá todos os dados e não poderá ser desfeito.",
    
    # User Management
    "User Details": "Detalhes do Usuário",
    "Active Users": "Usuários Ativos",
    "Online Users": "Usuários Online",
    "Peak Today": "Pico Hoje",
    "Response Time": "Tempo de Resposta",
    "User profile updated successfully": "Perfil do usuário atualizado com sucesso",
    "Profile image removed successfully": "Imagem de perfil removida com sucesso",
    "User type updated to ${newType.name}": "Tipo de usuário atualizado para ${newType.name}",
    "By: ${_currentUser.suspendedBy}": "Por: ${_currentUser.suspendedBy}",
    "Reason: ${_currentUser.suspensionReason}": "Motivo: ${_currentUser.suspensionReason}",
    "Save Changes": "Salvar Alterações",
    
    # Coupons
    "Create New Coupon": "Criar Novo Cupom",
    "Edit Coupon": "Editar Cupom",
    "Coupon created successfully": "Cupom criado com sucesso",
    "Coupon updated successfully": "Cupom atualizado com sucesso",
    "Coupon Management": "Gerenciamento de Cupons",
    "Create and manage discount coupons": "Criar e gerenciar cupons de desconto",
    
    # Moderation
    "Art Walk Moderation": "Moderação de Caminhada de Arte",
    "Moderate art walks and manage reports": "Moderar caminhadas de arte e gerenciar relatórios",
    "Capture Moderation": "Moderação de Captura",
    "Moderate captures and manage reports": "Moderar capturas e gerenciar relatórios",
    "Content Review": "Revisão de Conteúdo",
    
    # Dashboard
    "Admin Dashboard": "Painel do Administrador",
    "Unified Dashboard": "Painel Unificado",
    "All admin functions in one place": "Todas as funções administrativas em um só lugar",
    "Business Management": "Gestão de Negócios",
    "Content Management": "Gestão de Conteúdo",
    "Management Console": "Console de Gerenciamento",
    
    # Auth
    "Please enter your email": "Digite seu e-mail",
    "Please enter your password": "Digite sua senha",
    
    # Migration
    "Migrate Geo Fields": "Migrar Campos Geográficos",
    "Rollback Migration": "Reverter Migração",
    "This will add geo fields (geohash and geopoint) to all captures with locations. This is required for instant discovery to show user captures. Continue?": "Isso adicionará campos geográficos (geohash e geopoint) a todas as capturas com localizações. Isso é necessário para que a descoberta instantânea mostre as capturas do usuário. Continuar?",
    "This will remove the new moderation status fields from all collections. This action cannot be undone. Continue?": "Isso removerá os novos campos de status de moderação de todas as coleções. Esta ação não pode ser desfeita. Continuar?",
    "This will add standardized moderation status fields to all content collections. This operation cannot be undone easily. Continue?": "Isso adicionará campos de status de moderação padronizados a todas as coleções de conteúdo. Esta operação não pode ser desfeita facilmente. Continuar?",
    "Migration failed: ${error}": "Falha na migração: ${error}",
    "Geo field migration failed: ${error}": "Falha na migração de campo geográfico: ${error}",
    "Rollback failed: ${error}": "Falha ao reverter: ${error}",
    "Moderation Status Migration": "Migração de Status de Moderação",
    "Migration completed successfully!": "Migração concluída com sucesso!",
    "Geo field migration completed successfully!": "Migração de campo geográfico concluída com sucesso!",
    "Rollback completed successfully!": "Reversão concluída com sucesso!",
    "Migrate Geo Fields for Captures": "Migrar Campos Geográficos para Capturas",
    "Refresh Status": "Atualizar Status",
    "Migration in progress...": "Migração em andamento...",
    
    # Demo/Module
    "Edit this file to add navigation buttons to module screens": "Edite este arquivo para adicionar botões de navegação às telas do módulo",
    "Uadmin Module Demo": "Demonstração do Módulo Uadmin",
    "Example Button": "Botão de Exemplo",
    "ARTbeat Uadmin Module": "Módulo Uadmin ARTbeat",
    
    # Admin actions
    "❌ Failed to approve content: $e": "❌ Falha ao aprovar conteúdo: $e",
    "❌ Failed to reject content: $e": "❌ Falha ao rejeitar conteúdo: $e",
    "Admin Command Center": "Centro de Comando Administrativo",
    "Deleted \"${content.title}\" successfully": "\"${content.title}\" excluído com sucesso",
    "Updated \"${newTitle}\" successfully": "\"${newTitle}\" atualizado com sucesso",
    "Clear Review": "Limpar Revisão",
    "Rejecting content...": "Rejeitando conteúdo...",
    "✅ Approved: ${review.title}": "✅ Aprovado: ${review.title}",
    "❌ Rejected: ${review.title}": "❌ Rejeitado: ${review.title}",
    "Amount: \\${amount}": "Valor: \\${amount}",
    
    # Search
    "Search users, content, transactions...": "Pesquisar usuários, conteúdo, transações...",
    "Admin Search": "Pesquisa Administrativa",
    "Selected content: {title}": "Conteúdo selecionado: {title}",
    "Selected transaction: {id}": "Transação selecionada: {id}",
    "New admin user added": "Novo usuário administrador adicionado",
    
    # Security
    "Active Threats": "Ameaças Ativas",
    "Detection Settings": "Configurações de Detecção",
    "Recent Security Events": "Eventos de Segurança Recentes",
    "Security Overview": "Visão Geral de Segurança",
    "Threat Detection": "Detecção de Ameaças",
    "Suspicious Login Activity": "Atividade de Login Suspeita",
    "Multiple failed login attempts from IP 192.168.1.100": "Múltiplas tentativas de login falhadas do IP 192.168.1.100",
    "Unusual Data Access Pattern": "Padrão Incomum de Acesso a Dados",
    "User accessing large amounts of user data": "Usuário acessando grandes quantidades de dados de usuário",
    "Security Center": "Centro de Segurança",
    "Error: $_error": "Erro: $_error",
    
    # Content management
    "Type: ${content.type} • Status: ${content.status}": "Tipo: ${content.type} • Status: ${content.status}",
    "By: ${review.authorName}": "Por: ${review.authorName}",
    "Type: ${review.contentType.displayName}": "Tipo: ${review.contentType.displayName}",
    "Content approved successfully": "Conteúdo aprovado com sucesso",
    "Content rejected successfully": "Conteúdo rejeitado com sucesso",
    "Chart will be implemented with fl_chart package": "O gráfico será implementado com o pacote fl_chart",
    "Edit User": "Editar Usuário",
    "Loading stats...": "Carregando estatísticas...",
    
    # Ad system
    "Ad Migration": "Migração de Anúncios",
    "Dry Run (Preview Only)": "Execução de Teste (Apenas Visualização)",
    "Migrate Ads (Overwrite Existing)": "Migrar Anúncios (Sobrescrever Existentes)",
    "Migrate Ads (Skip Existing)": "Migrar Anúncios (Pular Existentes)",
    "⚠️ Overwrite Warning": "⚠️ Aviso de Sobrescrita",
    "Ad posted successfully!": "Anúncio publicado com sucesso!",
    "Create Ad": "Criar Anúncio",
    "Promote Your Art": "Promova Sua Arte",
    "Reach Art Lovers": "Alcance Amantes de Arte",
    "Ad Content": "Conteúdo do Anúncio",
    "Image (Optional)": "Imagem (Opcional)",
    "Where to Display": "Onde Exibir",
    "Size and Duration": "Tamanho e Duração",
    "Select Size": "Selecionar Tamanho",
    "Select Duration": "Selecionar Duração",
    "Post Ad for $price": "Publicar Anúncio por $price",
    "Browse Ads": "Navegar Anúncios",
    "Ad deleted": "Anúncio excluído",
    "Delete Ad?": "Excluir Anúncio?",
    "My Ads": "Meus Anúncios",
    "This action cannot be undone.": "Esta ação não pode ser desfeita.",
    "Active Ads ({count})": "Anúncios Ativos ({count})",
    "Expired Ads ({count})": "Anúncios Expirados ({count})",
    
    # Art walks
    "Art walk deleted successfully": "Caminhada de arte excluída com sucesso",
    "Reports cleared successfully": "Relatórios limpos com sucesso",
    "Clear Reports": "Limpar Relatórios",
    "Delete Art Walk": "Excluir Caminhada de Arte",
    "Reported": "Relatado",
    "Achievement posted to community feed!": "Conquista publicada no feed da comunidade!",
    "Share Achievement": "Compartilhar Conquista",
    "Art events and spaces near you": "Eventos e espaços de arte perto de você",
    "Browse Artwork": "Navegar Obras de Arte",
    "Discover local and featured artists": "Descobrir artistas locais e em destaque",
    "Error: ${snapshot.error}": "Erro: ${snapshot.error}",
    "No results for \"${_searchController.text}\"": "Nenhum resultado para \"${_searchController.text}\"",
    "Payout #${index + 1}": "Pagamento #${index + 1}",
    "No recent activity": "Nenhuma atividade recente",
    "No recent ad activity": "Nenhuma atividade de anúncio recente",
}

def translate_portuguese_ultra():
    """Apply ultra comprehensive Portuguese translations"""
    
    print("=" * 70)
    print("Portuguese Translation - ULTRA COMPREHENSIVE")
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
            
            if english_text in PT_ULTRA_TRANSLATIONS:
                portuguese_text = PT_ULTRA_TRANSLATIONS[english_text]
                data[key] = portuguese_text
                translated_count += 1
                if translated_count <= 50:
                    print(f"✓ {english_text[:55]} → {portuguese_text[:55]}")
    
    remaining_count = sum(1 for v in data.values() 
                         if isinstance(v, str) and v.startswith('[') and v.endswith(']') and not v.startswith('[PT]'))
    
    with open('assets/translations/pt.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "=" * 70)
    print("ULTRA PASS SUMMARY")
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
    translate_portuguese_ultra()
