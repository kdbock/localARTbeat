#!/usr/bin/env python3
"""
Spanish Translation - Complete Final Pass
Handles all remaining simple terms and messages
"""

import json
import re
from pathlib import Path

ES_JSON_PATH = Path(__file__).parent.parent / 'assets' / 'translations' / 'es.json'

# Complete final translations - all remaining terms
COMPLETE_TRANSLATIONS = {
    # System monitoring
    "Avg Session": "Sesión Promedio",
    "CPU Usage": "Uso de CPU",
    "Memory Usage": "Uso de Memoria",
    "Critical Alerts": "Alertas Críticas",
    "Warning Alerts": "Alertas de Advertencia",
    "No system alerts": "No hay alertas del sistema",
    
    # Status badges
    "Featured": "Destacado",
    "Verified": "Verificado",
    "Premium": "Premium",
    "Pro": "Pro",
    "Active": "Activo",
    "Inactive": "Inactivo",
    "Pending": "Pendiente",
    "Approved": "Aprobado",
    "Rejected": "Rechazado",
    
    # Navigation
    "Artbeat Home": "Inicio de Artbeat",
    "Return to main app": "Volver a la aplicación principal",
    "Admin Panel": "Panel de Administración",
    
    # Management
    "Transaction & refund management": "Gestión de transacciones y reembolsos",
    
    # Auth messages
    "Access denied. Admin privileges required.": "Acceso denegado. Se requieren privilegios de administrador.",
    "Invalid email address.": "Dirección de correo electrónico no válida.",
    "This account has been disabled.": "Esta cuenta ha sido deshabilitada.",
    "No user found with this email.": "No se encontró ningún usuario con este correo electrónico.",
    "Invalid password.": "Contraseña no válida.",
    "Please enter a valid email": "Por favor ingrese un correo electrónico válido",
    "Password must be at least 6 characters": "La contraseña debe tener al menos 6 caracteres",
    
    # Environment
    "Standalone development environment": "Entorno de desarrollo independiente",
    
    # Common terms
    "Mediums": "Medios",
    "Medium": "Medio",
    "Themes": "Temas",
    "Theme": "Tema",
    "Style": "Estilo",
    "Styles": "Estilos",
    "Category": "Categoría",
    "Categories": "Categorías",
    "Tags": "Etiquetas",
    "Tag": "Etiqueta",
    
    # Actions
    "Apply": "Aplicar",
    "Apply Changes": "Aplicar Cambios",
    "Discard": "Descartar",
    "Discard Changes": "Descartar Cambios",
    "Refresh": "Actualizar",
    "Reload": "Recargar",
    "Retry": "Reintentar",
    "Continue": "Continuar",
    "Skip": "Omitir",
    "Next": "Siguiente",
    "Previous": "Anterior",
    "Finish": "Finalizar",
    "Done": "Hecho",
    "OK": "OK",
    "Yes": "Sí",
    "No": "No",
    "Maybe": "Quizás",
    
    # Time and dates
    "Today": "Hoy",
    "Yesterday": "Ayer",
    "Tomorrow": "Mañana",
    "This Week": "Esta Semana",
    "Last Week": "Semana Pasada",
    "This Month": "Este Mes",
    "Last Month": "Mes Pasado",
    "This Year": "Este Año",
    "Last Year": "Año Pasado",
    
    # Quantities
    "All": "Todos",
    "None": "Ninguno",
    "Some": "Algunos",
    "Many": "Muchos",
    "Few": "Pocos",
    "Several": "Varios",
    
    # Common objects
    "Items": "Elementos",
    "Item": "Elemento",
    "Results": "Resultados",
    "Result": "Resultado",
    "Entries": "Entradas",
    "Entry": "Entrada",
    "Records": "Registros",
    "Record": "Registro",
    "Files": "Archivos",
    "File": "Archivo",
    "Documents": "Documentos",
    "Document": "Documento",
    
    # Status messages
    "Loading data": "Cargando datos",
    "Saving data": "Guardando datos",
    "Processing request": "Procesando solicitud",
    "Please wait": "Por favor espere",
    "Almost done": "Casi terminado",
    "Completed successfully": "Completado exitosamente",
    "Operation failed": "Operación fallida",
    "Operation cancelled": "Operación cancelada",
    
    # Errors
    "An error occurred": "Ocurrió un error",
    "Something went wrong": "Algo salió mal",
    "Please try again": "Por favor intente de nuevo",
    "Unable to connect": "No se puede conectar",
    "Connection lost": "Conexión perdida",
    "Timeout error": "Error de tiempo de espera",
    "Not found": "No encontrado",
    "Unauthorized": "No autorizado",
    "Forbidden": "Prohibido",
    "Bad request": "Solicitud incorrecta",
    
    # Common UI
    "Show more": "Mostrar más",
    "Show less": "Mostrar menos",
    "See all": "Ver todo",
    "See details": "Ver detalles",
    "Hide details": "Ocultar detalles",
    "Expand": "Expandir",
    "Collapse": "Contraer",
    "Open": "Abrir",
    "Close": "Cerrar",
    "Maximize": "Maximizar",
    "Minimize": "Minimizar",
}

