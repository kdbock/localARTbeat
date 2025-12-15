#!/usr/bin/env python3
"""
Spanish Translation - Final Remaining Entries
Handles all remaining translation entries
"""

import json
import re
from pathlib import Path

ES_JSON_PATH = Path(__file__).parent.parent / 'assets' / 'translations' / 'es.json'

# Final remaining translations
FINAL_REMAINING = {
    # Error messages with variables
    "Authentication failed: ${message}": "Autenticación fallida: ${message}",
    "An unexpected error occurred: ${error}": "Ocurrió un error inesperado: ${error}",
    "Migration failed: ${error}": "Migración fallida: ${error}",
    "Geo field migration failed: ${error}": "Migración de campo geo fallida: ${error}",
    "Error: ${snapshot.error}": "Error: ${snapshot.error}",
    "Error: ${e.toString()}": "Error: ${e.toString()}",
    "Error sharing: ${e.toString()}": "Error al compartir: ${e.toString()}",
    "Error picking image: $e": "Error al seleccionar imagen: $e",
    "Error: $_error": "Error: $_error",
    
    # UI labels and headers
    "Uadmin Module Demo": "Demostración del Módulo Uadmin",
    "Example Button": "Botón de Ejemplo",
    "ARTbeat Uadmin Module": "Módulo Uadmin de ARTbeat",
    "Run Migration": "Ejecutar Migración",
    "Data Migration": "Migración de Datos",
    "Approving content...": "Aprobando contenido...",
    "Selected transaction: {id}": "Transacción seleccionada: {id}",
    "Failed login attempt blocked": "Intento de inicio de sesión fallido bloqueado",
    "Password policy updated": "Política de contraseñas actualizada",
    "Security scan completed": "Escaneo de seguridad completado",
    "Suspicious data access detected": "Acceso a datos sospechoso detectado",
    "Blocked IPs": "IPs Bloqueadas",
    "Failed Logins": "Inicios de Sesión Fallidos",
    "Security Score": "Puntuación de Seguridad",
    "Access Control": "Control de Acceso",
    "Audit Logs": "Registros de Auditoría",
    "Suspicious Login Activity": "Actividad de Inicio de Sesión Sospechosa",
    "Multiple failed login attempts from IP 192.168.1.100": "Múltiples intentos de inicio de sesión fallidos desde IP 192.168.1.100",
    "Unusual Data Access Pattern": "Patrón Inusual de Acceso a Datos",
    "Chart will be implemented with fl_chart package": "El gráfico se implementará con el paquete fl_chart",
    "Payout #${index + 1}": "Pago #${index + 1}",
    "Ad Migration": "Migración de Anuncios",
    "Migration in progress...": "Migración en progreso...",
    "⚠️ Overwrite Warning": "⚠️ Advertencia de Sobrescritura",
    "Ad Content": "Contenido del Anuncio",
    "Tap to select image": "Toca para seleccionar imagen",
    "Where to Display": "Dónde Mostrar",
    "Post Ad for $price": "Publicar Anuncio por $price",
    "Art events and spaces near you": "Eventos de arte y espacios cerca de ti",
    "Discover local and featured artists": "Descubre artistas locales y destacados",
    "Local Scene": "Escena Local",
    "Popular artists and trending art": "Artistas populares y arte en tendencia",
    "Trending": "Tendencias",
    "Unable to start navigation. No art pieces found.": "No se puede iniciar la navegación. No se encontraron piezas de arte.",
    "Change Cover Image": "Cambiar Imagen de Portada",
    
    # Dynamic value displays
    "\\$${entry.value.toStringAsFixed(2)}": "\\$${entry.value.toStringAsFixed(2)}",  # Keep as is
    "+${artist.mediums.length - 2}": "+${artist.mediums.length - 2}",  # Keep as is
    "+${location.galleries.length - 2}": "+${location.galleries.length - 2}",  # Keep as is
    
    # Simple words
    "Link": "Enlace",
    "Copy Link": "Copiar Enlace",
    "Share Link": "Compartir Enlace",
    "Open Link": "Abrir Enlace",
    "Visit": "Visitar",
    "Website": "Sitio Web",
    "Portfolio": "Portafolio",
    "Gallery": "Galería",
    "Galleries": "Galerías",
    "Exhibition": "Exposición",
    "Exhibitions": "Exposiciones",
    "Collection": "Colección",
    "Collections": "Colecciones",
    "Curator": "Curador",
    "Curators": "Curadores",
}

def translate_final_remaining():
    """Apply final remaining translations"""
    print(f"{'='*70}")
    print(f"Spanish Translation - Final Remaining Entries")
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
        if content in FINAL_REMAINING:
            data[key] = FINAL_REMAINING[content]
            count += 1
            print(f"✓ [{content[:50]}] → {data[key][:50]}")
    
    # Save
    with open(ES_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    remaining_after = [(k, v) for k, v in data.items() if isinstance(v, str) and v.startswith('[') and v.endswith(']')]
    
    print(f"\n{'='*70}")
    print(f"FINAL REMAINING SUMMARY")
    print(f"{'='*70}")
    print(f"Translated in this pass: {count}")
    print(f"Still remaining: {len(remaining_after)}")
    print(f"✓ File saved: {ES_JSON_PATH}")
    
    if len(remaining_after) > 0:
        print(f"\nAll remaining entries:")
        # Group by first 2 words to see patterns
        patterns = {}
        for k, v in remaining_after:
            content = v[1:-1]
            words = content.split()[:2]
            pattern = ' '.join(words) if words else content
            if pattern not in patterns:
                patterns[pattern] = []
            patterns[pattern].append(v)
        
        print(f"\nGrouped by pattern:")
        for pattern, entries in sorted(patterns.items(), key=lambda x: -len(x[1])):
            print(f"\n  Pattern '{pattern}': {len(entries)} entries")
            for entry in entries[:3]:
                print(f"    {entry}")
    
    percentage = ((2698 - len(remaining_after)) / 2698) * 100
    print(f"\n{'='*70}")
    if count > 0:
        print(f"✅ Translated {count} more entries!")
    print(f"📊 Total progress: {2698 - len(remaining_after)}/2698 ({percentage:.1f}%)")
    print(f"{'='*70}\n")

if __name__ == "__main__":
    translate_final_remaining()
