#!/usr/bin/env python3
"""
Spanish Translation Script for Artbeat
Automatically translates English placeholders in es.json to Spanish
"""

import json
import re
from pathlib import Path

# File paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
ES_JSON_PATH = PROJECT_ROOT / 'assets' / 'translations' / 'es.json'

# Comprehensive Spanish translation dictionary
TRANSLATIONS = {
    # Common Actions
    "Take Action": "Tomar Acción",
    "Cancel": "Cancelar",
    "Confirm": "Confirmar",
    "Delete": "Eliminar",
    "Edit": "Editar",
    "Save": "Guardar",
    "Save Changes": "Guardar Cambios",
    "Close": "Cerrar",
    "Back": "Atrás",
    "Next": "Siguiente",
    "Continue": "Continuar",
    "Finish": "Finalizar",
    "Submit": "Enviar",
    "Send": "Enviar",
    "Create": "Crear",
    "Update": "Actualizar",
    "Upload": "Subir",
    "Download": "Descargar",
    "Share": "Compartir",
    "Add": "Agregar",
    "Remove": "Eliminar",
    "Clear": "Limpiar",
    "Clear All": "Limpiar Todo",
    "Apply": "Aplicar",
    "Apply Filters": "Aplicar Filtros",
    "Retry": "Reintentar",
    "Refresh": "Actualizar",
    "View": "Ver",
    "View All": "Ver Todo",
    "View Details": "Ver Detalles",
    "Load More": "Cargar Más",
    "Approve": "Aprobar",
    "Reject": "Rechazar",
    "Dismiss": "Descartar",
    "Leave": "Salir",
    "Stay": "Quedarse",
    "Explore": "Explorar",
    "Search": "Buscar",
    "Filter": "Filtrar",
    "Sort": "Ordenar",
    
    # Navigation
    "Go Back": "Volver",
    "Start": "Iniciar",
    "Stop": "Detener",
    "Pause": "Pausar",
    "Resume": "Reanudar",
    "Skip": "Saltar",
    "Claim Rewards": "Reclamar Recompensas",
    
    # Common Nouns
    "Dashboard": "Panel de Control",
    "Profile": "Perfil",
    "Settings": "Configuración",
    "Analytics": "Análisis",
    "Management": "Gestión",
    "Overview": "Resumen",
    "Description": "Descripción",
    "Details": "Detalles",
    "Status": "Estado",
    "Type": "Tipo",
    "Category": "Categoría",
    "Location": "Ubicación",
    "Date": "Fecha",
    "Time": "Hora",
    "Duration": "Duración",
    "Size": "Tamaño",
    "Price": "Precio",
    "Amount": "Cantidad",
    "Total": "Total",
    "User": "Usuario",
    "Users": "Usuarios",
    "Artist": "Artista",
    "Artists": "Artistas",
    "Artwork": "Obra de Arte",
    "Gallery": "Galería",
    "Event": "Evento",
    "Events": "Eventos",
    "Commission": "Comisión",
    "Commissions": "Comisiones",
    "Payment": "Pago",
    "Subscription": "Suscripción",
    "Review": "Revisión",
    "Reviews": "Reseñas",
    "Report": "Reporte",
    "Reports": "Reportes",
    "Comment": "Comentario",
    "Comments": "Comentarios",
    "Message": "Mensaje",
    "Messages": "Mensajes",
    "Notification": "Notificación",
    "Notifications": "Notificaciones",
    "Navigation": "Navegación",
    
    # Status and States
    "All": "Todo",
    "None": "Ninguno",
    "Active": "Activo",
    "Inactive": "Inactivo",
    "Pending": "Pendiente",
    "Pending Review": "Revisión Pendiente",
    "Approved": "Aprobado",
    "Rejected": "Rechazado",
    "Flagged": "Marcado",
    "Completed": "Completado",
    "In Progress": "En Progreso",
    "Loading": "Cargando",
    "Loading...": "Cargando...",
    "Processing": "Procesando",
    "Processing...": "Procesando...",
    "Saving": "Guardando",
    "Saving...": "Guardando...",
    "Uploading": "Subiendo",
    "Uploading...": "Subiendo...",
    
    # Empty States
    "No flagged ads": "No hay anuncios marcados",
    "No ads pending review": "No hay anuncios pendientes de revisión",
    "No pending reports": "No hay reportes pendientes",
    "No results found": "No se encontraron resultados",
    "No data available": "No hay datos disponibles",
    "No artwork available": "No hay obras de arte disponibles",
    "No artists found": "No se encontraron artistas",
    "No events found": "No se encontraron eventos",
    "No messages yet": "Aún no hay mensajes",
    "No comments yet": "Aún no hay comentarios",
    "No notifications": "No hay notificaciones",
    
    # Errors
    "Error": "Error",
    "Failed to approve ad: {error}": "Error al aprobar anuncio: {error}",
    "Failed to reject ad: {error}": "Error al rechazar anuncio: {error}",
    "Failed to load ad management data: {error}": "Error al cargar datos de gestión de anuncios: {error}",
    "Error loading artwork: $e": "Error al cargar obra de arte: $e",
    "Error loading details: $e": "Error al cargar detalles: $e",
    "Error: $e": "Error: $e",
    
    # Success Messages
    "successfully": "exitosamente",
    "Approved via admin dashboard": "Aprobado vía panel de administración",
    "Action taken by admin": "Acción tomada por administrador",
    "Report dismissed by admin": "Reporte descartado por administrador",
    "Artwork status updated to $newStatus": "Estado de obra actualizado a $newStatus",
    "Artwork deleted": "Obra de arte eliminada",
    "Comment deleted": "Comentario eliminado",
    
    # Advertisement Management
    "Advertisement Management": "Gestión de Anuncios",
    "Ad Management": "Gestión de Anuncios",
    "My Ads": "Mis Anuncios",
    "Create Ad": "Crear Anuncio",
    "Ad deleted": "Anuncio eliminado",
    "Delete Ad?": "¿Eliminar anuncio?",
    "Active Ads ({count})": "Anuncios Activos ({count})",
    "Expired Ads ({count})": "Anuncios Expirados ({count})",
    "Ad posted successfully!": "¡Anuncio publicado exitosamente!",
    "Promote Your Art": "Promociona Tu Arte",
    "Reach Art Lovers": "Alcanza a los Amantes del Arte",
    "Browse Ads": "Explorar Anuncios",
    
    # Admin sections
    "Artwork Management": "Gestión de Obras de Arte",
    "User Management": "Gestión de Usuarios",
    "Content Moderation": "Moderación de Contenido",
    "Security Center": "Centro de Seguridad",
    "Admin Dashboard": "Panel de Administración",
    "Admin Command Center": "Centro de Comando Administrativo",
    
    # Art Walk
    "Art Walk": "Paseo de Arte",
    "Art Walks": "Paseos de Arte",
    "My Art Walks": "Mis Paseos de Arte",
    "Create Art Walk": "Crear Paseo de Arte",
    "Edit Art Walk": "Editar Paseo de Arte",
    "Delete Art Walk": "Eliminar Paseo de Arte",
    "Art Walk Details": "Detalles del Paseo de Arte",
    "Start Navigation": "Iniciar Navegación",
    "Stop Navigation": "Detener Navegación",
    "Pause Walk": "Pausar Paseo",
    "Resume Walk": "Reanudar Paseo",
    "Abandon Walk": "Abandonar Paseo",
    "Abandon Walk?": "¿Abandonar paseo?",
    "Complete Walk": "Completar Paseo",
    "Walk Progress": "Progreso del Paseo",
    "Walk completed!": "¡Paseo completado!",
    "Navigation stopped": "Navegación detenida",
    "Navigation not active": "Navegación no activa",
    "Navigation paused while app is in background": "Navegación pausada mientras la aplicación está en segundo plano",
    "Navigation resumed": "Navegación reanudada",
    "Keep Exploring": "Seguir Explorando",
    "Leave Walk?": "¿Salir del paseo?",
    "Your progress will be lost.": "Se perderá tu progreso.",
    "Art Walk created successfully!": "¡Paseo de Arte creado exitosamente!",
    "Art Walk updated successfully!": "¡Paseo de Arte actualizado exitosamente!",
    "Art walk deleted successfully": "Paseo de Arte eliminado exitosamente",
    "Art walk not found": "Paseo de Arte no encontrado",
    "Art walk completed!": "¡Paseo de Arte completado!",
    "Weekly Goals": "Objetivos Semanales",
    
    # Navigation markers and instructions
    "• Green markers = visited": "• Marcadores verdes = visitados",
    "• Red markers = not yet visited": "• Marcadores rojos = aún no visitados",
    "• Follow the blue route line": "• Sigue la línea azul de la ruta",
    "• $photosCount photos taken": "• $photosCount fotos tomadas",
    "How to Use": "Cómo Usar",
    "Getting your location...": "Obteniendo tu ubicación...",
    "Your Location": "Tu Ubicación",
    "Already at the beginning of the route": "Ya estás al inicio de la ruta",
    
    # Bonuses and achievements
    "  ✓ Perfect completion bonus (+50 XP)": "  ✓ Bonus de completado perfecto (+50 XP)",
    "  ✓ Speed bonus (+25 XP)": "  ✓ Bonus de velocidad (+25 XP)",
    "• Perfect walk - all art found!": "• ¡Paseo perfecto - todo el arte encontrado!",
    "• Achievement progress updated": "• Progreso de logros actualizado",
    "You earned new achievements!": "¡Has ganado nuevos logros!",
    "You discovered all nearby art!": "¡Has descubierto todo el arte cercano!",
    "Achievement posted to community feed!": "¡Logro publicado en el feed de la comunidad!",
    
    # Artist features
    "Artist Dashboard": "Panel del Artista",
    "Artist Profile": "Perfil del Artista",
    "Become an Artist": "Conviértete en Artista",
    "My Artwork": "Mis Obras de Arte",
    "Upload Artwork": "Subir Obra de Arte",
    "Delete Artwork": "Eliminar Obra de Arte",
    "Artist profile created successfully!": "¡Perfil de artista creado exitosamente!",
    "Artist profile saved successfully": "Perfil de artista guardado exitosamente",
    "Artist profile not found": "Perfil de artista no encontrado",
    "Individual Artist": "Artista Individual",
    "Gallery Artists": "Artistas de Galería",
    "Featured Artists": "Artistas Destacados",
    "Free Plan": "Plan Gratuito",
    "Starter Plan": "Plan Inicial",
    "Business Plan": "Plan de Negocios",
    "Creator Plan": "Plan Creador",
    "Account Type": "Tipo de Cuenta",
    
    # Gallery
    "Gallery Analytics": "Análisis de Galería",
    "Paid Commissions": "Comisiones Pagadas",
    "Pending Commissions": "Comisiones Pendientes",
    "Total Commissions": "Comisiones Totales",
    "Revenue": "Ingresos",
    "Sales": "Ventas",
    "Artwork Views": "Visualizaciones de Obras",
    "Commission Hub": "Centro de Comisiones",
    "Commission Request": "Solicitud de Comisión",
    "Commission Wizard": "Asistente de Comisiones",
    
    # Messaging
    "Messages": "Mensajes",
    "Search Messages": "Buscar Mensajes",
    "Search conversations...": "Buscar conversaciones...",
    "Search contacts...": "Buscar contactos...",
    "No messages yet": "Aún no hay mensajes",
    "No contacts found": "No se encontraron contactos",
    "No blocked users": "No hay usuarios bloqueados",
    "Create Group": "Crear Grupo",
    "Add Member": "Agregar Miembro",
    "Add Members": "Agregar Miembros",
    "Remove Member": "Eliminar Miembro",
    "Select Members": "Seleccionar Miembros",
    "Select Contacts": "Seleccionar Contactos",
    "Select a contact": "Seleccionar un contacto",
    "Add Attachment": "Agregar Adjunto",
    "This chat is archived": "Este chat está archivado",
    "You left the group": "Has salido del grupo",
    "Loading conversations...": "Cargando conversaciones...",
    "No one is online right now": "Nadie está en línea ahora",
    "Find People": "Encontrar Personas",
    "Manage blocked contacts": "Gestionar contactos bloqueados",
    "Get notified about new messages": "Recibir notificaciones de nuevos mensajes",
    "Find messages and chat history": "Encontrar mensajes e historial de chat",
    "Discover and join art communities": "Descubrir y unirse a comunidades de arte",
    "Start a conversation with fellow artists and connect with the creative community": "Inicia una conversación con otros artistas y conéctate con la comunidad creativa",
    
    # Capture
    "Capture": "Captura",
    "Captures": "Capturas",
    "Find art captures by location or type": "Encontrar capturas de arte por ubicación o tipo",
    "Discover art captures near you": "Descubre capturas de arte cerca de ti",
    "Please accept the public art disclaimer": "Por favor acepta el aviso de arte público",
    
    # Events
    "Create Event": "Crear Evento",
    "Public Event": "Evento Público",
    "Announce upcoming events": "Anunciar próximos eventos",
    "Event saved successfully": "Evento guardado exitosamente",
    
    # Subscription and payments
    "Upgrade to Pro": "Actualizar a Pro",
    "Subscription Analytics": "Análisis de Suscripción",
    "Manage Subscription": "Gestionar Suscripción",
    "Payment Method": "Método de Pago",
    "Add Payment Method": "Agregar Método de Pago",
    "Last 7 Days": "Últimos 7 Días",
    "Last 30 Days": "Últimos 30 Días",
    "Last 90 Days": "Últimos 90 Días",
    "Last 12 Months": "Últimos 12 Meses",
    "This Year": "Este Año",
    "All Time": "Todo el Tiempo",
    
    # Questions and confirmations
    "Are you sure you want to delete this?": "¿Estás seguro de que deseas eliminar esto?",
    "This action cannot be undone.": "Esta acción no se puede deshacer.",
    "Please select at least one": "Por favor selecciona al menos uno",
    "Please select at least one member": "Por favor selecciona al menos un miembro",
    "You must be logged in": "Debes iniciar sesión",
    "Log In": "Iniciar Sesión",
    
    # Time and duration
    "Today": "Hoy",
    "Yesterday": "Ayer",
    "Tomorrow": "Mañana",
    "Now": "Ahora",
    "Soon": "Pronto",
    "Recently": "Recientemente",
    "Latest": "Más reciente",
    "Newest": "Más nuevo",
    "Oldest": "Más antiguo",
    
    # Common phrases
    "Welcome!": "¡Bienvenido!",
    "Welcome back": "Bienvenido de vuelta",
    "Thank you": "Gracias",
    "Please wait": "Por favor espera",
    "Coming soon": "Próximamente",
    "Learn more": "Aprender más",
    "Read more": "Leer más",
    "Show more": "Mostrar más",
    "Show less": "Mostrar menos",
    "See all": "Ver todo",
    "Got it": "Entendido",
    "OK": "OK",
    "Yes": "Sí",
    "No": "No",
    "Maybe": "Quizás",
}

