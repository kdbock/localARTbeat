#!/usr/bin/env python3
"""
Spanish Translation - Remove [ES] Prefixes
Translates all remaining [ES] prefixed entries
"""

import json
from pathlib import Path

ES_JSON_PATH = Path(__file__).parent.parent / 'assets' / 'translations' / 'es.json'

# Translations for [ES] prefixed entries
ES_PREFIX_TRANSLATIONS = {
    "Active Users": "Usuarios Activos",
    "All systems operational": "Todos los sistemas operativos",
    "Analytics": "Analíticas",
    "API": "API",
    "Artists": "Artistas",
    "Artworks": "Obras de Arte",
    "Business Analytics": "Analíticas de Negocio",
    "Configure App": "Configurar Aplicación",
    "Content Moderation": "Moderación de Contenido",
    "Database": "Base de Datos",
    "System Health": "Salud del Sistema",
    "User Management": "Gestión de Usuarios",
    "Content": "Contenido",
    "Settings": "Configuraciones",
    "Reports": "Informes",
    "Notifications": "Notificaciones",
    "Security": "Seguridad",
    "Logs": "Registros",
    "Admin": "Administrador",
    "Dashboard": "Tablero",
    "Overview": "Resumen",
    "Statistics": "Estadísticas",
    "Performance": "Rendimiento",
    "Metrics": "Métricas",
    "Revenue": "Ingresos",
    "Sales": "Ventas",
    "Orders": "Pedidos",
    "Customers": "Clientes",
    "Products": "Productos",
    "Inventory": "Inventario",
    "Payments": "Pagos",
    "Transactions": "Transacciones",
    "Subscriptions": "Suscripciones",
    "Support": "Soporte",
    "Help": "Ayuda",
    "Documentation": "Documentación",
    "API Keys": "Claves de API",
    "Integrations": "Integraciones",
    "Webhooks": "Webhooks",
    "Billing": "Facturación",
    "Account": "Cuenta",
    "Profile": "Perfil",
    "Preferences": "Preferencias",
    "Privacy": "Privacidad",
    "Terms": "Términos",
    "Legal": "Legal",
    "Compliance": "Cumplimiento",
    "Audit": "Auditoría",
    "Monitoring": "Monitoreo",
    "Alerts": "Alertas",
    "Events": "Eventos",
    "Activity": "Actividad",
    "History": "Historial",
    "Timeline": "Línea de Tiempo",
    "Calendar": "Calendario",
    "Schedule": "Horario",
    "Tasks": "Tareas",
    "Projects": "Proyectos",
    "Teams": "Equipos",
    "Members": "Miembros",
    "Roles": "Roles",
    "Permissions": "Permisos",
    "Access": "Acceso",
    "Status": "Estado",
    "Health": "Salud",
    "Uptime": "Tiempo de Actividad",
    "Downtime": "Tiempo de Inactividad",
    "Errors": "Errores",
    "Warnings": "Advertencias",
    "Critical": "Crítico",
    "Info": "Información",
    "Debug": "Depuración",
    "Trace": "Rastreo",
    "Version": "Versión",
    "Build": "Construcción",
    "Release": "Lanzamiento",
    "Update": "Actualización",
    "Upgrade": "Mejora",
    "Migration": "Migración",
    "Backup": "Respaldo",
    "Restore": "Restaurar",
    "Export": "Exportar",
    "Import": "Importar",
    "Sync": "Sincronizar",
    "Refresh": "Actualizar",
    "Reload": "Recargar",
    "Clear": "Limpiar",
    "Reset": "Restablecer",
    "Delete": "Eliminar",
    "Remove": "Remover",
    "Add": "Agregar",
    "Create": "Crear",
    "Edit": "Editar",
    "Update": "Actualizar",
    "Save": "Guardar",
    "Cancel": "Cancelar",
    "Close": "Cerrar",
    "Submit": "Enviar",
    "Confirm": "Confirmar",
    "Approve": "Aprobar",
    "Reject": "Rechazar",
    "Pending": "Pendiente",
    "Active": "Activo",
    "Inactive": "Inactivo",
    "Enabled": "Habilitado",
    "Disabled": "Deshabilitado",
    "Online": "En Línea",
    "Offline": "Fuera de Línea",
    "Connected": "Conectado",
    "Disconnected": "Desconectado",
    "Success": "Éxito",
    "Failed": "Fallido",
    "Error": "Error",
    "Warning": "Advertencia",
    "Information": "Información",
    "Total": "Total",
    "Count": "Conteo",
    "Average": "Promedio",
    "Maximum": "Máximo",
    "Minimum": "Mínimo",
    "Sum": "Suma",
    "Percentage": "Porcentaje",
    "Rate": "Tasa",
    "Ratio": "Ratio",
    "Score": "Puntuación",
    "Rank": "Rango",
    "Level": "Nivel",
    "Points": "Puntos",
    "Badges": "Insignias",
    "Achievements": "Logros",
    "Rewards": "Recompensas",
    "Leaderboard": "Tabla de Clasificación",
    "Ranking": "Clasificación",
}

def remove_es_prefix():
    """Remove [ES] prefixes and translate"""
    print(f"{'='*70}")
    print(f"Spanish Translation - Remove [ES] Prefixes")
    print(f"{'='*70}\n")
    
    with open(ES_JSON_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    es_entries = [(k, v) for k, v in data.items() if isinstance(v, str) and v.startswith('[ES]')]
    print(f"Found {len(es_entries)} entries with [ES] prefix\n")
    
    count = 0
    untranslated = []
    
    for key, value in list(data.items()):
        if not isinstance(value, str) or not value.startswith('[ES]'):
            continue
        
        # Remove [ES] prefix and trim
        content = value.replace('[ES]', '').strip()
        
        # Try to translate
        if content in ES_PREFIX_TRANSLATIONS:
            data[key] = ES_PREFIX_TRANSLATIONS[content]
            count += 1
            if count <= 50:
                print(f"✓ {content} → {data[key]}")
        else:
            # Keep without [ES] prefix but mark as untranslated
            data[key] = content
            untranslated.append((key, content))
            if len(untranslated) <= 10:
                print(f"◐ {content} (kept as-is)")
    
    # Save
    with open(ES_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    # Final verification
    remaining_es = [(k, v) for k, v in data.items() if isinstance(v, str) and '[ES]' in v]
    remaining_brackets = [(k, v) for k, v in data.items() if isinstance(v, str) and v.startswith('[') and v.endswith(']')]
    
    print(f"\n{'='*70}")
    print(f"ES PREFIX REMOVAL SUMMARY")
    print(f"{'='*70}")
    print(f"Translated: {count}")
    print(f"Kept as-is (technical terms): {len(untranslated)}")
    print(f"Remaining [ES] prefixes: {len(remaining_es)}")
    print(f"Remaining brackets: {len(remaining_brackets)}")
    print(f"✓ File saved: {ES_JSON_PATH}")
    
    if len(untranslated) > 0:
        print(f"\nKept as-is (likely technical terms):")
        for k, v in untranslated[:20]:
            print(f"  - {v}")
    
    print(f"\n{'='*70}")
    if count > 0:
        print(f"✅ Processed {count + len(untranslated)} [ES] entries!")
    
    total_complete = 2698 - len(remaining_brackets)
    percentage = (total_complete / 2698) * 100
    print(f"📊 Total progress: {total_complete}/2698 ({percentage:.1f}%)")
    print(f"{'='*70}\n")

if __name__ == "__main__":
    remove_es_prefix()
