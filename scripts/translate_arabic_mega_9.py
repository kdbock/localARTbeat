#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Arabic Translation Script - Mega Pass 9
Focus: Loading States, No Results Messages, Management, Settings
"""

import json

# Mega Pass 9: Loading, No Results, Management, Settings
AR_MEGA_TRANSLATIONS_9 = {
    # Loading States
    "Loading Event...": "جارٍ تحميل الحدث...",
    "Loading artist feed...": "جارٍ تحميل موجز الفنان...",
    "Loading conversations...": "جارٍ تحميل المحادثات...",
    "Loading dashboard...": "جارٍ تحميل لوحة المعلومات...",
    "Loading discoveries...": "جارٍ تحميل الاكتشافات...",
    "Loading events...": "جارٍ تحميل الأحداث...",
    "Loading stats...": "جارٍ تحميل الإحصائيات...",
    
    # Local & Location
    "Local Artists": "الفنانون المحليون",
    "Local Captures": "اللقطات المحلية",
    "Local Galleries & Museums": "المعارض والمتاحف المحلية",
    "Local Scene": "المشهد المحلي",
    "Location": "الموقع",
    "Location (optional)": "الموقع (اختياري)",
    "Location Privacy": "خصوصية الموقع",
    "Location Sharing": "مشاركة الموقع",
    "Location permissions are denied": "تم رفض أذونات الموقع",
    "Location services are disabled.": "خدمات الموقع معطلة.",
    "Location-based Recommendations": "التوصيات المعتمدة على الموقع",
    
    # Login & Security
    "Log In": "تسجيل الدخول",
    "Login Alerts": "تنبيهات تسجيل الدخول",
    "Login History": "سجل تسجيل الدخول",
    "Login Security": "أمان تسجيل الدخول",
    "Logout failed: {error}": "فشل تسجيل الخروج: {error}",
    
    # Lyrics & Media
    "Lyrics (Optional)": "كلمات الأغاني (اختياري)",
    "Main Image": "الصورة الرئيسية",
    
    # Maintenance & Settings
    "Maintenance Settings": "إعدادات الصيانة",
    "Make Private": "جعله خاصًا",
    "Make Public": "جعله عامًا",
    "Make this art walk visible to other users": "جعل هذه الجولة الفنية مرئية للمستخدمين الآخرين",
    "Make this artwork available for purchase": "جعل هذا العمل الفني متاحًا للشراء",
    "Make this artwork visible to other users": "جعل هذا العمل الفني مرئيًا للمستخدمين الآخرين",
    "Make this audio available for sale": "جعل هذا الصوت متاحًا للبيع",
    "Make this content available for sale": "جعل هذا المحتوى متاحًا للبيع",
    "Make this video available for sale": "جعل هذا الفيديو متاحًا للبيع",
    
    # Management
    "Manage Accounts": "إدارة الحسابات",
    "Manage All": "إدارة الكل",
    "Manage Blocked Users": "إدارة المستخدمين المحظورين",
    "Manage Devices": "إدارة الأجهزة",
    "Manage Opportunities": "إدارة الفرص",
    "Manage Subscription": "إدارة الاشتراك",
    "Manage Users": "إدارة المستخدمين",
    "Manage blocked contacts": "إدارة جهات الاتصال المحظورة",
    "Manage requests": "إدارة الطلبات",
    "Manage trusted devices and security features": "إدارة الأجهزة الموثوقة وميزات الأمان",
    "Manage user accounts and profiles": "إدارة حسابات المستخدمين والملفات الشخصية",
    "Manage users you have blocked from interacting with you": "إدارة المستخدمين الذين حظرتهم من التفاعل معك",
    "Manage your art": "إدارة فنك",
    "Manage your commissions": "إدارة عمولاتك",
    "Manage your income": "إدارة دخلك",
    "Manage your profile and preferences": "إدارة ملفك الشخصي وتفضيلاتك",
    "Manage, create, connect": "إدارة وإنشاء والتواصل",
    "Management Actions": "إجراءات الإدارة",
    "Management Console": "وحدة تحكم الإدارة",
    
    # Marketing & Media
    "Marketing Communications": "الاتصالات التسويقية",
    "Materials": "المواد",
    "Media": "الوسائط",
    "Media Files": "ملفات الوسائط",
    "Media saved successfully": "تم حفظ الوسائط بنجاح",
    "Media saved to ${file.path}": "تم حفظ الوسائط إلى ${file.path}",
    "Medium & Styles": "الوسيط والأنماط",
    "Medium: $_selectedMedium": "الوسيط: $_selectedMedium",
    
    # Messages
    "Message Settings": "إعدادات الرسائل",
    "Message unstarred": "تم إلغاء تمييز الرسالة",
    "Messaging Dashboard": "لوحة معلومات الرسائل",
    "Messaging Help": "مساعدة الرسائل",
    "Messaging Settings": "إعدادات الرسائل",
    
    # Microphone & Migration
    "Microphone permission is required for recording": "إذن الميكروفون مطلوب للتسجيل",
    "Migrate Ads (Overwrite Existing)": "ترحيل الإعلانات (الكتابة فوق الموجود)",
    "Migrate Ads (Skip Existing)": "ترحيل الإعلانات (تخطي الموجود)",
    "Migration in progress...": "جارٍ الترحيل...",
    
    # Moderation & Monitoring
    "Moderate": "إشراف",
    "Moderate art walks and manage reports": "الإشراف على الجولات الفنية وإدارة التقارير",
    "Moderate captures and manage reports": "الإشراف على اللقطات وإدارة التقارير",
    "Moderation features coming soon": "ميزات الإشراف قريبًا",
    "Monitor device locations for security": "مراقبة مواقع الأجهزة للأمان",
    "Monitor security events in real-time": "مراقبة أحداث الأمان في الوقت الفعلي",
    
    # Monthly & Performance
    "Monthly Performance": "الأداء الشهري",
    "Monthly release": "إصدار شهري",
    "Multiple failed login attempts from IP 192.168.1.100": "محاولات تسجيل دخول فاشلة متعددة من IP 192.168.1.100",
    
    # My Content
    "My Ads": "إعلاناتي",
    "My Analytics": "تحليلاتي",
    "My Events": "أحداثي",
    "My Tickets": "تذاكري",
    "My Walks": "جولاتي",
    
    # Navigation
    "Navigate to message in chat": "الانتقال إلى الرسالة في المحادثة",
    "Navigation": "التنقل",
    "Navigation Error": "خطأ في التنقل",
    "Navigation error: {error}": "خطأ في التنقل: {error}",
    "Navigation is working!": "التنقل يعمل!",
    "Navigation not active": "التنقل غير نشط",
    "Navigation paused while app is in background": "تم إيقاف التنقل مؤقتًا أثناء تشغيل التطبيق في الخلفية",
    "Navigation resumed": "تم استئناف التنقل",
    "Navigation stopped": "توقف التنقل",
    "Navigation stopped.": "توقف التنقل.",
    
    # Nearby
    "Nearby": "قريب",
    "Nearby Art Walks": "الجولات الفنية القريبة",
    
    # Network & Groups
    "Network error. Please check your connection.": "خطأ في الشبكة. يرجى التحقق من اتصالك.",
    "New Group": "مجموعة جديدة",
    "New admin user added": "تمت إضافة مستخدم مشرف جديد",
    "New password is too weak": "كلمة المرور الجديدة ضعيفة جدًا",
    "New passwords do not match": "كلمات المرور الجديدة غير متطابقة",
    
    # No Results Messages
    "No Galleries Available": "لا توجد معارض متاحة",
    "No additional images added yet": "لم يتم إضافة صور إضافية بعد",
    "No art nearby. Try moving to a different location!": "لا توجد أعمال فنية قريبة. حاول الانتقال إلى موقع مختلف!",
    "No art pieces available.": "لا توجد قطع فنية متاحة.",
    "No artist performance data available": "لا توجد بيانات أداء فنان متاحة",
    "No artists found": "لم يتم العثور على فنانين",
    "No artists nearby": "لا يوجد فنانون قريبون",
    "No artwork available": "لا توجد أعمال فنية متاحة",
    "No artwork data available": "لا توجد بيانات للأعمال الفنية متاحة",
    "No artwork found matching your criteria.": "لم يتم العثور على عمل فني يطابق معاييرك.",
    "No artwork nearby": "لا توجد أعمال فنية قريبة",
    "No artwork performance data available yet": "لا توجد بيانات أداء الأعمال الفنية متاحة بعد",
    "No artwork yet": "لا توجد أعمال فنية بعد",
    "No artworks yet": "لا توجد أعمال فنية بعد",
    "No audio file selected": "لم يتم تحديد ملف صوتي",
    "No audio files added yet": "لم يتم إضافة ملفات صوتية بعد",
    "No blocked users": "لا يوجد مستخدمون محظورون",
    "No capture found": "لم يتم العثور على لقطة",
    "No captures found nearby": "لم يتم العثور على لقطات قريبة",
    "No collections found": "لم يتم العثور على مجموعات",
    "No completed walks yet": "لا توجد جولات مكتملة بعد",
    "No contacts found": "لم يتم العثور على جهات اتصال",
    "No content found": "لم يتم العثور على محتوى",
    "No content provided": "لم يتم توفير محتوى",
    "No data available for the selected period": "لا توجد بيانات متاحة للفترة المحددة",
    "No description provided": "لم يتم توفير وصف",
    "No engaged followers yet": "لا يوجد متابعون متفاعلون بعد",
    "No events found": "لم يتم العثور على أحداث",
    "No events near you": "لا توجد أحداث قريبة منك",
    "No events nearby": "لا توجد أحداث قريبة",
    "No feed items available": "لا توجد عناصر موجز متاحة",
    "No flagged events": "لا توجد أحداث مبلغ عنها",
    "No followers yet": "لا يوجد متابعون بعد",
    "No galleries or museums found in your area": "لم يتم العثور على معارض أو متاحف في منطقتك",
    "No image selected": "لم يتم تحديد صورة",
    "No location data available": "لا توجد بيانات موقع متاحة",
    "No messages found.": "لم يتم العثور على رسائل.",
    "No messages in this thread": "لا توجد رسائل في هذا الموضوع",
    "No navigation step available": "لا توجد خطوة تنقل متاحة",
    "No one is online right now": "لا أحد متصل الآن",
    "No past tickets": "لا توجد تذاكر سابقة",
    "No recent activity": "لا يوجد نشاط حديث",
    "No recent ad activity": "لا يوجد نشاط إعلاني حديث",
    "No recent alerts": "لا توجد تنبيهات حديثة",
    "No recent transactions": "لا توجد معاملات حديثة",
    "No referral data available": "لا توجد بيانات إحالة متاحة",
    'No results for "${_searchController.text}"': 'لا توجد نتائج لـ "${_searchController.text}"',
    'No results for "{query}"': 'لا توجد نتائج لـ "{query}"',
    "No results found": "لم يتم العثور على نتائج",
    "No results.": "لا توجد نتائج.",
    "No revenue data available for selected time period": "لا توجد بيانات إيرادات متاحة للفترة الزمنية المحددة",
    "No saved walks yet": "لا توجد جولات محفوظة بعد",
    "No tickets yet": "لا توجد تذاكر بعد",
    "No title provided": "لم يتم توفير عنوان",
    "No transactions found": "لم يتم العثور على معاملات",
    "No trending events": "لا توجد أحداث رائجة",
    "No upcoming tickets": "لا توجد تذاكر قادمة",
    "No user is currently signed in": "لا يوجد مستخدم مسجل الدخول حاليًا",
    "No users found": "لم يتم العثور على مستخدمين",
    "No users nearby": "لا يوجد مستخدمون قريبون",
    "No users online": "لا يوجد مستخدمون متصلون",
    "No videos added yet": "لم يتم إضافة مقاطع فيديو بعد",
    "No visitor data available": "لا توجد بيانات زوار متاحة",
    "No walks created yet": "لم يتم إنشاء جولات بعد",
    "No walks in progress": "لا توجد جولات قيد التقدم",
    "No weekend events": "لا توجد أحداث في عطلة نهاية الأسبوع",
    
    # Other States
    "Not authenticated": "غير مصادق عليه",
    "Not provided": "غير مقدم",
    "Nothing here yet": "لا يوجد شيء هنا بعد",
    "Now following {fullName}": "الآن تتابع {fullName}",
    
    # Numbers & Other
    "Number of Tracks": "عدد المقاطع",
    "OR": "أو",
    "Optimized for streaming playback": "محسّن لتشغيل البث",
    "Original uploaded file": "الملف الأصلي المحمل",
    "Other": "أخرى",
    
    # Package & Paid
    "Package Name": "اسم الحزمة",
    "Paid Commissions": "العمولات المدفوعة",
    "Participants": "المشاركون",
    
    # Password Security
    "Password Security": "أمان كلمة المرور",
    "Password does not meet security requirements": "كلمة المرور لا تلبي متطلبات الأمان",
    "Password is too weak": "كلمة المرور ضعيفة جدًا",
    "Password is too weak. Please use a stronger password.": "كلمة المرور ضعيفة جدًا. يرجى استخدام كلمة مرور أقوى.",
    "Password must be at least 8 characters": "يجب أن تتكون كلمة المرور من 8 أحرف على الأقل",
    "Password must be at least 8 characters long and contain uppercase, lowercase, and numbers.": "يجب أن تتكون كلمة المرور من 8 أحرف على الأقل وتحتوي على أحرف كبيرة وصغيرة وأرقام.",
    "Password policy updated": "تم تحديث سياسة كلمة المرور",
    "Password reset failed. Please try again. ({code})": "فشلت إعادة تعيين كلمة المرور. يرجى المحاولة مرة أخرى. ({code})",
    "Password reset link sent. Please check your email.": "تم إرسال رابط إعادة تعيين كلمة المرور. يرجى التحقق من بريدك الإلكتروني.",
    
    # Past & Payment
    "Past": "الماضي",
    "Pause Preview": "إيقاف المعاينة مؤقتًا",
    "Payment Amount:": "مبلغ الدفع:",
    "Payment ID:": "معرف الدفع:",
    "Payout #${index + 1}": "الدفع #${index + 1}",
    "Peak Today": "الذروة اليوم",
    
    # Pending
    "Pending Commissions": "العمولات المعلقة",
    "Pending Reviews": "المراجعات المعلقة",
    "Pending Verification": "التحقق المعلق",
    
    # Performance
    "Performance Insights": "رؤى الأداء",
    "Performance Optimization": "تحسين الأداء",
    "Periodically require password updates": "طلب تحديثات كلمة المرور بشكل دوري",
}

def apply_translations():
    """Apply Arabic mega translations pass 9 to ar.json"""
    input_file = '/Users/kristybock/artbeat/assets/translations/ar.json'
    output_file = input_file
    
    print("\n" + "="*60)
    print("Arabic Translation - Mega Pass 9")
    print("Focus: Loading, No Results, Management, Settings")
    print("="*60 + "\n")
    
    # Load current translations
    with open(input_file, 'r', encoding='utf-8') as f:
        translations = json.load(f)
    
    # Track progress
    applied_count = 0
    
    # Apply translations
    for english_text, arabic_text in AR_MEGA_TRANSLATIONS_9.items():
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
    print("Arabic Translation - Mega Pass 9 Complete")
    print("="*60)
    print(f"Translations applied: {applied_count}")
    print(f"Remaining bracketed entries: {remaining}")
    print(f"Overall progress: {completed}/{total} ({percentage:.1f}%)")
    print(f"File saved: {output_file}")
    print("="*60 + "\n")

if __name__ == "__main__":
    apply_translations()
