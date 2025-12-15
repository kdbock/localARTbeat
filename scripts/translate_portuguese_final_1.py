#!/usr/bin/env python3
"""
Portuguese Translation - Final Pass 1
Translating remaining system, user, and error messages
"""

import json

PT_FINAL_1_TRANSLATIONS = {
    # System Settings
    "System Settings": "Configurações do Sistema",
    "User Settings": "Configurações do Usuário",
    "Error loading system data: $e": "Erro ao carregar dados do sistema: $e",
    "Avg Session": "Sessão Média",
    "No recent alerts": "Nenhum alerta recente",
    "System Monitoring": "Monitoramento do Sistema",
    "View All": "Ver Tudo",
    
    # Profile errors
    "Failed to remove profile image: $e": "Falha ao remover imagem do perfil: $e",
    "Failed to update profile: $e": "Falha ao atualizar perfil: $e",
    "Failed to update featured status: $e": "Falha ao atualizar status em destaque: $e",
    "Failed to update user type: $e": "Falha ao atualizar tipo de usuário: $e",
    "Failed to update verification status: $e": "Falha ao atualizar status de verificação: $e",
    
    # Profile actions
    "Edit Profile": "Editar Perfil",
    "Featured": "Em Destaque",
    "Remove": "Remover",
    "Remove Profile Image": "Remover Imagem do Perfil",
    "Verified": "Verificado",
    
    # Actions
    "Create": "Criar",
    "Update": "Atualizar",
    "Confirm": "Confirmar",
    "Go Back": "Voltar",
    "Search": "Pesquisar",
    "Clear All": "Limpar Tudo",
    
    # Coupon errors
    "Failed to create coupon: {error}": "Falha ao criar cupom: {error}",
    "Failed to update coupon: {error}": "Falha ao atualizar cupom: {error}",
    
    # Dashboard sections
    "Analytics": "Análises",
    "User Management": "Gerenciamento de Usuários",
    
    # Migration errors
    "Failed to check migration status: ${error}": "Falha ao verificar status da migração: ${error}",
    "Failed to load migration status": "Falha ao carregar status da migração",
    
    # Content management errors
    "Failed to clear review: $e": "Falha ao limpar revisão: $e",
    "Failed to delete content: $e": "Falha ao excluir conteúdo: $e",
    "Failed to update content: $e": "Falha ao atualizar conteúdo: $e",
    
    # General messages
    "Error": "Erro",
    "No content found": "Nenhum conteúdo encontrado",
    "No transactions found": "Nenhuma transação encontrada",
    "No users found": "Nenhum usuário encontrado",
    
    # Ad errors
    "Failed to post ad: $e": "Falha ao publicar anúncio: $e",
    "Failed to upload image: $e": "Falha ao enviar imagem: $e",
    "Tap to select image": "Toque para selecionar imagem",
    "Select Zone": "Selecionar Zona",
    
    # Art walk errors
    "Error clearing reports: $e": "Erro ao limpar relatórios: $e",
    "Error deleting art walk: $e": "Erro ao excluir caminhada de arte: $e",
    "Error loading art walks: $e": "Erro ao carregar caminhadas de arte: $e",
    "Failed to post achievement: $e": "Falha ao publicar conquista: $e",
    "Error loading nearby art: $e": "Erro ao carregar arte próxima: $e",
    "Error completing art walk: ${e.toString()}": "Erro ao concluir caminhada de arte: ${e.toString()}",
    "Error sharing: ${e.toString()}": "Erro ao compartilhar: ${e.toString()}",
    "Failed to start navigation: $e": "Falha ao iniciar navegação: $e",
    "Error loading art walk: $e": "Erro ao carregar caminhada de arte: $e",
    "Error picking image: $e": "Erro ao escolher imagem: $e",
    "Error updating art walk: $e": "Erro ao atualizar caminhada de arte: $e",
    "Error capturing selfie: $e": "Erro ao capturar selfie: $e",
    "Error starting art walk: $e": "Erro ao iniciar caminhada de arte: $e",
    
    # Profile & trending
    "My Profile": "Meu Perfil",
    "Trending": "Em Alta",
    
    # Art walks
    "Change Cover Image": "Mudar Imagem de Capa",
    "Art Walks": "Caminhadas de Arte",
    
    # Common UI
    "Add User": "Adicionar Usuário",
    "Address": "Endereço",
    "Amount": "Valor",
    "Cancel": "Cancelar",
    "Close": "Fechar",
    "Continue": "Continuar",
    "Date": "Data",
    "Delete": "Excluir",
    "Description": "Descrição",
    "Email": "E-mail",
    "Location": "Localização",
    "Name": "Nome",
    "Notes": "Notas",
    "Phone": "Telefone",
    "Price": "Preço",
    "Refresh": "Atualizar",
    "Required": "Obrigatório",
    "Save": "Salvar",
    "Status": "Status",
    "Submit": "Enviar",
    "Title": "Título",
    "Type": "Tipo",
    "Upload": "Enviar",
    "Username": "Nome de Usuário",
    
    # Time
    "Today": "Hoje",
    "Yesterday": "Ontem",
    "Last 7 Days": "Últimos 7 Dias",
    "Last 30 Days": "Últimos 30 Dias",
    "This Month": "Este Mês",
    "Last Month": "Mês Passado",
    
    # Status
    "Active": "Ativo",
    "Inactive": "Inativo",
    "Pending": "Pendente",
    "Completed": "Concluído",
    "Failed": "Falhou",
    "Success": "Sucesso",
    
    # Confirmations
    "Are you sure?": "Tem certeza?",
    "Yes": "Sim",
    "No": "Não",
    "OK": "OK",
}

def translate_portuguese_final_1():
    """Apply final Portuguese translations - pass 1"""
    
    print("=" * 70)
    print("Portuguese Translation - FINAL PASS 1")
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
            
            if english_text in PT_FINAL_1_TRANSLATIONS:
                portuguese_text = PT_FINAL_1_TRANSLATIONS[english_text]
                data[key] = portuguese_text
                translated_count += 1
                if translated_count <= 50:
                    print(f"✓ {english_text[:55]} → {portuguese_text[:55]}")
    
    remaining_count = sum(1 for v in data.values() 
                         if isinstance(v, str) and v.startswith('[') and v.endswith(']') and not v.startswith('[PT]'))
    
    with open('assets/translations/pt.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "=" * 70)
    print("FINAL PASS 1 SUMMARY")
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
    translate_portuguese_final_1()
