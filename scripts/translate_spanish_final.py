#!/usr/bin/env python3
"""
Spanish Translation - Final Comprehensive Pass
Handles all remaining complex entries and technical terms
"""

import json
import re
from pathlib import Path

ES_JSON_PATH = Path(__file__).parent.parent / 'assets' / 'translations' / 'es.json'

# Final comprehensive translations
FINAL_TRANSLATIONS = {
    # Payment and transactions
    "Process Bulk Refunds": "Procesar Reembolsos Masivos",
    "Total Refunds": "Reembolsos Totales",
    "Total Transactions": "Transacciones Totales",
    "Transaction ID: ${transaction.id}": "ID de Transacción: ${transaction.id}",
    "Transaction: ${transaction.id}": "Transacción: ${transaction.id}",
    "Email Alerts": "Alertas por Correo",
    "Disable Account": "Deshabilitar Cuenta",
    "IP range added to whitelist": "Rango de IP agregado a lista blanca",
    "Log ID: LOG_${1000 + index}": "ID de Registro: LOG_${1000 + index}",
    
    # Security and monitoring
    "Automated Threat Response": "Respuesta Automática a Amenazas",
    "Automatically block suspicious activity": "Bloquear automáticamente actividad sospechosa",
    "• Consider blocking if pattern continues": "• Considerar bloquear si el patrón continúa",
    "Monitor security events in real-time": "Monitorear eventos de seguridad en tiempo real",
    "• Monitor the IP address": "• Monitorear la dirección IP",
    "Office Network": "Red de Oficina",
    "Factory Reset": "Restablecimiento de Fábrica",
    "VPN Connection": "Conexión VPN",
    "Danger Zone": "Zona de Peligro",
    "Real-time Monitoring": "Monitoreo en Tiempo Real",
    "Recommended Actions": "Acciones Recomendadas",
    "Resolve Issues": "Resolver Problemas",
    
    # Technical terms (often kept in English or minimally translated)
    "10.0.0.0/8": "10.0.0.0/8",
    "192.168.1.0/24": "192.168.1.0/24",
    "VPN": "VPN",
    "IP": "IP",
    "API": "API",
    "URL": "URL",
    "CSV": "CSV",
    "PDF": "PDF",
    "JSON": "JSON",
    "XML": "XML",
    
    # More actions
    "Process": "Procesar",
    "Monitor": "Monitorear",
    "Resolve": "Resolver",
    "Configure": "Configurar",
    "Enable": "Habilitar",
    "Disable": "Deshabilitar",
    "Activate": "Activar",
    "Deactivate": "Desactivar",
    "Initialize": "Inicializar",
    "Terminate": "Terminar",
    "Execute": "Ejecutar",
    "Deploy": "Desplegar",
    "Rollback": "Revertir",
    "Migrate": "Migrar",
    "Sync": "Sincronizar",
    "Backup": "Respaldar",
    "Restore": "Restaurar",
    "Archive": "Archivar",
    "Unarchive": "Desarchivar",
    
    # Status and notifications
    "Automated": "Automatizado",
    "Automatically": "Automáticamente",
    "Manual": "Manual",
    "Manually": "Manualmente",
    "Optional": "Opcional",
    "Required": "Requerido",
    "Recommended": "Recomendado",
    "Deprecated": "Obsoleto",
    "Beta": "Beta",
    "Preview": "Vista Previa",
    "Experimental": "Experimental",
    "Stable": "Estable",
    "Unstable": "Inestable",
    
    # Lists and bullets
    "• ": "• ",  # Keep bullet point
    "- ": "- ",  # Keep dash
}

