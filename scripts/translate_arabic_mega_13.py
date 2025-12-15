#!/usr/bin/env python3
"""
Arabic Translation - Mega Pass 13
Target: Explore/Export/Failed/Favorite/Feature/Feed/File/Filter sections
Coverage: ~350 translations
"""

import json

# Load current translations
with open('assets/translations/ar.json', 'r', encoding='utf-8') as f:
    translations = json.load(f)

# Mega Pass 13 Translation Dictionary (350 entries)
MEGA_13 = {
    # Explore & Explorer
    "Explore": "استكشف",
    "Explore Art": "استكشف الفن",
    "Explore Art Walks": "استكشف الجولات الفنية",
    "Explore Artists": "استكشف الفنانين",
    "Explore Events": "استكشف الأحداث",
    "Explore Gallery": "استكشف المعرض",
    "Explore Local Art": "استكشف الفن المحلي",
    "Explore More": "استكشف المزيد",
    "Explore art": "استكشف الفن",
    "Explore art walks": "استكشف الجولات الفنية",
    "Explore artists": "استكشف الفنانين",
    "Explore local art": "استكشف الفن المحلي",
    "Explorer": "المستكشف",
    
    # Export & Exported
    "Export": "تصدير",
    "Export Analytics": "تصدير التحليلات",
    "Export Data": "تصدير البيانات",
    "Export Report": "تصدير التقرير",
    "Export Settings": "تصدير الإعدادات",
    "Export complete": "اكتمل التصدير",
    "Export data": "تصدير البيانات",
    "Export failed": "فشل التصدير",
    "Exported": "تم التصدير",
    "Exporting...": "جارٍ التصدير...",
    
    # Failed & Failure
    "FAILED": "فشل",
    "Failed": "فشل",
    "Failed to approve": "فشل في الموافقة",
    "Failed to block user": "فشل في حظر المستخدم",
    "Failed to complete": "فشل في الإكمال",
    "Failed to connect": "فشل في الاتصال",
    "Failed to create": "فشل في الإنشاء",
    "Failed to delete": "فشل في الحذف",
    "Failed to follow": "فشل في المتابعة",
    "Failed to like": "فشل في الإعجاب",
    "Failed to load": "فشل في التحميل",
    "Failed to load art walk": "فشل في تحميل الجولة الفنية",
    "Failed to load artwork": "فشل في تحميل العمل الفني",
    "Failed to load data": "فشل في تحميل البيانات",
    "Failed to load image": "فشل في تحميل الصورة",
    "Failed to load profile": "فشل في تحميل الملف الشخصي",
    "Failed to load user": "فشل في تحميل المستخدم",
    "Failed to refresh": "فشل في التحديث",
    "Failed to reject": "فشل في الرفض",
    "Failed to save": "فشل في الحفظ",
    "Failed to send": "فشل في الإرسال",
    "Failed to send message": "فشل في إرسال الرسالة",
    "Failed to sign in": "فشل في تسجيل الدخول",
    "Failed to sign out": "فشل في تسجيل الخروج",
    "Failed to sign up": "فشل في التسجيل",
    "Failed to start": "فشل في البدء",
    "Failed to submit": "فشل في الإرسال",
    "Failed to unblock user": "فشل في إلغاء حظر المستخدم",
    "Failed to unfollow": "فشل في إلغاء المتابعة",
    "Failed to unlike": "فشل في إلغاء الإعجاب",
    "Failed to update": "فشل في التحديث",
    "Failed to upload": "فشل في التحميل",
    "Failed to upload image": "فشل في تحميل الصورة",
    "Failure": "فشل",
    
    # Favorite & Favorites
    "Favorite": "مفضل",
    "Favorite Art": "الفن المفضل",
    "Favorite Artist": "الفنان المفضل",
    "Favorite Artists": "الفنانون المفضلون",
    "Favorite Artworks": "الأعمال الفنية المفضلة",
    "Favorite Events": "الأحداث المفضلة",
    "Favorite Walks": "الجولات المفضلة",
    "Favorite added": "تمت إضافة المفضل",
    "Favorite removed": "تمت إزالة المفضل",
    "Favorited": "مفضل",
    "Favorites": "المفضلات",
    
    # Feature & Featured
    "Feature": "ميزة",
    "Feature Art": "فن مميز",
    "Feature Artist": "فنان مميز",
    "Feature This": "ميز هذا",
    "Featured": "مميز",
    "Featured Art": "الفن المميز",
    "Featured Artist": "الفنان المميز",
    "Featured Artists": "الفنانون المميزون",
    "Featured Artwork": "العمل الفني المميز",
    "Featured Artworks": "الأعمال الفنية المميزة",
    "Featured Content": "المحتوى المميز",
    "Featured Events": "الأحداث المميزة",
    "Featured Walks": "الجولات المميزة",
    "Featured art": "الفن المميز",
    "Featured artists": "الفنانون المميزون",
    "Features": "الميزات",
    
    # Feed
    "Feed": "الخلاصة",
    "Feed Settings": "إعدادات الخلاصة",
    "Feedback": "ملاحظات",
    "Feedback submitted successfully": "تم إرسال الملاحظات بنجاح",
    
    # File & Files
    "File": "ملف",
    "File Name": "اسم الملف",
    "File Preview": "معاينة الملف",
    "File Selected": "تم تحديد الملف",
    "File Size": "حجم الملف",
    "File Type": "نوع الملف",
    "File Upload": "تحميل الملف",
    "File cannot exceed 10MB": "لا يمكن أن يتجاوز الملف 10 ميجابايت",
    "File cannot exceed 50MB": "لا يمكن أن يتجاوز الملف 50 ميجابايت",
    "File not found": "الملف غير موجود",
    "File selected": "تم تحديد الملف",
    "File size too large": "حجم الملف كبير جدًا",
    "File too large": "الملف كبير جدًا",
    "File type not supported": "نوع الملف غير مدعوم",
    "File uploaded successfully": "تم تحميل الملف بنجاح",
    "Files": "الملفات",
    
    # Filter & Filters
    "Filter": "فلتر",
    "Filter By": "تصفية حسب",
    "Filter By Category": "تصفية حسب الفئة",
    "Filter By Date": "تصفية حسب التاريخ",
    "Filter By Location": "تصفية حسب الموقع",
    "Filter By Price": "تصفية حسب السعر",
    "Filter By Rating": "تصفية حسب التقييم",
    "Filter By Status": "تصفية حسب الحالة",
    "Filter By Type": "تصفية حسب النوع",
    "Filter Options": "خيارات التصفية",
    "Filter Results": "تصفية النتائج",
    "Filter by category": "تصفية حسب الفئة",
    "Filter by date": "تصفية حسب التاريخ",
    "Filter by location": "تصفية حسب الموقع",
    "Filter by price": "تصفية حسب السعر",
    "Filter by rating": "تصفية حسب التقييم",
    "Filter by status": "تصفية حسب الحالة",
    "Filter by type": "تصفية حسب النوع",
    "Filtered": "مصفى",
    "Filters": "الفلاتر",
    "Filters Applied": "تم تطبيق الفلاتر",
    
    # Find & Finding
    "Find": "بحث",
    "Find Art": "بحث عن الفن",
    "Find Artist": "بحث عن فنان",
    "Find Artists": "بحث عن الفنانين",
    "Find Events": "بحث عن الأحداث",
    "Find Friends": "بحث عن الأصدقاء",
    "Find Local Art": "بحث عن الفن المحلي",
    "Find More": "بحث عن المزيد",
    "Find art": "بحث عن الفن",
    "Find artists": "بحث عن الفنانين",
    "Find events": "بحث عن الأحداث",
    "Find friends": "بحث عن الأصدقاء",
    "Find local art": "بحث عن الفن المحلي",
    "Finding...": "جارٍ البحث...",
    
    # Finish & Finished
    "Finish": "إنهاء",
    "Finish Later": "إنهاء لاحقًا",
    "Finish Setup": "إنهاء الإعداد",
    "Finish Walk": "إنهاء الجولة",
    "Finish setup": "إنهاء الإعداد",
    "Finished": "منتهٍ",
    
    # Follow & Following
    "FOLLOW": "متابعة",
    "Follow": "متابعة",
    "Follow Artist": "متابعة الفنان",
    "Follow User": "متابعة المستخدم",
    "Follow artist": "متابعة الفنان",
    "Follow user": "متابعة المستخدم",
    "Followed": "متابَع",
    "Follower": "متابع",
    "Followers": "المتابعون",
    "Following": "متابَع",
    "Following ${count}": "يتابع ${count}",
    "Following {count}": "يتابع {count}",
    
    # Forgot & Forgotten
    "Forgot Password": "نسيت كلمة المرور",
    "Forgot Password?": "نسيت كلمة المرور؟",
    "Forgot password": "نسيت كلمة المرور",
    "Forgot password?": "نسيت كلمة المرور؟",
    "Forgot your password?": "نسيت كلمة المرور؟",
    
    # Free & Freedom
    "Free": "مجاني",
    "Free Entry": "دخول مجاني",
    "Free Event": "حدث مجاني",
    "Free Shipping": "شحن مجاني",
    "Free Trial": "تجربة مجانية",
    "Free for everyone": "مجاني للجميع",
    
    # Friend & Friends
    "Friend": "صديق",
    "Friend Request": "طلب صداقة",
    "Friend Requests": "طلبات الصداقة",
    "Friend request sent": "تم إرسال طلب الصداقة",
    "Friends": "الأصدقاء",
    
    # From
    "From": "من",
    "From ${startDate} to ${endDate}": "من ${startDate} إلى ${endDate}",
    "From {startDate} to {endDate}": "من {startDate} إلى {endDate}",
    "From your location": "من موقعك",
    
    # Full & Fullscreen
    "Full Name": "الاسم الكامل",
    "Full Profile": "الملف الشخصي الكامل",
    "Full Screen": "ملء الشاشة",
    "Full View": "عرض كامل",
    "Full name": "الاسم الكامل",
    "Full name cannot be empty": "لا يمكن أن يكون الاسم الكامل فارغًا",
    "Full name is required": "الاسم الكامل مطلوب",
    "Fullscreen": "ملء الشاشة",
    
    # Gallery
    "Gallery": "المعرض",
    "Gallery Image": "صورة المعرض",
    "Gallery Images": "صور المعرض",
    "Gallery Settings": "إعدادات المعرض",
    "Gallery View": "عرض المعرض",
    
    # General & Generate
    "General": "عام",
    "General Information": "معلومات عامة",
    "General Settings": "الإعدادات العامة",
    "Generate": "توليد",
    "Generate Code": "توليد الرمز",
    "Generate Link": "توليد الرابط",
    "Generate QR Code": "توليد رمز QR",
    "Generate Report": "توليد التقرير",
    "Generated": "تم التوليد",
    "Generating...": "جارٍ التوليد...",
    
    # Get & Getting
    "Get": "احصل على",
    "Get App": "احصل على التطبيق",
    "Get Code": "احصل على الرمز",
    "Get Directions": "احصل على الاتجاهات",
    "Get Help": "احصل على المساعدة",
    "Get Link": "احصل على الرابط",
    "Get More": "احصل على المزيد",
    "Get Notified": "احصل على الإشعارات",
    "Get Started": "ابدأ",
    "Get Verified": "احصل على التحقق",
    "Get directions": "احصل على الاتجاهات",
    "Get help": "احصل على المساعدة",
    "Get started": "ابدأ",
    "Getting started": "البدء",
    
    # Gift & Gifts
    "Gift": "هدية",
    "Gift Card": "بطاقة هدية",
    "Gift Cards": "بطاقات الهدايا",
    "Gift Options": "خيارات الهدايا",
    "Gift This": "أهدِ هذا",
    "Gift sent successfully": "تم إرسال الهدية بنجاح",
    "Gifted": "مُهدى",
    "Gifts": "الهدايا",
    
    # Give & Given
    "Give": "إعطاء",
    "Give Feedback": "إعطاء ملاحظات",
    "Give Permission": "إعطاء الإذن",
    "Give Rating": "إعطاء تقييم",
    "Give Review": "إعطاء مراجعة",
    "Give feedback": "إعطاء ملاحظات",
    "Give rating": "إعطاء تقييم",
    "Given": "معطى",
    
    # Go & Going
    "Go": "انتقل",
    "Go Back": "العودة",
    "Go Home": "الانتقال للصفحة الرئيسية",
    "Go Live": "بث مباشر",
    "Go Offline": "الانتقال لوضع عدم الاتصال",
    "Go Online": "الانتقال لوضع الاتصال",
    "Go Premium": "الترقية للمميز",
    "Go Pro": "الترقية للمحترف",
    "Go To": "الانتقال إلى",
    "Go back": "العودة",
    "Go home": "الانتقال للصفحة الرئيسية",
    "Go to": "الانتقال إلى",
    "Going": "سأذهب",
    
    # Grid & Group
    "Grid": "شبكة",
    "Grid View": "عرض الشبكة",
    "Group": "مجموعة",
    "Group Chat": "محادثة جماعية",
    "Group Chats": "المحادثات الجماعية",
    "Group Name": "اسم المجموعة",
    "Group Settings": "إعدادات المجموعة",
    "Group chat": "محادثة جماعية",
    "Group created": "تم إنشاء المجموعة",
    "Group deleted": "تم حذف المجموعة",
    "Group name": "اسم المجموعة",
    "Group updated": "تم تحديث المجموعة",
    "Groups": "المجموعات",
    
    # Guest & Guests
    "Guest": "ضيف",
    "Guest Mode": "وضع الضيف",
    "Guest User": "مستخدم ضيف",
    "Guests": "الضيوف",
    
    # Guide & Guidelines
    "Guide": "دليل",
    "Guided Tour": "جولة إرشادية",
    "Guidelines": "الإرشادات",
    "Guides": "الأدلة",
    
    # Handle & Handled
    "Handle": "معالج",
    "Handled": "معالَج",
    "Handler": "المعالج",
    "Handling...": "جارٍ المعالجة...",
    
    # Help & Helper
    "HELP": "مساعدة",
    "Help": "مساعدة",
    "Help & Support": "المساعدة والدعم",
    "Help Center": "مركز المساعدة",
    "Help Guide": "دليل المساعدة",
    "Help center": "مركز المساعدة",
    
    # Hidden & Hide
    "Hidden": "مخفي",
    "Hide": "إخفاء",
    "Hide Comments": "إخفاء التعليقات",
    "Hide Details": "إخفاء التفاصيل",
    "Hide Likes": "إخفاء الإعجابات",
    "Hide Posts": "إخفاء المنشورات",
    "Hide Profile": "إخفاء الملف الشخصي",
    "Hide comments": "إخفاء التعليقات",
}

# Apply translations
applied_count = 0
for english_text, arabic_text in MEGA_13.items():
    bracketed = f"[{english_text}]"
    if bracketed in translations.values():
        for key, value in list(translations.items()):
            if value == bracketed:
                translations[key] = arabic_text
                applied_count += 1
                if applied_count <= 20 or applied_count % 50 == 0:
                    print(f'  ✓ "{english_text}" → "{arabic_text}"')
                break

# Save updated translations
with open('assets/translations/ar.json', 'w', encoding='utf-8') as f:
    json.dump(translations, f, ensure_ascii=False, indent=2)

# Count remaining
remaining = sum(1 for v in translations.values() if v.startswith('[') and v.endswith(']'))
total = len(translations)
completed = total - remaining
percentage = (completed / total * 100) if total > 0 else 0

print(f"\n{'='*60}")
print("Arabic Translation - MEGA PASS 13")
print("="*60)
print(f"Translations applied: {applied_count}")
print(f"Remaining bracketed entries: {remaining}")
print(f"Overall progress: {completed}/{total} ({percentage:.1f}%)")
print(f"File saved: assets/translations/ar.json")
print("="*60)
