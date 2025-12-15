#!/usr/bin/env python3
"""
Spanish Translation Script - Batch 2
Handles more complex translations and remaining entries
"""

import json
import re
from pathlib import Path

ES_JSON_PATH = Path(__file__).parent.parent / 'assets' / 'translations' / 'es.json'

# Additional comprehensive translations for batch 2
ADDITIONAL_TRANSLATIONS = {
    # Complex phrases with variables
    'Ad "{title}" rejected': 'Anuncio "{title}" rechazado',
    'Ad "{title}" approved successfully': 'Anuncio "{title}" aprobado exitosamente',
    
    # Actions and buttons
    "Flag": "Marcar",
    "Login": "Iniciar Sesión",
    "Block User": "Bloquear Usuario",
    "Report User": "Reportar Usuario",
    "Remove star": "Eliminar estrella",
    "Mark as Failed": "Marcar como Fallido",
    "Copy to Clipboard": "Copiar al Portapapeles",
    "Export Selected": "Exportar Seleccionados",
    "Bulk Refund": "Reembolso Masivo",
    "Process Refund": "Procesar Reembolso",
    "Select All": "Seleccionar Todo",
    "Deselect All": "Deseleccionar Todo",
    "Mark as Paid": "Marcar como Pagado",
    "Mark as Pending": "Marcar como Pendiente",
    "Download CSV": "Descargar CSV",
    "Print": "Imprimir",
    "Starred Messages": "Mensajes Destacados",
    
    # Titles and headers
    "Title": "Título",
    "Name": "Nombre",
    "Email": "Correo Electrónico",
    "Phone": "Teléfono",
    "Address": "Dirección",
    "City": "Ciudad",
    "State": "Estado",
    "Country": "País",
    "Zip Code": "Código Postal",
    "Website": "Sitio Web",
    "Bio": "Biografía",
    "About": "Acerca de",
    "Contact": "Contacto",
    "Social Media": "Redes Sociales",
    
    # Stats and metrics
    "Avg Transaction": "Transacción Promedio",
    "Total Revenue": "Ingresos Totales",
    "Total Sales": "Ventas Totales",
    "Total Orders": "Pedidos Totales",
    "Conversion Rate": "Tasa de Conversión",
    "Click Rate": "Tasa de Clics",
    "View Count": "Conteo de Vistas",
    "Like Count": "Conteo de Me Gusta",
    "Share Count": "Conteo de Compartidos",
    "Comment Count": "Conteo de Comentarios",
    "Follower Count": "Conteo de Seguidores",
    "Following Count": "Conteo de Seguidos",
    
    # Empty states
    "No artwork found": "No se encontró ninguna obra de arte",
    "No data to export": "No hay datos para exportar",
    "No items selected": "No hay elementos seleccionados",
    "No transactions found": "No se encontraron transacciones",
    "No payments found": "No se encontraron pagos",
    "No refunds found": "No se encontraron reembolsos",
    "Select artwork to view details": "Selecciona una obra de arte para ver detalles",
    "Select user to view details": "Selecciona un usuario para ver detalles",
    "Select transaction to view details": "Selecciona una transacción para ver detalles",
    
    # Questions and confirmations
    "Are you sure you want to process this refund?": "¿Estás seguro de que deseas procesar este reembolso?",
    "Are you sure you want to delete this item?": "¿Estás seguro de que deseas eliminar este elemento?",
    "Are you sure you want to block this user?": "¿Estás seguro de que deseas bloquear a este usuario?",
    "Are you sure you want to continue?": "¿Estás seguro de que deseas continuar?",
    "Do you want to save changes?": "¿Deseas guardar los cambios?",
    "Discard changes?": "¿Descartar cambios?",
    
    # Success messages
    "CSV content copied to clipboard": "Contenido CSV copiado al portapapeles",
    "User blocked": "Usuario bloqueado",
    "User unblocked": "Usuario desbloqueado",
    "User reported": "Usuario reportado",
    "Message starred": "Mensaje destacado",
    "Message unstarred": "Mensaje no destacado",
    "Item flagged": "Elemento marcado",
    "Item unflagged": "Marca del elemento eliminada",
    "Changes saved successfully": "Cambios guardados exitosamente",
    "Operation completed successfully": "Operación completada exitosamente",
    
    # Instructions and hints  
    "Click below to copy CSV content:": "Haz clic abajo para copiar el contenido CSV:",
    "Tap to select": "Toca para seleccionar",
    "Swipe to delete": "Desliza para eliminar",
    "Pull to refresh": "Arrastra para actualizar",
    "Hold to preview": "Mantén presionado para previsualizar",
    "Double tap to like": "Doble toque para dar me gusta",
    
    # Coming soon and placeholders
    "Reporting functionality coming soon.": "Funcionalidad de reportes próximamente.",
    "This feature is coming soon": "Esta función estará disponible pronto",
    "Under development": "En desarrollo",
    "Stay tuned": "Mantente atento",
    
    # Date and time
    "Just now": "Justo ahora",
    "A moment ago": "Hace un momento",
    "minutes ago": "minutos atrás",
    "hours ago": "horas atrás",
    "days ago": "días atrás",
    "weeks ago": "semanas atrás",
    "months ago": "meses atrás",
    "years ago": "años atrás",
    
    # Filters and sorting
    "Filter by status": "Filtrar por estado",
    "Filter by date": "Filtrar por fecha",
    "Filter by type": "Filtrar por tipo",
    "Filter by category": "Filtrar por categoría",
    "Sort by date": "Ordenar por fecha",
    "Sort by name": "Ordenar por nombre",
    "Sort by price": "Ordenar por precio",
    "Sort by popularity": "Ordenar por popularidad",
    "Ascending": "Ascendente",
    "Descending": "Descendente",
    
    # Permissions and access
    "Permission denied": "Permiso denegado",
    "Access denied": "Acceso denegado",
    "Unauthorized": "No autorizado",
    "Forbidden": "Prohibido",
    "Not found": "No encontrado",
    "Request admin access": "Solicitar acceso de administrador",
    "Admin access required": "Se requiere acceso de administrador",
    
    # Loading and progress
    "Initializing...": "Inicializando...",
    "Please wait...": "Por favor espera...",
    "Almost done...": "Casi listo...",
    "Finalizing...": "Finalizando...",
    "Syncing...": "Sincronizando...",
    "Connecting...": "Conectando...",
    
    # Network and errors
    "Network error": "Error de red",
    "Connection failed": "Conexión fallida",
    "Timeout error": "Error de tiempo de espera",
    "Server error": "Error del servidor",
    "Something went wrong": "Algo salió mal",
    "Please try again": "Por favor intenta de nuevo",
    "Retry": "Reintentar",
    
    # Forms and validation
    "Required field": "Campo requerido",
    "Invalid email": "Correo electrónico inválido",
    "Invalid phone number": "Número de teléfono inválido",
    "Password too short": "Contraseña muy corta",
    "Passwords don't match": "Las contraseñas no coinciden",
    "Field cannot be empty": "El campo no puede estar vacío",
    "Please fill all required fields": "Por favor completa todos los campos requeridos",
    
    # Account and profile
    "Edit Profile": "Editar Perfil",
    "Change Password": "Cambiar Contraseña",
    "Account Settings": "Configuración de Cuenta",
    "Privacy Settings": "Configuración de Privacidad",
    "Notification Settings": "Configuración de Notificaciones",
    "Language": "Idioma",
    "Theme": "Tema",
    "Dark Mode": "Modo Oscuro",
    "Light Mode": "Modo Claro",
    "Log Out": "Cerrar Sesión",
    "Sign Out": "Cerrar Sesión",
    "Sign In": "Iniciar Sesión",
    "Sign Up": "Registrarse",
    "Forgot Password?": "¿Olvidaste tu contraseña?",
    "Reset Password": "Restablecer Contraseña",
    "Remember Me": "Recuérdame",
    
    # File operations
    "Choose File": "Elegir Archivo",
    "Upload File": "Subir Archivo",
    "Download File": "Descargar Archivo",
    "Delete File": "Eliminar Archivo",
    "File uploaded successfully": "Archivo subido exitosamente",
    "File deleted successfully": "Archivo eliminado exitosamente",
    "Invalid file type": "Tipo de archivo inválido",
    "File too large": "Archivo muy grande",
    "Max file size": "Tamaño máximo de archivo",
    
    # Media
    "Photo": "Foto",
    "Photos": "Fotos",
    "Video": "Video",
    "Videos": "Videos",
    "Audio": "Audio",
    "Document": "Documento",
    "Documents": "Documentos",
    "Attachment": "Adjunto",
    "Attachments": "Adjuntos",
    "Take Photo": "Tomar Foto",
    "Choose Photo": "Elegir Foto",
    "Record Video": "Grabar Video",
    "Choose Video": "Elegir Video",
    
    # Social actions
    "Like": "Me gusta",
    "Unlike": "Quitar me gusta",
    "Comment": "Comentar",
    "Share": "Compartir",
    "Follow": "Seguir",
    "Unfollow": "Dejar de seguir",
    "Subscribe": "Suscribirse",
    "Unsubscribe": "Cancelar suscripción",
    "Block": "Bloquear",
    "Unblock": "Desbloquear",
    "Report": "Reportar",
    "Bookmark": "Guardar",
    "Unbookmark": "Quitar de guardados",
}

