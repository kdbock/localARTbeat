#!/usr/bin/env python3
"""
Portuguese Translation - Pass 1
Common actions, admin, transactions, and basic UI elements
"""

import json

PT_TRANSLATIONS_1 = {
    # Common actions
    "Take Action": "Tomar Ação",
    "Approve": "Aprovar",
    "Reject": "Rejeitar",
    "Delete": "Excluir",
    "Cancel": "Cancelar",
    "Close": "Fechar",
    "Flag": "Sinalizar",
    "Login": "Entrar",
    "Save": "Salvar",
    "Edit": "Editar",
    "View Details": "Ver Detalhes",
    "Retry": "Tentar Novamente",
    
    # Common status
    "All": "Todos",
    "Pending Review": "Revisão Pendente",
    "Flagged": "Sinalizado",
    "Reports": "Relatórios",
    "Approved": "Aprovado",
    "Rejected": "Rejeitado",
    
    # Admin management
    "Advertisement Management": "Gerenciamento de Anúncios",
    "Artwork Management": "Gerenciamento de Obras",
    "No flagged ads": "Nenhum anúncio sinalizado",
    "No ads pending review": "Nenhum anúncio aguardando revisão",
    "No pending reports": "Nenhum relatório pendente",
    "No artwork found": "Nenhuma obra encontrada",
    
    # Admin actions
    "Approved via admin dashboard": "Aprovado via painel administrativo",
    "Action taken by admin": "Ação tomada pelo administrador",
    "Report dismissed by admin": "Relatório rejeitado pelo administrador",
    "Ad \"{title}\" approved successfully": "Anúncio \"{title}\" aprovado com sucesso",
    "Ad \"{title}\" rejected": "Anúncio \"{title}\" rejeitado",
    "Artwork deleted": "Obra excluída",
    "Comment deleted": "Comentário excluído",
    
    # Delete confirmations
    "Delete Artwork": "Excluir Obra",
    "Delete Comment": "Excluir Comentário",
    "Reject Artwork": "Rejeitar Obra",
    
    # Errors
    "Error: $e": "Erro: $e",
    "Error loading artwork: $e": "Erro ao carregar obra: $e",
    "Error loading details: $e": "Erro ao carregar detalhes: $e",
    "Failed to approve ad: {error}": "Falha ao aprovar anúncio: {error}",
    "Failed to load ad management data: {error}": "Falha ao carregar dados de gerenciamento de anúncios: {error}",
    "Failed to reject ad: {error}": "Falha ao rejeitar anúncio: {error}",
    
    # Form fields
    "Description": "Descrição",
    "Title": "Título",
    "Select artwork to view details": "Selecione uma obra para ver detalhes",
    
    # Status updates
    "Artwork status updated to $newStatus": "Status da obra atualizado para $newStatus",
    
    # Transactions
    "Click below to copy CSV content:": "Clique abaixo para copiar conteúdo CSV:",
    "Mark as Failed": "Marcar como Falhou",
    "Download $fileName": "Baixar $fileName",
    "User: ${transaction.userName}": "Usuário: ${transaction.userName}",
    "Description: ${transaction.description}": "Descrição: ${transaction.description}",
    "Amount: ${transaction.formattedAmount}": "Valor: ${transaction.formattedAmount}",
    "Are you sure you want to process this refund?": "Tem certeza de que deseja processar este reembolso?",
    "Avg Transaction": "Transação Média",
    "Bulk Refund": "Reembolso em Massa",
    "Clear All Filters": "Limpar Todos os Filtros",
    "Copy to Clipboard": "Copiar para Área de Transferência",
    "CSV content copied to clipboard": "Conteúdo CSV copiado para área de transferência",
    "Date Range": "Intervalo de Datas",
}

def translate_portuguese_1():
    """Apply first batch of Portuguese translations"""
    
    print("=" * 70)
    print("Portuguese Translation - Pass 1")
    print("=" * 70)
    
    # Load current pt.json
    with open('assets/translations/pt.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Count initial bracketed entries
    initial_count = sum(1 for v in data.values() 
                       if isinstance(v, str) and v.startswith('[') and v.endswith(']') and not v.startswith('[PT]'))
    
    print(f"Starting with {initial_count} bracketed entries\n")
    
    # Apply translations
    translated_count = 0
    for key, value in data.items():
        if isinstance(value, str) and value.startswith('[') and value.endswith(']') and not value.startswith('[PT]'):
            english_text = value[1:-1]
            
            if english_text in PT_TRANSLATIONS_1:
                portuguese_text = PT_TRANSLATIONS_1[english_text]
                data[key] = portuguese_text
                translated_count += 1
                print(f"✓ {english_text[:60]} → {portuguese_text[:60]}")
    
    # Count remaining
    remaining_count = sum(1 for v in data.values() 
                         if isinstance(v, str) and v.startswith('[') and v.endswith(']') and not v.startswith('[PT]'))
    
    # Save
    with open('assets/translations/pt.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "=" * 70)
    print("PASS 1 SUMMARY")
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
    translate_portuguese_1()