def translate_complete():
    """Apply complete final translations"""
    print(f"{'='*70}")
    print(f"Spanish Translation - Complete Final Pass")
    print(f"{'='*70}\n")
    
    with open(ES_JSON_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    remaining = [(k, v) for k, v in data.items() if isinstance(v, str) and v.startswith('[') and v.endswith(']')]
    print(f"Starting with {len(remaining)} bracketed entries\n")
    
    count = 0
    
    for key, value in list(data.items()):
        if not isinstance(value, str) or not (value.startswith('[') and value.endswith(']')):
            continue
        
        content = value[1:-1]  # Remove brackets
        
        # Direct match
        if content in COMPLETE_TRANSLATIONS:
            data[key] = COMPLETE_TRANSLATIONS[content]
            count += 1
            if count <= 50:  # Only show first 50
                print(f"✓ [{content}] → {data[key]}")
        else:
            # Try pattern matching with variables
            for pattern in COMPLETE_TRANSLATIONS:
                # Check if it contains the pattern with variables after it
                if pattern in content and content.startswith(pattern):
                    # Keep the variable part
                    remainder = content[len(pattern):]
                    data[key] = COMPLETE_TRANSLATIONS[pattern] + remainder
                    count += 1
                    if count <= 50:
                        print(f"✓ [{content[:40]}] → {data[key][:40]}")
                    break
    
    # Save
    with open(ES_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    remaining_after = [(k, v) for k, v in data.items() if isinstance(v, str) and v.startswith('[') and v.endswith(']')]
    
    print(f"\n{'='*70}")
    print(f"COMPLETE SUMMARY")
    print(f"{'='*70}")
    print(f"Translated in this pass: {count}")
    print(f"Still remaining: {len(remaining_after)}")
    print(f"✓ File saved: {ES_JSON_PATH}")
    
    if len(remaining_after) > 0 and len(remaining_after) <= 100:
        print(f"\nAll remaining entries:")
        for i, (k, v) in enumerate(remaining_after, 1):
            print(f"  {i}. {v}")
    elif len(remaining_after) > 0:
        print(f"\nRemaining entries (first 50):")
        for i, (k, v) in enumerate(remaining_after[:50], 1):
            print(f"  {i}. {v[:80]}")
    
    print(f"\n{'='*70}")
    if count > 0:
        print(f"✅ Translated {count} more entries!")
    
    percentage = ((2698 - len(remaining_after)) / 2698) * 100
    print(f"📊 Total progress: {2698 - len(remaining_after)}/2698 ({percentage:.1f}%)")
    print(f"{'='*70}\n")

if __name__ == "__main__":
    translate_complete()
