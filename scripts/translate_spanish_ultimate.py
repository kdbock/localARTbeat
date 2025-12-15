#!/usr/bin/env python3
"""
Spanish Translation - Ultimate Final Pass
Handles all remaining entries including error messages, questions, and technical terms
"""

import json
import re
from pathlib import Path

ES_JSON_PATH = Path(__file__).parent.parent / 'assets' / 'translations' / 'es.json'

# Ultimate comprehensive translations
ULTIMATE_TRANSLATIONS = {
    # Common single words and short phrases
    "Reset": "Restablecer",
    "Abandon": "Abandonar",
    "Try Again": "Intentar de Nuevo",
    "New Chat": "Nuevo Chat",
    "Select Zone": "Seleccionar Zona",
    "Select difficulty": "Seleccionar dificultad",
    
    # VPN and network
    "VPN Network": "Red VPN",
    "VPN Connection": "Conexión VPN",
    
    # Status messages
    "No settings available": "No hay configuraciones disponibles",
    "No recent alerts": "No hay alertas recientes",
    "Factory reset completed": "Restablecimiento de fábrica completado",
    "Threat marked as resolved": "Amenaza marcada como resuelta",
    "New admin user added": "Nuevo usuario administrador agregado",
    
    # Questions and confirmations
    "Are you absolutely sure you want to proceed?": "¿Está absolutamente seguro de que desea continuar?",
    "Are you sure you want to clear all cached data?": "¿Está seguro de que desea borrar todos los datos almacenados en caché?",
    "Please enter your email": "Por favor ingrese su correo electrónico",
    "Please enter your password": "Por favor ingrese su contraseña",
    
    # Warnings
    "WARNING: This will delete all data": "ADVERTENCIA: Esto eliminará todos los datos",
    "WARNING: This will delete all data and cannot be undone.": "ADVERTENCIA: Esto eliminará todos los datos y no se puede deshacer.",
    
    # Settings and configurations  
    "Reset all settings to default values": "Restablecer todas las configuraciones a valores predeterminados",
    
    # Pattern fragments (will be used in partial matching)
    "Error loading": "Error al cargar",
    "Error deleting": "Error al eliminar",
    "Error creating": "Error al crear",
    "Error updating": "Error al actualizar",
    "Error saving": "Error al guardar",
    "Error sending": "Error al enviar",
    "Severity": "Severidad",
    "Role": "Rol",
    "Medium": "Medio",
    "Threat": "Amenaza",
    "admin user": "usuario administrador",
    "system data": "datos del sistema",
    "art walk": "ruta de arte",
}

def smart_translate(text):
    """
    Apply smart translation with pattern matching and variable preservation
    """
    # Keep variables intact: ${...}, $..., {...}, etc.
    # Strategy: Replace known English phrases while preserving variables
    
    # Direct match first
    if text in ULTIMATE_TRANSLATIONS:
        return ULTIMATE_TRANSLATIONS[text]
    
    # Pattern: "Error [action] [object]: $e" → "Error al [action] [object]: $e"
    error_pattern = r'^Error\s+(loading|deleting|creating|updating|saving|sending|processing)\s+(.+?):\s+(.+)$'
    match = re.match(error_pattern, text, re.IGNORECASE)
    if match:
        action = match.group(1).lower()
        obj = match.group(2)
        var = match.group(3)
        action_map = {
            'loading': 'cargar',
            'deleting': 'eliminar', 
            'creating': 'crear',
            'updating': 'actualizar',
            'saving': 'guardar',
            'sending': 'enviar',
            'processing': 'procesar',
        }
        obj_map = {
            'system data': 'datos del sistema',
            'art walk': 'ruta de arte',
            'data': 'datos',
        }
        spanish_action = action_map.get(action, action)
        spanish_obj = obj_map.get(obj, obj)
        return f'Error al {spanish_action} {spanish_obj}: {var}'
    
    # Try partial word replacement
    modified = text
    for eng, esp in sorted(ULTIMATE_TRANSLATIONS.items(), key=lambda x: -len(x[0])):
        if eng in modified and eng != text:  # Don't match whole string (already checked)
            modified = modified.replace(eng, esp)
    
    if modified != text:
        return modified
    
    return None  # No translation found

def translate_ultimate():
    """Apply ultimate comprehensive translations"""
    print(f"{'='*70}")
    print(f"Spanish Translation - Ultimate Final Pass")
    print(f"{'='*70}\n")
    
    with open(ES_JSON_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"Total entries: {len(data)}")
    
    remaining = [(k, v) for k, v in data.items() if isinstance(v, str) and v.startswith('[') and v.endswith(']')]
    print(f"Remaining bracketed entries: {len(remaining)}\n")
    
    count = 0
    
    for key, value in list(data.items()):
        if not isinstance(value, str) or not (value.startswith('[') and value.endswith(']')):
            continue
        
        content = value[1:-1]  # Remove brackets
        
        result = smart_translate(content)
        if result:
            data[key] = result
            count += 1
            print(f"✓ {value[:50]} → {result[:50]}")
    
    # Save
    with open(ES_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    # Final check
    remaining_after = [(k, v) for k, v in data.items() if isinstance(v, str) and v.startswith('[') and v.endswith(']')]
    
    print(f"\n{'='*70}")
    print(f"ULTIMATE SUMMARY")
    print(f"{'='*70}")
    print(f"Total entries in file: {len(data)}")
    print(f"Translated in this pass: {count}")
    print(f"Still remaining: {len(remaining_after)}")
    print(f"\n✓ File saved: {ES_JSON_PATH}")
    
    if len(remaining_after) > 0:
        print(f"\nStill remaining (sample):")
        for i, (k, v) in enumerate(remaining_after[:30], 1):
            print(f"  {i}. {v[:80]}")
    
    print(f"\n{'='*70}")
    if count > 0:
        print(f"✅ Translated {count} more entries!")
    print(f"{'='*70}\n")

if __name__ == "__main__":
    translate_ultimate()
