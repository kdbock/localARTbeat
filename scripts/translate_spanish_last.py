#!/usr/bin/env python3
"""
Spanish Translation - Last 110 Entries
Handles the final 110 remaining translation entries
"""

import json
import re
from pathlib import Path

ES_JSON_PATH = Path(__file__).parent.parent / 'assets' / 'translations' / 'es.json'

# Last 110 translations
LAST_TRANSLATIONS = {
    # Confirmations
    "Are you sure you want to approve this capture?": "¿Está seguro de que desea aprobar esta captura?",
    "Are you sure you want to reject this capture?": "¿Está seguro de que desea rechazar esta captura?",
    "Are you sure you want to delete this capture?": "¿Está seguro de que desea eliminar esta captura?",
    "Are you sure?": "¿Está seguro?",
    
    # Groups and messaging
    "New Group": "Nuevo Grupo",
    "Broadcast": "Difusión",
    "Select sorting": "Seleccionar orden",
    "Participants": "Participantes",
    "Auto-download Media": "Auto-descargar Multimedia",
    "Chat Theme": "Tema de Chat",
    "Dark": "Oscuro",
    "Light": "Claro",
    "Select Theme": "Seleccionar Tema",
    "System": "Sistema",
    "Select Wallpaper": "Seleccionar Fondo de Pantalla",
    "Feed Name": "Nombre del Feed",
    "Join Groups": "Unirse a Grupos",
    "Messaging Help": "Ayuda de Mensajería",
    "Popular Chats": "Chats Populares",
    "Privacy and notification preferences": "Privacidad y preferencias de notificación",
    "Tips and support for messaging": "Consejos y soporte para mensajería",
    "Chat deleted": "Chat eliminado",
    "Chat history cleared": "Historial de chat borrado",
    "Initializing voice recorder...": "Inicializando grabadora de voz...",
    "Auto-delete spam": "Auto-eliminar spam",
    "Moderate": "Moderado",
    "Moderation features coming soon": "Funciones de moderación próximamente",
    "Quiet hours": "Horas silenciosas",
    "Go to message": "Ir al mensaje",
    "Navigate to message in chat": "Navegar al mensaje en el chat",
    
    # Error messages
    "Error abandoning walk: $e": "Error al abandonar recorrido: $e",
    "Error completing walk: $e": "Error al completar recorrido: $e",
    "Error pausing walk: $e": "Error al pausar recorrido: $e",
    "Error resuming walk: $e": "Error al reanudar recorrido: $e",
    "Error capturing selfie: $e": "Error al capturar selfie: $e",
    "Error advancing navigation: $e": "Error al avanzar navegación: $e",
    "Error getting location: ${e.toString()}": "Error al obtener ubicación: ${e.toString()}",
    "Error marking as visited: $e": "Error al marcar como visitado: $e",
    "Error stopping navigation: $e": "Error al detener navegación: $e",
    "Error with previous step: $e": "Error con el paso anterior: $e",
    "Error submitting review: $e": "Error al enviar reseña: $e",
    "Error unsaving walk: $e": "Error al dejar de guardar recorrido: $e",
    "Error selecting image: ${e.toString()}": "Error al seleccionar imagen: ${e.toString()}",
    "Error searching artists: ${e.toString()}": "Error al buscar artistas: ${e.toString()}",
    
    # Status and info messages
    "✓ Photo documentation bonus (+30 XP)": "  ✓ Bonificación por documentación fotográfica (+30 XP)",
    "  ✓ Photo documentation bonus (+30 XP)": "  ✓ Bonificación por documentación fotográfica (+30 XP)",
    "Would you like to finish now or continue exploring?": "¿Le gustaría terminar ahora o continuar explorando?",
    "• You can still claim other rewards": "• Aún puede reclamar otras recompensas",
    "⬅️ At first step of this segment": "⬅️ En el primer paso de este segmento",
    "• +$completionBonus XP total": "• +$completionBonus XP total",
    "⬅️ Showing previous navigation step": "⬅️ Mostrando paso de navegación anterior",
    "Walk paused. You can resume anytime!": "Recorrido pausado. ¡Puedes reanudar en cualquier momento!",
    "• ${widget.progress.totalPointsEarned} points earned": "• ${widget.progress.totalPointsEarned} puntos ganados",
    
    # Artist features
    "Cover Image": "Imagen de Portada",
    "Please log in to follow artists": "Por favor inicie sesión para seguir artistas",
    "Please log in to send gifts": "Por favor inicie sesión para enviar regalos",
    "Set as Default": "Establecer como Predeterminado",
    "Public Art Disclaimer": "Aviso de Arte Público",
    "See trending art discoveries": "Ver descubrimientos de arte en tendencia",
    "See trending conversations": "Ver conversaciones en tendencia",
    "Gift Received": "Regalo Recibido",
    "Host exhibitions and gatherings": "Organizar exposiciones y reuniones",
    "Manage your commissions": "Administrar sus comisiones",
    "Photo Post": "Publicación con Foto",
    "Set up commission settings": "Configurar ajustes de comisiones",
    "Showcase your latest creation": "Mostrar su última creación",
    "Text Post": "Publicación de Texto",
    "Track your performance": "Seguir su rendimiento",
    "Could not open $url": "No se pudo abrir $url",
    "You cannot send gifts to yourself": "No puede enviarse regalos a sí mismo",
    "Invitation cancelled": "Invitación cancelada",
    "Invitation reminder sent": "Recordatorio de invitación enviado",
    "Please select a plan": "Por favor seleccione un plan",
    "Request Refund": "Solicitar Reembolso",
    "Nearby Art": "Arte Cercano",
    "Terms & Conditions": "Términos y Condiciones",
    "Unable to load artist feed": "No se pudo cargar el feed del artista",
    "Feed settings saved!": "¡Configuración del feed guardada!",
    "Media saved to ${file.path}": "Multimedia guardada en ${file.path}",
    
    # UI elements
    "Level up your art journey!": "¡Sube de nivel en tu viaje artístico!",
    "SCREEN_TITLE": "TÍTULO_DE_PANTALLA",
    "GestureDetector was tapped!": "¡GestureDetector fue tocado!",
}

