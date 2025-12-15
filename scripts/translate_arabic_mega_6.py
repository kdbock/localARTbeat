#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Arabic Translation Script - Mega Pass 6
Focus: App-specific, Bonuses, Admin, and Remaining Common Terms
"""

import json
import re

# Mega Pass 6: App-specific terms and remaining common entries
AR_MEGA_TRANSLATIONS_6 = {
    # XP & Bonuses
    "✓ Perfect completion bonus (+50 XP)": "✓ مكافأة الإتمام المثالي (+50 نقطة خبرة)",
    "✓ Photo documentation bonus (+30 XP)": "✓ مكافأة توثيق الصور (+30 نقطة خبرة)",
    "✓ Speed bonus (+25 XP)": "✓ مكافأة السرعة (+25 نقطة خبرة)",
    
    # Account & Actions
    "Account Actions": "إجراءات الحساب",
    "Account Created": "تم إنشاء الحساب",
    "Account Type": "نوع الحساب",
    "Account deleted successfully": "تم حذف الحساب بنجاح",
    "Account settings updated successfully": "تم تحديث إعدادات الحساب بنجاح",
    "Already have an account? Log in": "لديك حساب بالفعل؟ تسجيل الدخول",
    "An account already exists with this email.": "يوجد حساب بالفعل بهذا البريد الإلكتروني.",
    "Activity History": "سجل النشاط",
    "Actions": "الإجراءات",
    "Action Breakdown": "تفصيل الإجراءات",
    
    # Admin & System
    "Admin Panel": "لوحة المشرف",
    "Admin Settings": "إعدادات المشرف",
    "Admin Search": "بحث المشرف",
    "Admin Command Center": "مركز قيادة المشرف",
    "Admin Upload Tools": "أدوات تحميل المشرف",
    "Access denied. Admin privileges required.": "تم رفض الوصول. الامتيازات الإدارية مطلوبة.",
    "All admin functions in one place": "جميع الوظائف الإدارية في مكان واحد",
    "ARTbeat": "ARTbeat",
    "ARTbeat Uadmin Module": "وحدة ARTbeat الإدارية",
    "API": "واجهة برمجة التطبيقات",
    
    # Achievement System
    "Achievement System": "نظام الإنجازات",
    "Achievement posted to community feed!": "تم نشر الإنجاز في موجز المجتمع!",
    "Achievements refreshed": "تم تحديث الإنجازات",
    
    # Ad Management
    "Ad Campaign Management": "إدارة الحملات الإعلانية",
    "Ad Content": "محتوى الإعلان",
    "Ad Migration": "ترحيل الإعلان",
    "Ad Performance Analytics": "تحليلات أداء الإعلان",
    "Ad deleted": "تم حذف الإعلان",
    "Ad posted successfully!": "تم نشر الإعلان بنجاح!",
    "Active Ads ({count})": "الإعلانات النشطة ({count})",
    "Advertise": "أعلن",
    
    # Artwork & Content
    "Add Artwork": "إضافة عمل فني",
    "Add new artwork to your portfolio": "إضافة عمل فني جديد إلى معرضك",
    "Add detailed information and metadata": "إضافة معلومات مفصلة وبيانات وصفية",
    "Add images, videos, and audio to your artwork": "إضافة صور ومقاطع فيديو وصوت إلى عملك الفني",
    "Add bio and profile photo": "إضافة السيرة الذاتية وصورة الملف الشخصي",
    "Add your bio, photo, and preferences to get started": "أضف سيرتك الذاتية وصورتك وتفضيلاتك للبدء",
    "Additional Details": "تفاصيل إضافية",
    "Additional Details: Success": "تفاصيل إضافية: نجاح",
    "Additional Images": "صور إضافية",
    
    # Media Types
    "Add Audio": "إضافة صوت",
    "Add Images": "إضافة صور",
    "Add Videos": "إضافة مقاطع فيديو",
    "Add Attachment": "إضافة مرفق",
    "Add your audio content": "إضافة محتواك الصوتي",
    "Add your video content": "إضافة محتواك المرئي",
    "Add your video content and thumbnail": "إضافة محتواك المرئي والصورة المصغرة",
    "Add your written content": "إضافة محتواك المكتوب",
    "Add lyrics for your audio content": "إضافة كلمات لمحتواك الصوتي",
    
    # Album & Collections
    "Album": "ألبوم",
    "Album Description": "وصف الألبوم",
    "Album Number (optional)": "رقم الألبوم (اختياري)",
    "Album Title": "عنوان الألبوم",
    "All Collections": "جميع المجموعات",
    "Add genres, pricing information, and album settings if applicable.": "أضف الأنواع ومعلومات التسعير وإعدادات الألبوم إن أمكن.",
    "Add genres, pricing information, and serialization settings if applicable.": "أضف الأنواع ومعلومات التسعير وإعدادات التسلسل إن أمكن.",
    
    # Categories & Filters
    "All Categories": "جميع الفئات",
    "All Statuses": "جميع الحالات",
    "All Time": "كل الأوقات",
    "All Types": "جميع الأنواع",
    "Advanced Search": "بحث متقدم",
    "Advanced Analytics": "تحليلات متقدمة",
    
    # Permissions & Settings
    "Allow Comments": "السماح بالتعليقات",
    "Allow Likes": "السماح بالإعجابات",
    "Allow Messages": "السماح بالرسائل",
    "Allow Multiple Sessions": "السماح بالجلسات المتعددة",
    "Allow Sharing": "السماح بالمشاركة",
    "Allow location-based features": "السماح بالميزات المعتمدة على الموقع",
    "Allow login from multiple devices": "السماح بتسجيل الدخول من أجهزة متعددة",
    
    # Art Walk Specific
    "Abandon": "إلغاء",
    "Abandon Walk": "إلغاء الجولة",
    "Abandon Walk?": "إلغاء الجولة؟",
    "Already at the beginning of the route": "أنت بالفعل في بداية المسار",
    
    # System Messages
    "All systems operational": "جميع الأنظمة تعمل",
    "All events are currently clear of flags.": "جميع الأحداث خالية من العلامات حاليًا.",
    "All history cleared": "تم مسح جميع السجلات",
    "All mentions marked as read": "تم وضع علامة على جميع الإشارات كمقروءة",
    "An error occurred. Please try again.": "حدث خطأ. يرجى المحاولة مرة أخرى.",
    "An unexpected error occurred while loading events. Please try again.": "حدث خطأ غير متوقع أثناء تحميل الأحداث. يرجى المحاولة مرة أخرى.",
    
    # Other Actions
    "Add Member": "إضافة عضو",
    "Add Payment Method": "إضافة طريقة دفع",
    "Add Post": "إضافة منشور",
    "Add Ticket": "إضافة تذكرة",
    "Accept & Continue": "قبول ومتابعة",
    "Active Commissions": "العمولات النشطة",
    "Active Threats": "التهديدات النشطة",
    "2FA Method": "طريقة المصادقة الثنائية",
    "Add an extra layer of security to your account": "أضف طبقة إضافية من الأمان لحسابك",
    
    # Numbers & IP
    "1 blocked user": "مستخدم واحد محظور",
    "Add IP Range": "إضافة نطاق IP",
    
    # Music Genre
    "Ambient": "محيط",
    
    # Deletion Messages
    '"{title}" has been deleted successfully': 'تم حذف "{title}" بنجاح',
    '"${artwork.title}" has been deleted successfully': 'تم حذف "${artwork.title}" بنجاح',
    
    # Common App Terms
    "Amount: \\${amount}": "المبلغ: \\${amount}",
    
    # More specific entries
    "+${artist.mediums.length - 2}": "+${artist.mediums.length - 2}",
    "10.0.0.0/8": "10.0.0.0/8",
    "192.168.1.0/24": "192.168.1.0/24",
}

def apply_translations():
    """Apply Arabic mega translations pass 6 to ar.json"""
    input_file = '/Users/kristybock/artbeat/assets/translations/ar.json'
    output_file = input_file
    
    print("\n" + "="*60)
    print("Arabic Translation - Mega Pass 6")
    print("Focus: App-specific, Bonuses, Admin, Common Terms")
    print("="*60 + "\n")
    
    # Load current translations
    with open(input_file, 'r', encoding='utf-8') as f:
        translations = json.load(f)
    
    # Track progress
    applied_count = 0
    
    # Apply translations
    for english_text, arabic_text in AR_MEGA_TRANSLATIONS_6.items():
        # Create bracketed version
        bracketed = f"[{english_text}]"
        
        # Find and replace in translations
        if bracketed in translations.values():
            for key, value in translations.items():
                if value == bracketed:
                    translations[key] = arabic_text
                    applied_count += 1
                    print(f'  ✓ "{english_text}" → "{arabic_text}"')
                    break
    
    # Save updated translations
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(translations, f, ensure_ascii=False, indent=2)
    
    # Count remaining bracketed entries
    remaining = sum(1 for v in translations.values() if v.startswith('[') and v.endswith(']'))
    total = len(translations)
    completed = total - remaining
    percentage = (completed / total * 100) if total > 0 else 0
    
    print(f"\n{'='*60}")
    print("Arabic Translation - Mega Pass 6 Complete")
    print("="*60)
    print(f"Translations applied: {applied_count}")
    print(f"Remaining bracketed entries: {remaining}")
    print(f"Overall progress: {completed}/{total} ({percentage:.1f}%)")
    print(f"File saved: {output_file}")
    print("="*60 + "\n")

if __name__ == "__main__":
    apply_translations()
