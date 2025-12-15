#!/usr/bin/env python3
"""
Portuguese Translation - Remove [PT] Prefixes
Translate all [PT] prefix entries
"""

import json

PT_PREFIX_TRANSLATIONS = {
    "[PT] Active Users": "Usuários Ativos",
    "[PT] All systems operational": "Todos os sistemas operacionais",
    "[PT] Analytics": "Análises",
    "[PT] API": "API",
    "[PT] Artists": "Artistas",
    "[PT] Artworks": "Obras de Arte",
    "[PT] Business Analytics": "Análises de Negócios",
    "[PT] Configure App": "Configurar Aplicativo",
    "[PT] Content Moderation": "Moderação de Conteúdo",
    "[PT] Database": "Banco de Dados",
    "[PT] Detailed Insights": "Insights Detalhados",
    "[PT] Key Metrics": "Métricas Principais",
    "[PT] Manage Users": "Gerenciar Usuários",
    "[PT] Management Actions": "Ações de Gerenciamento",
    "[PT] Monitoring": "Monitoramento",
    "[PT] Monthly Performance": "Desempenho Mensal",
    "[PT] Normal": "Normal",
    "[PT] Online": "Online",
    "[PT] Pending": "Pendente",
    "[PT] Pending Reviews": "Avaliações Pendentes",
    "[PT] Quick Access": "Acesso Rápido",
    "[PT] Recent Activity": "Atividade Recente",
    "[PT] Sales": "Vendas",
    "[PT] Security": "Segurança",
    "[PT] Server": "Servidor",
    "[PT] Settings": "Configurações",
    "[PT] Storage": "Armazenamento",
    "[PT] Success": "Sucesso",
    "[PT] System": "Sistema",
    "[PT] System Health": "Saúde do Sistema",
    "[PT] System Overview": "Visão Geral do Sistema",
    "[PT] System Status": "Status do Sistema",
    "[PT] Total Revenue": "Receita Total",
    "[PT] Total Users": "Total de Usuários",
    "[PT] Users": "Usuários",
    "[PT] View Analytics Dashboard": "Ver Painel de Análises",
    "[PT] View details": "Ver detalhes",
    "[PT] View User Reports": "Ver Relatórios de Usuários",
    "[PT] Warning": "Aviso",
    
    # Onboarding
    "[PT] Complete": "Concluir",
    "[PT] Connect with Other Artists": "Conectar-se com Outros Artistas",
    "[PT] Continue": "Continuar",
    "[PT] Create and share your art": "Criar e compartilhar sua arte",
    "[PT] Create your profile": "Criar seu perfil",
    "[PT] Discover Art Everywhere": "Descobrir Arte em Todos os Lugares",
    "[PT] Discover art and artists": "Descobrir arte e artistas",
    "[PT] Display settings updated": "Configurações de exibição atualizadas",
    "[PT] Done": "Concluído",
    "[PT] Enter your details": "Digite seus dados",
    "[PT] Explore Local Art": "Explorar Arte Local",
    "[PT] Finish Setup": "Concluir Configuração",
    "[PT] Get Started": "Começar",
    "[PT] Join art communities": "Participar de comunidades de arte",
    "[PT] Join the Community": "Participar da Comunidade",
    "[PT] Join vibrant art communities": "Participar de comunidades de arte vibrantes",
    "[PT] Next": "Próximo",
    "[PT] Previous": "Anterior",
    "[PT] Save": "Salvar",
    "[PT] Search art by location": "Pesquisar arte por localização",
    "[PT] Set your preferences": "Definir suas preferências",
    "[PT] Setup Complete!": "Configuração Concluída!",
    "[PT] Setup your artist profile": "Configurar seu perfil de artista",
    "[PT] Share Your Art": "Compartilhar Sua Arte",
    "[PT] Share your work": "Compartilhar seu trabalho",
    "[PT] Show me around": "Mostre-me os arredores",
    "[PT] Skip": "Pular",
    "[PT] Skip for now": "Pular por enquanto",
    "[PT] Start": "Iniciar",
    "[PT] Start Exploring": "Começar a Explorar",
    "[PT] Update Profile": "Atualizar Perfil",
    "[PT] Upload artwork": "Enviar obra de arte",
    "[PT] Use art filters": "Usar filtros de arte",
    "[PT] Welcome to ARTbeat": "Bem-vindo ao ARTbeat",
    "[PT] Welcome!": "Bem-vindo!",
    "[PT] You're all set!": "Está tudo pronto!",
    
    # Profile & Account
    "[PT] About": "Sobre",
    "[PT] Account": "Conta",
    "[PT] Admin": "Administrador",
    "[PT] Advanced": "Avançado",
    "[PT] Appearance": "Aparência",
    "[PT] Bio": "Biografia",
    "[PT] Change": "Alterar",
    "[PT] Contact": "Contato",
    "[PT] Dark Mode": "Modo Escuro",
    "[PT] Edit": "Editar",
    "[PT] Enable": "Habilitar",
    "[PT] Feedback": "Feedback",
    "[PT] General": "Geral",
    "[PT] Help": "Ajuda",
    "[PT] Information": "Informação",
    "[PT] Language": "Idioma",
    "[PT] Logout": "Sair",
    "[PT] Notifications": "Notificações",
    "[PT] Password": "Senha",
    "[PT] Preferences": "Preferências",
    "[PT] Privacy": "Privacidade",
    "[PT] Profile": "Perfil",
    "[PT] Security": "Segurança",
    "[PT] Support": "Suporte",
    "[PT] Terms": "Termos",
    "[PT] Theme": "Tema",
    "[PT] Update": "Atualizar",
    "[PT] Version": "Versão",
    
    # Common actions
    "[PT] Apply": "Aplicar",
    "[PT] Close": "Fechar",
    "[PT] Delete": "Excluir",
    "[PT] Disable": "Desabilitar",
    "[PT] Download": "Baixar",
    "[PT] Refresh": "Atualizar",
    "[PT] Reset": "Redefinir",
    "[PT] Retry": "Tentar Novamente",
    "[PT] Select": "Selecionar",
    "[PT] Submit": "Enviar",
    "[PT] Upload": "Enviar",
    
    # Remaining entries
    "[PT] Achievements": "Conquistas",
    "[PT] Add bio and profile photo": "Adicionar biografia e foto de perfil",
    "[PT] Add your bio, photo, and preferences to get started": "Adicione sua biografia, foto e preferências para começar",
    "[PT] Art Walks": "Caminhadas de Arte",
    "[PT] Begin your artistic journey today": "Comece sua jornada artística hoje",
    "[PT] Browse": "Navegar",
    "[PT] Browse, commission, and collect from local artists. Support creativity by gifting promo credits that help artists shine.": "Navegue, encomende e colecione de artistas locais. Apoie a criatividade presenteando créditos promocionais que ajudam os artistas a brilhar.",
    "[PT] Capture a beautiful moment": "Capture um belo momento",
    "[PT] Captures": "Capturas",
    "[PT] Community": "Comunidade",
    "[PT] Community Feed": "Feed da Comunidade",
    "[PT] Complete Your Profile": "Complete Seu Perfil",
    "[PT] Connect artists": "Conectar artistas",
    "[PT] Connect with Artists": "Conectar-se com Artistas",
    "[PT] Connect with artists": "Conectar-se com artistas",
    "[PT] Connect with artists and art lovers worldwide": "Conectar-se com artistas e amantes de arte em todo o mundo",
    "[PT] Connect with fellow artists": "Conectar-se com outros artistas",
    "[PT] Connect with thousands of artists and art enthusiasts": "Conectar-se com milhares de artistas e entusiastas de arte",
    "[PT] Create & Share": "Criar e Compartilhar",
    "[PT] Daily Challenge": "Desafio Diário",
    "[PT] Discover Features": "Descobrir Recursos",
    "[PT] Discover Local ARTbeat": "Descobrir ARTbeat Local",
    "[PT] Discover new art": "Descobrir nova arte",
    "[PT] Discover, Create, Connect": "Descobrir, Criar, Conectar",
    "[PT] Discover, create, and connect with art lovers worldwide": "Descubra, crie e conecte-se com amantes de arte em todo o mundo",
    "[PT] Discover. Capture. Explore.": "Descobrir. Capturar. Explorar.",
    "[PT] Events": "Eventos",
    "[PT] Explore More": "Explorar Mais",
    "[PT] Explore art nearby": "Explorar arte próxima",
    "[PT] Explore beautiful artworks from Local ARTbeat talented artists around you": "Explore belas obras de arte de artistas talentosos do ARTbeat Local ao seu redor",
    "[PT] Explore nearby": "Explorar por perto",
    "[PT] Find Friends": "Encontrar Amigos",
    "[PT] Find art": "Encontrar arte",
    "[PT] Follow guided art experiences and discover hidden gems": "Siga experiências artísticas guiadas e descubra joias escondidas",
    "[PT] Join Conversation": "Participar da Conversa",
    "[PT] Join events": "Participar de eventos",
    "[PT] Let's get you set up": "Vamos configurar você",
    "[PT] Level": "Nível",
    "[PT] Loading dashboard...": "Carregando painel...",
    "[PT] Loading...": "Carregando...",
    "[PT] Nearby Art Walks": "Caminhadas de Arte Próximas",
    "[PT] Pending Verification": "Verificação Pendente",
    "[PT] Preparing your personalized experience": "Preparando sua experiência personalizada",
    "[PT] Quick Actions": "Ações Rápidas",
    "[PT] Quick Setup": "Configuração Rápida",
    "[PT] Ready to Start?": "Pronto para Começar?",
    "[PT] Ready to explore some art?": "Pronto para explorar alguma arte?",
    "[PT] Recent Alerts": "Alertas Recentes",
    "[PT] Recent Captures": "Capturas Recentes",
    "[PT] Reports": "Relatórios",
    "[PT] Revenue": "Receita",
    "[PT] Revenue Growth": "Crescimento de Receita",
    "[PT] Review Reports": "Revisar Relatórios",
    "[PT] Server Load": "Carga do Servidor",
    "[PT] Servers": "Servidores",
    "[PT] Share your art, spark conversations, and connect through a creative feed. Chat 1-on-1 or in groups—where inspiration meets community.": "Compartilhe sua arte, inicie conversas e conecte-se através de um feed criativo. Converse individualmente ou em grupos—onde a inspiração encontra a comunidade.",
    "[PT] Share your artistic perspective with photo captures": "Compartilhe sua perspectiva artística com capturas de fotos",
    "[PT] Start Capturing": "Começar a Capturar",
    "[PT] Start an Art Walk": "Iniciar uma Caminhada de Arte",
    "[PT] Step {step} of {total}": "Passo {step} de {total}",
    "[PT] Storage Warning": "Aviso de Armazenamento",
    "[PT] Storage capacity reaching maximum": "Capacidade de armazenamento atingindo o máximo",
    "[PT] System Settings": "Configurações do Sistema",
    "[PT] Take Your First Photo": "Tire Sua Primeira Foto",
    "[PT] Turn every mural into a mission—complete quests, earn badges, and level up your art adventure.": "Transforme cada mural em uma missão—complete missões, ganhe emblemas e suba de nível em sua aventura artística.",
    "[PT] User Management": "Gerenciamento de Usuários",
    "[PT] View All": "Ver Tudo",
    "[PT] Walks": "Caminhadas",
    "[PT] Welcome back, Admin": "Bem-vindo de volta, Administrador",
    "[PT] Welcome to Artbeat": "Bem-vindo ao Artbeat",
    "[PT] Welcome to Local ARTbeat": "Bem-vindo ao ARTbeat Local",
    "[PT] Welcome, {0}!": "Bem-vindo, {0}!",
    "[PT] Welcome, {username}!": "Bem-vindo, {username}!",
    "[PT] Your Journey": "Sua Jornada",
    "[PT] Your Progress": "Seu Progresso",
    "[PT] completed": "concluído",
    "[PT] members joined": "membros participaram",
    "[PT] {count} artists online": "{count} artistas online",
}