def translate_last_entries():
    """Apply last comprehensive translations"""
    print(f"{'='*70}")
    print(f"Spanish Translation - Last 110 Entries")
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
        if content in LAST_TRANSLATIONS:
            data[key] = LAST_TRANSLATIONS[content]
            count += 1
            print(f"✓ [{content[:50]}...] → {data[key][:50]}")
    
    # Save
    with open(ES_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    remaining_after = [(k, v) for k, v in data.items() if isinstance(v, str) and v.startswith('[') and v.endswith(']')]
    
    print(f"\n{'='*70}")
    print(f"LAST ENTRIES SUMMARY")
    print(f"{'='*70}")
    print(f"Translated in this pass: {count}")
    print(f"Still remaining: {len(remaining_after)}")
    print(f"✓ File saved: {ES_JSON_PATH}")
    
    if len(remaining_after) == 0:
        print(f"\n🎉 ALL TRANSLATIONS COMPLETE!")
        print(f"✅ All 2,698 entries in es.json have been translated!")
    elif len(remaining_after) > 0:
        print(f"\nFinal remaining entries:")
        for i, (k, v) in enumerate(remaining_after, 1):
            print(f"  {i}. {k}: {v}")
    
    percentage = ((2698 - len(remaining_after)) / 2698) * 100
    print(f"\n{'='*70}")
    if count > 0:
        print(f"✅ Translated {count} more entries!")
    print(f"📊 Total progress: {2698 - len(remaining_after)}/2698 ({percentage:.1f}%)")
    print(f"{'='*70}\n")

if __name__ == "__main__":
    translate_last_entries()
