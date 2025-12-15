#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Arabic Translation Script - Mega Pass 7
Focus: Audio, Authentication, Business, Content Management
"""

import json

# Mega Pass 7: Audio, Authentication, Business, Content
AR_MEGA_TRANSLATIONS_7 = {
    # Audio Related
    "Audio content uploaded successfully!": "تم تحميل المحتوى الصوتي بنجاح!",
    "Audio content validated": "تم التحقق من المحتوى الصوتي",
    "Audio file is too large. Maximum size: {size}": "الملف الصوتي كبير جدًا. الحد الأقصى للحجم: {size}",
    "Audio metadata extracted successfully": "تم استخراج البيانات الوصفية الصوتية بنجاح",
    "Audio must be at least 30 seconds long": "يجب أن يكون الصوت 30 ثانية على الأقل",
    "Audio processing complete": "اكتمل معالجة الصوت",
    "Audio upload coming soon!": "تحميل الصوت قريبًا!",
    "Audio upload completed successfully": "اكتمل تحميل الصوت بنجاح",
    "Audio upload failed. Please try again.": "فشل تحميل الصوت. يرجى المحاولة مرة أخرى.",
    "Audiobook": "كتاب صوتي",
    
    # Authentication & Security
    "Authentication Required": "المصادقة مطلوبة",
    "Authentication failed: ${message}": "فشلت المصادقة: ${message}",
    "Authenticator App": "تطبيق المصادقة",
    "Auto-delete spam": "حذف البريد المزعج تلقائيًا",
    "Automated Threat Response": "الاستجابة التلقائية للتهديدات",
    "Back to Login": "العودة لتسجيل الدخول",
    "Backup Codes": "رموز النسخ الاحتياطي",
    "Backup Database": "نسخ احتياطي لقاعدة البيانات",
    "Backup created successfully": "تم إنشاء النسخة الاحتياطية بنجاح",
    
    # Business & Analytics
    "Business Analytics": "تحليلات الأعمال",
    "Business Management": "إدارة الأعمال",
    "Business Plan": "خطة الأعمال",
    "Business Tools": "أدوات الأعمال",
    "Average Sale": "متوسط المبيعات",
    "Avg Engagement Rate": "متوسط معدل التفاعل",
    "Avg Results": "متوسط النتائج",
    "Avg per Sale": "المتوسط لكل عملية بيع",
    "Conversion Rate": "معدل التحويل",
    
    # Content Management
    "Content": "المحتوى",
    "Content Input": "إدخال المحتوى",
    "Content Management": "إدارة المحتوى",
    "Content Preview": "معاينة المحتوى",
    "Content Privacy": "خصوصية المحتوى",
    "Content Review": "مراجعة المحتوى",
    "Content Settings": "إعدادات المحتوى",
    "Content Type": "نوع المحتوى",
    "Content approved successfully": "تمت الموافقة على المحتوى بنجاح",
    "Content rejected successfully": "تم رفض المحتوى بنجاح",
    "Content uploaded successfully!": "تم تحميل المحتوى بنجاح!",
    
    # Audit & Logs
    "Audit Log Details": "تفاصيل سجل المراجعة",
    "Audit Logs": "سجلات المراجعة",
    
    # Media & Upload
    "Auto-download Media": "التنزيل التلقائي للوسائط",
    "Automatically download photos and videos": "تنزيل الصور ومقاطع الفيديو تلقائيًا",
    "Available for Sale": "متاح للبيع",
    "Author's Note": "ملاحظة المؤلف",
    
    # Basic Info
    "Basic Info": "المعلومات الأساسية",
    "Basic Information": "المعلومات الأساسية",
    "Begin your artistic journey today": "ابدأ رحلتك الفنية اليوم",
    "Bi-weekly release": "إصدار نصف أسبوعي",
    "Bio (optional)": "السيرة الذاتية (اختياري)",
    "Bitrate": "معدل البت",
    
    # Blocking & Moderation
    "Blocked IPs": "عناوين IP المحظورة",
    "Blocked users cannot message you or see your content. You can unblock them at any time.": "لا يمكن للمستخدمين المحظورين مراسلتك أو رؤية محتواك. يمكنك إلغاء حظرهم في أي وقت.",
    "Blocked {date}": "محظور {date}",
    
    # Music Genres
    "Blues": "بلوز",
    "Classical": "كلاسيكي",
    
    # Coupons & Promotions
    "Brief description of the coupon": "وصف موجز للقسيمة",
    
    # Broadcasting
    "Broadcast": "بث",
    "Broadcast message sent successfully": "تم إرسال رسالة البث بنجاح",
    
    # Browse & Navigation
    "Browse Ads": "تصفح الإعلانات",
    "Browse All Galleries": "تصفح جميع المعارض",
    "Browse, commission, and collect from local artists. Support creativity by gifting promo credits that help artists shine.": "تصفح واطلب واجمع من الفنانين المحليين. ادعم الإبداع بإهداء رصيد ترويجي يساعد الفنانين على التألق.",
    
    # Community
    "Build Community": "بناء المجتمع",
    "Build Number": "رقم البناء",
    
    # Bulk Operations
    "Bulk Actions ({{count}} events)": "إجراءات جماعية ({{count}} حدث)",
    "Bulk Event Management": "إدارة الأحداث الجماعية",
    "Bulk upload content and data": "تحميل المحتوى والبيانات بشكل جماعي",
    
    # Reviews
    "By: ${review.authorName}": "بواسطة: ${review.authorName}",
    
    # Cache
    "CANCEL": "إلغاء",
    "Cache cleared successfully": "تم مسح ذاكرة التخزين المؤقت بنجاح",
    
    # Invitations & Uploads
    "Cancel Invitation": "إلغاء الدعوة",
    "Cancel Upload": "إلغاء التحميل",
    "Cancelled": "ملغى",
    
    # Capture System
    "Capture Details": "تفاصيل الالتقاط",
    "Capture Moderation": "إشراف الالتقاط",
    "Capture a beautiful moment": "التقط لحظة جميلة",
    "Capture approved successfully": "تمت الموافقة على الالتقاط بنجاح",
    "Capture deleted permanently": "تم حذف الالتقاط نهائيًا",
    "Capture deleted successfully": "تم حذف الالتقاط بنجاح",
    "Capture rejected": "تم رفض الالتقاط",
    "Capture updated successfully": "تم تحديث الالتقاط بنجاح",
    
    # Image Management
    "Change Cover Image": "تغيير صورة الغلاف",
    "Change Image": "تغيير الصورة",
    
    # Chapters & Series
    "Chapter Number (optional)": "رقم الفصل (اختياري)",
    
    # Charts
    "Chart will be implemented with fl_chart package": "سيتم تنفيذ المخطط باستخدام حزمة fl_chart",
    
    # Chat
    "Chat Info": "معلومات المحادثة",
    "Chat Notifications": "إشعارات المحادثة",
    "Chat Theme": "سمة المحادثة",
    "Chat deleted": "تم حذف المحادثة",
    "Chat history cleared": "تم مسح سجل المحادثة",
    "Chat not found": "المحادثة غير موجودة",
    
    # Verification & Review
    "Check all details before publishing": "تحقق من جميع التفاصيل قبل النشر",
    "Check back later for curated collections": "تحقق لاحقًا من المجموعات المنسقة",
    "Check back soon for new events in your area": "تحقق قريبًا من الأحداث الجديدة في منطقتك",
    
    # Languages
    "Chinese": "الصينية",
    
    # File Selection
    "Choose File": "اختيار ملف",
    "Choose Thumbnail": "اختيار صورة مصغرة",
    
    # Plans & Pricing
    "Choose Your Plan": "اختر خطتك",
    "Choose a plan to get started as an artist.": "اختر خطة للبدء كفنان.",
    "Choose how you'd like to provide your audio content. You can upload audio files or record directly.": "اختر كيفية تقديم محتواك الصوتي. يمكنك تحميل ملفات صوتية أو التسجيل مباشرة.",
    "Choose how you'd like to provide your written content. You can upload a file or write directly in the app.": "اختر كيفية تقديم محتواك المكتوب. يمكنك تحميل ملف أو الكتابة مباشرة في التطبيق.",
    "Choose whether to sell your artwork and set a price": "اختر ما إذا كنت تريد بيع عملك الفني وحدد السعر",
    
    # Credits
    "Cinematographer (Optional)": "مصور سينمائي (اختياري)",
    "Composer (Optional)": "ملحن (اختياري)",
    
    # Rewards
    "Claim Rewards": "استلام المكافآت",
    
    # Clear Actions
    "Clear All": "مسح الكل",
    "Clear Cache": "مسح ذاكرة التخزين المؤقت",
    "Clear Chat History": "مسح سجل المحادثة",
    "Clear Filters": "مسح الفلاتر",
    "Clear Reports": "مسح التقارير",
    "Clear Review": "مسح المراجعة",
    "Clear Search": "مسح البحث",
    "Clear Selection": "مسح التحديد",
    "Clear all cached data": "مسح جميع البيانات المخزنة مؤقتًا",
    
    # Community & Collections
    "Collectors": "الجامعون",
    "Color Palette": "لوحة الألوان",
    "Commission": "عمولة",
    "Commission Hub": "مركز العمولات",
    "Commission Wizard": "معالج العمولات",
    "Commissions": "العمولات",
    "Community Views": "مشاهدات المجتمع",
    "Compact": "مضغوط",
    
    # Completion
    "Complete Now": "إكمال الآن",
    "Complete Walk Early?": "إكمال الجولة مبكرًا؟",
    "Complete Your Profile": "أكمل ملفك الشخصي",
    "Complete your first art walk to see it here": "أكمل جولتك الفنية الأولى لرؤيتها هنا",
    
    # Compression
    "Compressed streaming version": "نسخة البث المضغوطة",
    "Compressing audio for optimal streaming...": "جارٍ ضغط الصوت للبث الأمثل...",
    "Compression Settings": "إعدادات الضغط",
    
    # Events
    "Concert": "حفلة موسيقية",
    
    # Configuration
    "Configure App": "تكوين التطبيق",
    "Confirm Deletion": "تأكيد الحذف",
    
    # Connections
    "Connect": "اتصال",
    "Connect artists": "ربط الفنانين",
    "Connect with Artists": "التواصل مع الفنانين",
    "Connect with artists": "التواصل مع الفنانين",
    "Connect with artists and art lovers worldwide": "التواصل مع الفنانين ومحبي الفن في جميع أنحاء العالم",
    "Connect with fellow artists": "التواصل مع زملائك الفنانين",
    "Connect with galleries and sell your artwork": "التواصل مع المعارض وبيع أعمالك الفنية",
    "Connect with thousands of artists and art enthusiasts": "التواصل مع آلاف الفنانين وعشاق الفن",
    "Connection request sent!": "تم إرسال طلب الاتصال!",
    "Connections": "الاتصالات",
    "Connectivity test: All services online": "اختبار الاتصال: جميع الخدمات متصلة",
    
    # Contact
    "Contact Information": "معلومات الاتصال",
    
    # Privacy & Control
    "Control how and when you can log in": "التحكم في كيفية ووقت تسجيل الدخول",
    "Control how your data is collected and used": "التحكم في كيفية جمع بياناتك واستخدامها",
    "Control location tracking and sharing": "التحكم في تتبع الموقع ومشاركته",
    "Control who can see and interact with your content": "التحكم في من يمكنه رؤية محتواك والتفاعل معه",
    "Control who can see your profile and information": "التحكم في من يمكنه رؤية ملفك الشخصي ومعلوماتك",
    
    # Bandwidth
    "Bandwidth optimized for your connection": "تم تحسين النطاق الترددي لاتصالك",
}

def apply_translations():
    """Apply Arabic mega translations pass 7 to ar.json"""
    input_file = '/Users/kristybock/artbeat/assets/translations/ar.json'
    output_file = input_file
    
    print("\n" + "="*60)
    print("Arabic Translation - Mega Pass 7")
    print("Focus: Audio, Authentication, Business, Content")
    print("="*60 + "\n")
    
    # Load current translations
    with open(input_file, 'r', encoding='utf-8') as f:
        translations = json.load(f)
    
    # Track progress
    applied_count = 0
    
    # Apply translations
    for english_text, arabic_text in AR_MEGA_TRANSLATIONS_7.items():
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
    print("Arabic Translation - Mega Pass 7 Complete")
    print("="*60)
    print(f"Translations applied: {applied_count}")
    print(f"Remaining bracketed entries: {remaining}")
    print(f"Overall progress: {completed}/{total} ({percentage:.1f}%)")
    print(f"File saved: {output_file}")
    print("="*60 + "\n")

if __name__ == "__main__":
    apply_translations()