# Pattern-based translations (for complex strings with variables)
PATTERN_TRANSLATIONS = [
    # Format: (english_pattern, spanish_replacement, regex_flags)
    (r'Error\s+(\w+)', r'Error \1', 0),  # Keep 'Error' followed by term
    (r'Failed\s+to\s+(\w+)', r'Error al \1', 0),  # "Failed to X" → "Error al X"
    (r'Loading\s+(\w+)', r'Cargando \1', 0),  # "Loading X" → "Cargando X"
    (r'Saving\s+(\w+)', r'Guardando \1', 0),  # "Saving X" → "Guardando X"
    (r'Uploading\s+(\w+)', r'Subiendo \1', 0),  # "Uploading X" → "Subiendo X"
    (r'Downloading\s+(\w+)', r'Descargando \1', 0),  # "Downloading X" → "Descargando X"
    (r'Deleting\s+(\w+)', r'Eliminando \1', 0),  # "Deleting X" → "Eliminando X"
    (r'Creating\s+(\w+)', r'Creando \1', 0),  # "Creating X" → "Creando X"
    (r'Updating\s+(\w+)', r'Actualizando \1', 0),  # "Updating X" → "Actualizando X"
]

def apply_pattern_translation(text):
    """Apply pattern-based translations"""
    for pattern, replacement, flags in PATTERN_TRANSLATIONS:
        text = re.sub(pattern, replacement, text, flags=flags)
    return text

def translate_final_pass():
    """Apply final comprehensive translations"""
    print(f"{'='*70}")
    print(f"Spanish Translation - Final Comprehensive Pass")
    print(f"{'='*70}\n")
    
    with open(ES_JSON_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"Total entries: {len(data)}")
    
    # Find remaining bracketed entries
    remaining = [(k, v) for k, v in data.items() if isinstance(v, str) and v.startswith('[') and v.endswith(']')]
    print(f"Remaining bracketed entries: {len(remaining)}\n")
    
    count = 0
    partially_translated = 0
    
    for key, value in list(data.items()):
        if not isinstance(value, str) or not (value.startswith('[') and value.endswith(']')):
            continue
        
        content = value[1:-1]  # Remove brackets
        original_content = content
        
        # 1. Try direct match
        if content in FINAL_TRANSLATIONS:
            data[key] = FINAL_TRANSLATIONS[content]
            count += 1
            print(f"✓ {key}")
            print(f"  {value} → {data[key]}")
            continue
        
        # 2. Apply pattern-based translations
        pattern_result = apply_pattern_translation(content)
        if pattern_result != content:
            data[key] = pattern_result
            count += 1
            print(f"✓ {key} (pattern)")
            print(f"  {value} → {pattern_result}")
            continue
        
        # 3. Try partial word replacement for compound phrases
        modified = content
        changed = False
        for eng, esp in FINAL_TRANSLATIONS.items():
            if eng in modified and eng != modified:  # Don't match if it's the whole string (already checked)
                modified = modified.replace(eng, esp)
                if modified != content:
                    changed = True
        
        if changed:
            data[key] = modified
            partially_translated += 1
            print(f"◐ {key} (partial)")
            print(f"  {value} → {modified}")
    
    # Save
    with open(ES_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    # Final check
    remaining_after = [(k, v) for k, v in data.items() if isinstance(v, str) and v.startswith('[') and v.endswith(']')]
    
    print(f"\n{'='*70}")
    print(f"FINAL SUMMARY")
    print(f"{'='*70}")
    print(f"Total entries in file: {len(data)}")
    print(f"Fully translated: {count}")
    print(f"Partially translated: {partially_translated}")
    print(f"Still remaining: {len(remaining_after)}")
    print(f"\n✓ File saved: {ES_JSON_PATH}")
    
    if len(remaining_after) > 0:
        print(f"\nRemaining entries (first 20):")
        for i, (k, v) in enumerate(remaining_after[:20], 1):
            print(f"  {i}. {k}: {v[:70]}")
    
    print(f"\n{'='*70}")
    total_translated = count + partially_translated
    if total_translated > 0:
        print(f"✅ Translated {total_translated} more entries!")
    print(f"{'='*70}\n")

if __name__ == "__main__":
    translate_final_pass()