def translate_batch2():
    """Apply batch 2 translations"""
    print(f"{'='*70}")
    print(f"Spanish Translation - Batch 2")
    print(f"{'='*70}\n")
    
    with open(ES_JSON_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"Total entries: {len(data)}")
    
    # Find remaining bracketed entries
    remaining = [(k, v) for k, v in data.items() if isinstance(v, str) and v.startswith('[') and v.endswith(']')]
    print(f"Remaining bracketed entries: {len(remaining)}\n")
    
    # Apply translations
    count = 0
    for key, value in list(data.items()):
        if not isinstance(value, str) or not (value.startswith('[') and value.endswith(']')):
            continue
        
        content = value[1:-1]  # Remove brackets
        
        # Direct match
        if content in ADDITIONAL_TRANSLATIONS:
            data[key] = ADDITIONAL_TRANSLATIONS[content]
            count += 1
            print(f"✓ {key}: {value} → {data[key]}")
            continue
        
        # Pattern matching for complex strings with variables
        translated = False
        for eng, esp in ADDITIONAL_TRANSLATIONS.items():
            if '{' in content or '$' in content:
                # Handle variable substitution
                pattern = re.escape(eng).replace(r'\{', '{').replace(r'\}', '}').replace(r'\$', '$')
                if re.search(pattern, content, re.IGNORECASE):
                    new_value = re.sub(pattern, esp, content, flags=re.IGNORECASE)
                    if new_value != content:
                        data[key] = new_value
                        count += 1
                        print(f"✓ {key}: {value} → {new_value}")
                        translated = True
                        break
    
    # Save
    with open(ES_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    # Check remaining
    remaining_after = [(k, v) for k, v in data.items() if isinstance(v, str) and v.startswith('[') and v.endswith(']')]
    
    print(f"\n{'='*70}")
    print(f"SUMMARY")
    print(f"{'='*70}")
    print(f"Translated: {count}")
    print(f"Remaining: {len(remaining_after)}")
    print(f"✓ File saved!")
    print(f"{'='*70}\n")

if __name__ == "__main__":
    translate_batch2()