def translate_json_file(file_path: Path, dry_run: bool = False):
    """
    Translate English placeholders in JSON file to Spanish
    
    Args:
        file_path: Path to the JSON file
        dry_run: If True, only show what would be changed without saving
    """
    print(f"{'='*70}")
    print(f"Spanish Translation Tool - Artbeat")
    print(f"{'='*70}\n")
    
    # Load JSON file
    print(f"Loading: {file_path}")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    original_count = len(data)
    print(f"Total entries: {original_count}\n")
    
    # Find entries to translate
    to_translate = []
    for key, value in data.items():
        if not isinstance(value, str):
            continue
        
        # Check for bracketed placeholders
        if value.startswith('[') and value.endswith(']'):
            # Extract content from brackets
            content = value[1:-1]
            to_translate.append((key, value, content))
    
    print(f"Found {len(to_translate)} bracketed placeholders to translate\n")
    
    # Translate entries
    translated_count = 0
    untranslated = []
    
    for key, original_value, content in to_translate:
        # Try direct translation first
        if content in TRANSLATIONS:
            new_value = TRANSLATIONS[content]
            data[key] = new_value
            translated_count += 1
            if not dry_run:
                print(f"✓ {key}")
                print(f"  {original_value} → {new_value}")
        else:
            # Try to translate with variable substitution
            found_translation = False
            for eng, esp in TRANSLATIONS.items():
                if eng in content:
                    # Simple replacement for now
                    new_value = content.replace(eng, esp)
                    # Only replace if it's different
                    if new_value != content:
                        data[key] = new_value
                        translated_count += 1
                        found_translation = True
                        if not dry_run:
                            print(f"✓ {key}")
                            print(f"  {original_value} → {new_value}")
                        break
            
            if not found_translation:
                untranslated.append((key, original_value))
    
    # Summary
    print(f"\n{'='*70}")
    print(f"TRANSLATION SUMMARY")
    print(f"{'='*70}")
    print(f"Total entries: {original_count}")
    print(f"Translated: {translated_count}")
    print(f"Untranslated: {len(untranslated)}")
    
    if untranslated and len(untranslated) <= 20:
        print(f"\nUntranslated entries:")
        for key, value in untranslated[:20]:
            print(f"  {key}: {value}")
    
    # Save file
    if not dry_run:
        print(f"\nSaving file...")
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"✓ File saved: {file_path}")
    else:
        print(f"\n[DRY RUN] No changes saved")
    
    print(f"\n{'='*70}")
    if translated_count > 0:
        print(f"✅ Successfully translated {translated_count} entries!")
    else:
        print(f"ℹ️  No entries needed translation")
    print(f"{'='*70}\n")
    
    return translated_count, len(untranslated)

if __name__ == "__main__":
    import sys
    
    # Check for dry-run flag
    dry_run = '--dry-run' in sys.argv or '-d' in sys.argv
    
    if dry_run:
        print("\n🔍 DRY RUN MODE - No changes will be saved\n")
    
    # Run translation
    try:
        translated, untranslated = translate_json_file(ES_JSON_PATH, dry_run=dry_run)
        
        if untranslated > 0:
            print(f"\n💡 Tip: Review untranslated entries and add them to TRANSLATIONS dict")
            print(f"   in the script for future runs\n")
        
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