def remove_pt_prefixes():
    """Remove [PT] prefixes and translate"""
    
    print("=" * 70)
    print("Portuguese Translation - REMOVING [PT] PREFIXES")
    print("=" * 70)
    
    with open('assets/translations/pt.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    initial_count = sum(1 for v in data.values() 
                       if isinstance(v, str) and v.startswith('[PT]'))
    
    print(f"Starting with {initial_count} [PT] prefixes\n")
    
    translated_count = 0
    for key, value in data.items():
        if isinstance(value, str) and value.startswith('[PT]'):
            if value in PT_PREFIX_TRANSLATIONS:
                portuguese_text = PT_PREFIX_TRANSLATIONS[value]
                data[key] = portuguese_text
                translated_count += 1
                if translated_count <= 50:
                    print(f"✓ {value[5:45]} → {portuguese_text[:45]}")
    
    remaining_count = sum(1 for v in data.values() 
                         if isinstance(v, str) and v.startswith('[PT]'))
    
    with open('assets/translations/pt.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "=" * 70)
    print("[PT] PREFIX REMOVAL SUMMARY")
    print("=" * 70)
    print(f"Translated: {translated_count}")
    print(f"Remaining: {remaining_count}")
    print(f"✓ File saved")
    print("=" * 70)

if __name__ == "__main__":
    remove_pt_prefixes()
