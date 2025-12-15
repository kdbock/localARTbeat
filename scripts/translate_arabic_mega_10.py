#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Arabic Translation Script - Mega Pass 10
Focus: Sales, Search, Security, Settings, Sharing
"""

import json

# Mega Pass 10: Sales, Search, Security, Settings, Sharing
AR_MEGA_TRANSLATIONS_10 = {
    # Sales & Information
    "Sale Information": "معلومات البيع",
    "Sales": "المبيعات",
    "Sample Rate": "معدل العينة",
    
    # Save Actions
    "Save Capture": "حفظ اللقطة",
    "Save Changes": "حفظ التغييرات",
    "Save Draft": "حفظ المسودة",
    "Save Profile": "حفظ الملف الشخصي",
    "Save Search": "حفظ البحث",
    "Save these backup codes in a secure location:": "احفظ رموز النسخ الاحتياطي هذه في مكان آمن:",
    "Saved Searches": "عمليات البحث المحفوظة",
    "Saving audio metadata...": "جارٍ حفظ البيانات الوصفية الصوتية...",
    "Saving profile...": "جارٍ حفظ الملف الشخصي...",
    
    # Search
    "Search Analytics": "تحليلات البحث",
    "Search Art Walks": "البحث في الجولات الفنية",
    "Search Captures": "البحث في اللقطات",
    "Search Conversations": "البحث في المحادثات",
    "Search Error": "خطأ في البحث",
    "Search Events": "البحث في الأحداث",
    "Search artists, artwork, captures...": "البحث عن الفنانين والأعمال الفنية واللقطات...",
    "Search artwork, artists, styles...": "البحث عن الأعمال الفنية والفنانين والأنماط...",
    "Search artwork...": "البحث عن الأعمال الفنية...",
    "Search artworks, artists, galleries": "البحث عن الأعمال الفنية والفنانين والمعارض",
    "Search by name, location, or category...": "البحث بالاسم أو الموقع أو الفئة...",
    "Search contacts...": "البحث في جهات الاتصال...",
    "Search conversations...": "البحث في المحادثات...",
    "Search for artists and community members": "البحث عن الفنانين وأعضاء المجتمع",
    "Search for artists and their captures": "البحث عن الفنانين ولقطاتهم",
    "Search for artists, artwork, captures, and more": "البحث عن الفنانين والأعمال الفنية واللقطات والمزيد",
    "Search saved successfully": "تم حفظ البحث بنجاح",
    "Search users, content, transactions...": "البحث عن المستخدمين والمحتوى والمعاملات...",
    "Searching...": "جارٍ البحث...",
    
    # Security
    "Security Actions": "إجراءات الأمان",
    "Security Checkup": "فحص الأمان",
    "Security Overview": "نظرة عامة على الأمان",
    "Security Score": "نقاط الأمان",
    "Security Settings": "إعدادات الأمان",
    "Security monitoring and controls": "مراقبة الأمان والتحكم فيه",
    "Security scan completed": "اكتمل فحص الأمان",
    "Suspicious Login Activity": "نشاط تسجيل دخول مشبوه",
    "Suspicious data access detected": "تم اكتشاف وصول مشبوه إلى البيانات",
    
    # See & Select
    "See All": "عرض الكل",
    "See trending art discoveries": "عرض الاكتشافات الفنية الرائجة",
    "See trending conversations": "عرض المحادثات الرائجة",
    "Select Audio File": "تحديد ملف صوتي",
    "Select Contacts": "تحديد جهات الاتصال",
    "Select Duration": "تحديد المدة",
    "Select File": "تحديد ملف",
    "Select Image": "تحديد صورة",
    "Select Members": "تحديد الأعضاء",
    "Select Size": "تحديد الحجم",
    "Select Theme": "تحديد السمة",
    "Select Video File": "تحديد ملف فيديو",
    "Select Wallpaper": "تحديد الخلفية",
    "Select Zone": "تحديد المنطقة",
    "Select a category for selected events:": "تحديد فئة للأحداث المحددة:",
    "Select a contact": "تحديد جهة اتصال",
    "Select a thumbnail image for your video": "تحديد صورة مصغرة للفيديو",
    "Select difficulty": "تحديد الصعوبة",
    "Select events to perform bulk actions": "تحديد الأحداث لتنفيذ الإجراءات الجماعية",
    "Select sorting": "تحديد الترتيب",
    "Select the new status for selected events:": "تحديد الحالة الجديدة للأحداث المحددة:",
    "Selected content: {title}": "المحتوى المحدد: {title}",
    "Selected transaction: {id}": "المعاملة المحددة: {id}",
    
    # Send & Sending
    "Send Broadcast Message": "إرسال رسالة بث",
    "Send reminders to attendees": "إرسال تذكيرات للحضور",
    "Send verification SMS": "إرسال رسالة تحقق SMS",
    "Send verification email": "إرسال بريد تحقق إلكتروني",
    "Sending media...": "جارٍ إرسال الوسائط...",
    
    # Series & Server
    "Series/Book Number (optional)": "رقم السلسلة/الكتاب (اختياري)",
    "Server Load": "حمل الخادم",
    "Servers": "الخوادم",
    
    # Settings
    "Set as Default": "تعيين كافتراضي",
    "Set pricing for your artwork": "تعيين السعر لعملك الفني",
    "Set up commission settings": "إعداد إعدادات العمولة",
    "Settings reset successfully": "تمت إعادة تعيين الإعدادات بنجاح",
    "Settings saved successfully": "تم حفظ الإعدادات بنجاح",
    "Severity: $severity": "الخطورة: $severity",
    
    # Share & Sharing
    "Share Achievement": "مشاركة الإنجاز",
    "Share data with trusted partners": "مشاركة البيانات مع الشركاء الموثوقين",
    "Share photos from your studio": "مشاركة الصور من الاستوديو الخاص بك",
    "Share poems, stories, essays, and other written creative work": "مشاركة القصائد والقصص والمقالات والأعمال الإبداعية المكتوبة الأخرى",
    "Share updates with your community": "مشاركة التحديثات مع مجتمعك",
    "Share video art, performances, tutorials, and multimedia content": "مشاركة الفن المرئي والعروض والدروس والمحتوى متعدد الوسائط",
    "Share your art, spark conversations, and connect through a creative feed. Chat 1-on-1 or in groups—where inspiration meets community.": "شارك فنك وأثر المحادثات واتصل من خلال موجز إبداعي. دردشة فردية أو جماعية - حيث يلتقي الإلهام بالمجتمع.",
    "Share your artistic perspective with photo captures": "شارك منظورك الفني بلقطات الصور",
    "Share your new audio content": "مشاركة محتواك الصوتي الجديد",
    "Share your thoughts and updates": "مشاركة أفكارك وتحديثاتك",
    
    # Show Settings
    "Show Followers Count": "إظهار عدد المتابعين",
    "Show Following Count": "إظهار عدد المتابَعين",
    "Show Last Seen": "إظهار آخر ظهور",
    "Show Location in Profile": "إظهار الموقع في الملف الشخصي",
    "Show Message Previews": "إظهار معاينات الرسائل",
    "Show Online Status": "إظهار حالة الاتصال",
    "Show in Search": "إظهار في البحث",
    "Show in community feed": "إظهار في موجز المجتمع",
    "Show notification count on app icon": "إظهار عدد الإشعارات على أيقونة التطبيق",
    "Show notifications while using the app": "إظهار الإشعارات أثناء استخدام التطبيق",
    
    # Showcase & Sign
    "Showcase your latest creation": "اعرض أحدث إبداعاتك",
    "Showcase your work to local art lovers, get discovered, and grow your career": "اعرض عملك لمحبي الفن المحليين واكتشف نفسك وطور مسيرتك المهنية",
    "Sign Out Everywhere": "تسجيل الخروج من كل مكان",
    "Sign in to continue your artistic journey": "سجل الدخول لمواصلة رحلتك الفنية",
    "Sign out of all devices": "تسجيل الخروج من جميع الأجهزة",
    "Signed out of all other devices": "تم تسجيل الخروج من جميع الأجهزة الأخرى",
    
    # Similar & Size
    "Similar": "مشابه",
    "Size and Duration": "الحجم والمدة",
    
    # Skip
    "Skip 2FA on trusted devices": "تخطي المصادقة الثنائية على الأجهزة الموثوقة",
    "Skip Email Verification?": "تخطي التحقق من البريد الإلكتروني؟",
    "Skip for now": "تخطي الآن",
    
    # Something & Sound
    "Something went wrong. Please try again.": "حدث خطأ ما. يرجى المحاولة مرة أخرى.",
    "Sound": "الصوت",
    "Soundtrack": "موسيقى تصويرية",
    
    # Spanish & Specialties
    "Spanish": "الإسبانية",
    "Specialties": "التخصصات",
    "Spoken Word": "كلمة منطوقة",
    
    # Starred & Start
    "Starred Messages": "الرسائل المميزة",
    "Start Capturing": "بدء الالتقاط",
    "Start Navigation": "بدء التنقل",
    "Start Recording": "بدء التسجيل",
    "Start Walk": "بدء الجولة",
    "Start Your Artist Journey": "ابدأ رحلتك الفنية",
    "Start a conversation with fellow artists and connect with the creative community": "ابدأ محادثة مع زملائك الفنانين واتصل بالمجتمع الإبداعي",
    "Start an Art Walk": "ابدأ جولة فنية",
    "Starter Plan": "الخطة الابتدائية",
    "Stay": "البقاء",
    "Step {step} of {total}": "الخطوة {step} من {total}",
    "Steps": "الخطوات",
    
    # Stop
    "Stop Navigation": "إيقاف التنقل",
    "Stop Preview": "إيقاف المعاينة",
    "Stop Recording": "إيقاف التسجيل",
    "Stop Walk": "إيقاف الجولة",
    
    # Storage
    "Storage Warning": "تحذير التخزين",
    "Storage capacity reaching maximum": "سعة التخزين تقترب من الحد الأقصى",
    
    # Style & Submit
    "Style: $_selectedStyle": "النمط: $_selectedStyle",
    "Styles:": "الأنماط:",
    "Submit Refund Request": "إرسال طلب استرداد",
    "Submit Review": "إرسال المراجعة",
    
    # Subscribe & Subscription
    "Subscribe to ${_getTierName(widget.tier)}": "الاشتراك في ${_getTierName(widget.tier)}",
    "Subscription Analytics": "تحليلات الاشتراك",
    "Subscription Plans": "خطط الاشتراك",
    "Subscription Successful": "الاشتراك ناجح",
    
    # Support & Supported
    "Support & Account": "الدعم والحساب",
    "Supported formats: MP4, MOV, AVI, MKV, WebM, FLV, WMV": "التنسيقات المدعومة: MP4، MOV، AVI، MKV، WebM، FLV، WMV",
    
    # System
    "System": "النظام",
    "System Information": "معلومات النظام",
    "System Management": "إدارة النظام",
    "System Overview": "نظرة عامة على النظام",
    "System Settings": "إعدادات النظام",
    "System configuration": "تكوين النظام",
    
    # Tags & Take
    "Tags (comma-separated)": "العلامات (مفصولة بفواصل)",
    "Tags, Hashtags & Keywords": "العلامات والهاشتاجات والكلمات الرئيسية",
    "Take Your First Photo": "التقط صورتك الأولى",
    "Tap to select cover image": "اضغط لتحديد صورة الغلاف",
    "Tap to select image": "اضغط لتحديد صورة",
    
    # Technical & Tell
    "Technical Specifications": "المواصفات الفنية",
    "Tell others about yourself": "أخبر الآخرين عن نفسك",
    "Tell us about yourself": "أخبرنا عن نفسك",
    
    # Terms & Text
    "Terms & Conditions": "الأحكام والشروط",
    "Terms of Service": "شروط الخدمة",
    "Text Input": "إدخال النص",
    "Text Post": "منشور نصي",
    
    # The phrases
    "The email address is invalid.": "عنوان البريد الإلكتروني غير صحيح.",
    "The requested art walk could not be found.": "تعذر العثور على الجولة الفنية المطلوبة.",
    "There are no events happening near your location right now.": "لا توجد أحداث تحدث بالقرب من موقعك الآن.",
    "There are no events scheduled for this weekend.": "لا توجد أحداث مجدولة لعطلة نهاية الأسبوع هذه.",
    "There are no trending events at the moment.": "لا توجد أحداث رائجة في الوقت الحالي.",
    
    # Third-party & This
    "Third-party Sharing": "المشاركة مع طرف ثالث",
    "This Week": "هذا الأسبوع",
    "This Year": "هذا العام",
    "This action cannot be undone.": "لا يمكن التراجع عن هذا الإجراء.",
    "This action cannot be undone. All your data will be permanently deleted.": "لا يمكن التراجع عن هذا الإجراء. سيتم حذف جميع بياناتك نهائيًا.",
    "This artwork is already in your art walk": "هذا العمل الفني موجود بالفعل في جولتك الفنية",
    "This audio content appears to be a duplicate. Please ensure this is original work.": "يبدو أن هذا المحتوى الصوتي مكرر. يرجى التأكد من أن هذا عمل أصلي.",
    "This chat is archived": "هذه المحادثة مؤرشفة",
    "This content appears to be a duplicate. Please ensure this is original work.": "يبدو أن هذا المحتوى مكرر. يرجى التأكد من أن هذا عمل أصلي.",
    "This email is already in use by another account.": "هذا البريد الإلكتروني مستخدم بالفعل من قبل حساب آخر.",
    "This is a serialized story": "هذه قصة متسلسلة",
    "This is how others will see your name": "هكذا سيرى الآخرون اسمك",
    "This is part of an album": "هذا جزء من ألبوم",
    "This operation requires recent authentication. Please log out and log in again.": "تتطلب هذه العملية مصادقة حديثة. يرجى تسجيل الخروج وتسجيل الدخول مرة أخرى.",
    "This will add geo fields (geohash and geopoint) to all captures with locations. This is required for instant discovery to show user captures. Continue?": "سيؤدي ذلك إلى إضافة حقول جغرافية (geohash و geopoint) إلى جميع اللقطات ذات المواقع. هذا مطلوب للاكتشاف الفوري لإظهار لقطات المستخدم. المتابعة؟",
    "This will add standardized moderation status fields to all content collections. This operation cannot be undone easily. Continue?": "سيؤدي ذلك إلى إضافة حقول حالة الإشراف الموحدة إلى جميع مجموعات المحتوى. لا يمكن التراجع عن هذه العملية بسهولة. المتابعة؟",
    "This will be the primary image displayed for your artwork": "ستكون هذه الصورة الرئيسية المعروضة لعملك الفني",
    "This will permanently delete your account and all associated data. This action cannot be undone.\n\nAre you sure you want to continue?": "سيؤدي هذا إلى حذف حسابك وجميع البيانات المرتبطة به نهائيًا. لا يمكن التراجع عن هذا الإجراء.\n\nهل أنت متأكد من أنك تريد المتابعة؟",
    "This will remove the new moderation status fields from all collections. This action cannot be undone. Continue?": "سيؤدي ذلك إلى إزالة حقول حالة الإشراف الجديدة من جميع المجموعات. لا يمكن التراجع عن هذا الإجراء. المتابعة؟",
    "This will sign you out of all devices except this one. You'll need to sign in again on other devices.": "سيؤدي ذلك إلى تسجيل خروجك من جميع الأجهزة باستثناء هذا الجهاز. ستحتاج إلى تسجيل الدخول مرة أخرى على الأجهزة الأخرى.",
    
    # Threat & Thumbnail
    "Threat Detection": "اكتشاف التهديدات",
    "Threat marked as resolved": "تم وضع علامة على التهديد كمحلول",
    "Thumbnail": "صورة مصغرة",
    
    # Tips & Title
    "Tips and support for messaging": "نصائح ودعم للمراسلة",
    "Title is required": "العنوان مطلوب",
    "Title, description, and cover image": "العنوان والوصف وصورة الغلاف",
    "Title, description, and details": "العنوان والوصف والتفاصيل",
    
    # Today & Too
    "Today": "اليوم",
    "Too many requests. Please wait before trying again.": "طلبات كثيرة جدًا. يرجى الانتظار قبل المحاولة مرة أخرى.",
    
    # Top & Total
    "Top Fans": "أفضل المعجبين",
    "Top Performing Artwork": "العمل الفني الأفضل أداءً",
    "Top Performing Artworks": "الأعمال الفنية الأفضل أداءً",
    "Top Search Queries": "أفضل استعلامات البحث",
    "Total Analytics": "إجمالي التحليلات",
    "Total Chapters Planned": "إجمالي الفصول المخططة",
}

def apply_translations():
    """Apply Arabic mega translations pass 10 to ar.json"""
    input_file = '/Users/kristybock/artbeat/assets/translations/ar.json'
    output_file = input_file
    
    print("\n" + "="*60)
    print("Arabic Translation - Mega Pass 10")
    print("Focus: Sales, Search, Security, Settings, Sharing")
    print("="*60 + "\n")
    
    # Load current translations
    with open(input_file, 'r', encoding='utf-8') as f:
        translations = json.load(f)
    
    # Track progress
    applied_count = 0
    
    # Apply translations
    for english_text, arabic_text in AR_MEGA_TRANSLATIONS_10.items():
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
    print("Arabic Translation - Mega Pass 10 Complete")
    print("="*60)
    print(f"Translations applied: {applied_count}")
    print(f"Remaining bracketed entries: {remaining}")
    print(f"Overall progress: {completed}/{total} ({percentage:.1f}%)")
    print(f"File saved: {output_file}")
    print("="*60 + "\n")

if __name__ == "__main__":
    apply_translations()
