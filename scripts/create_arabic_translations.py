#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Create Arabic (ar.json) translation file for Artbeat app
This creates an initial Arabic translation with common terms translated
"""

import json
import os

# Get the project root directory
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
translations_dir = os.path.join(project_root, 'assets', 'translations')

# Load English as source
en_file = os.path.join(translations_dir, 'en.json')
with open(en_file, 'r', encoding='utf-8') as f:
    en_data = json.load(f)

# Comprehensive Arabic translations
# Maps English text to Arabic translations
ARABIC_TRANSLATIONS = {
    # Common Actions
    "Cancel": "إلغاء",
    "Dismiss": "تجاهل",
    "Reject": "رفض",
    "Take Action": "اتخاذ إجراء",
    "Delete": "حذف",
    "Edit": "تعديل",
    "Save": "حفظ",
    "Submit": "إرسال",
    "Confirm": "تأكيد",
    "Continue": "متابعة",
    "Back": "رجوع",
    "Next": "التالي",
    "Previous": "السابق",
    "Close": "إغلاق",
    "Open": "فتح",
    "View": "عرض",
    "Search": "بحث",
    "Filter": "تصفية",
    "Sort": "ترتيب",
    "Apply": "تطبيق",
    "Reset": "إعادة تعيين",
    "Clear": "مسح",
    "Refresh": "تحديث",
    "Reload": "إعادة تحميل",
    "Upload": "رفع",
    "Download": "تنزيل",
    "Share": "مشاركة",
    "Copy": "نسخ",
    "Paste": "لصق",
    "Cut": "قص",
    "Select": "اختيار",
    "Deselect": "إلغاء الاختيار",
    "Select All": "تحديد الكل",
    "Add": "إضافة",
    "Remove": "إزالة",
    "Create": "إنشاء",
    "Update": "تحديث",
    "Approve": "موافقة",
    "Publish": "نشر",
    "Archive": "أرشفة",
    "Restore": "استعادة",
    "Export": "تصدير",
    "Import": "استيراد",
    "Print": "طباعة",
    "Send": "إرسال",
    "Receive": "استقبال",
    "Reply": "رد",
    "Forward": "إعادة توجيه",
    "Retry": "إعادة المحاولة",
    "Try Again": "حاول مرة أخرى",
    "Loading...": "جارٍ التحميل...",
    "Loading": "جارٍ التحميل",
    "Saving...": "جارٍ الحفظ...",
    "Processing...": "جارٍ المعالجة...",
    
    # Admin & Management
    "No flagged ads": "لا توجد إعلانات مبلغ عنها",
    "No ads pending review": "لا توجد إعلانات قيد المراجعة",
    "No pending reports": "لا توجد تقارير معلقة",
    "Advertisement Management": "إدارة الإعلانات",
    "Admin Dashboard": "لوحة تحكم المشرف",
    "User Management": "إدارة المستخدمين",
    "Content Moderation": "إدارة المحتوى",
    "Security Center": "مركز الأمان",
    "Analytics": "التحليلات",
    "Settings": "الإعدادات",
    "Reports": "التقارير",
    "Active Users": "المستخدمون النشطون",
    "Total Users": "إجمالي المستخدمين",
    "Revenue": "الإيرادات",
    "Total Revenue": "إجمالي الإيرادات",
    "Statistics": "الإحصائيات",
    "Overview": "نظرة عامة",
    "Dashboard": "لوحة التحكم",
    "System Status": "حالة النظام",
    "System Health": "صحة النظام",
    "Performance": "الأداء",
    "Monitoring": "المراقبة",
    "Logs": "السجلات",
    "Audit": "المراجعة",
    "Backup": "النسخ الاحتياطي",
    "Security": "الأمان",
    "Permissions": "الأذونات",
    "Access Control": "التحكم في الوصول",
    
    # Status & States
    "Active": "نشط",
    "Inactive": "غير نشط",
    "Pending": "قيد الانتظار",
    "Approved": "موافق عليه",
    "Rejected": "مرفوض",
    "Published": "منشور",
    "Draft": "مسودة",
    "Archived": "مؤرشف",
    "Deleted": "محذوف",
    "Completed": "مكتمل",
    "Failed": "فشل",
    "Success": "نجح",
    "Error": "خطأ",
    "Warning": "تحذير",
    "Info": "معلومات",
    "Online": "متصل",
    "Offline": "غير متصل",
    "Available": "متاح",
    "Unavailable": "غير متاح",
    "Enabled": "مفعّل",
    "Disabled": "معطّل",
    "Verified": "موثّق",
    "Unverified": "غير موثّق",
    
    # User & Profile
    "Profile": "الملف الشخصي",
    "My Profile": "ملفي الشخصي",
    "Edit Profile": "تعديل الملف الشخصي",
    "View Profile": "عرض الملف الشخصي",
    "Account": "الحساب",
    "My Account": "حسابي",
    "Account Settings": "إعدادات الحساب",
    "Personal Info": "المعلومات الشخصية",
    "Email": "البريد الإلكتروني",
    "Password": "كلمة المرور",
    "Username": "اسم المستخدم",
    "Name": "الاسم",
    "First Name": "الاسم الأول",
    "Last Name": "اسم العائلة",
    "Phone": "الهاتف",
    "Phone Number": "رقم الهاتف",
    "Address": "العنوان",
    "Bio": "السيرة الذاتية",
    "About": "حول",
    "About Me": "عني",
    "Preferences": "التفضيلات",
    "Privacy": "الخصوصية",
    "Privacy Settings": "إعدادات الخصوصية",
    "Notifications": "الإشعارات",
    "Notification Settings": "إعدادات الإشعارات",
    "Language": "اللغة",
    "Theme": "المظهر",
    "Dark": "داكن",
    "Light": "فاتح",
    "Auto": "تلقائي",
    
    # Authentication
    "Login": "تسجيل الدخول",
    "Sign In": "تسجيل الدخول",
    "Sign Up": "التسجيل",
    "Register": "تسجيل",
    "Logout": "تسجيل الخروج",
    "Sign Out": "تسجيل الخروج",
    "Forgot Password": "نسيت كلمة المرور",
    "Reset Password": "إعادة تعيين كلمة المرور",
    "Change Password": "تغيير كلمة المرور",
    "Current Password": "كلمة المرور الحالية",
    "New Password": "كلمة المرور الجديدة",
    "Confirm Password": "تأكيد كلمة المرور",
    "Remember Me": "تذكرني",
    "Invalid email address.": "عنوان البريد الإلكتروني غير صالح.",
    "Invalid password.": "كلمة المرور غير صالحة.",
    "Password must be at least 6 characters": "يجب أن تتكون كلمة المرور من 6 أحرف على الأقل",
    "Passwords do not match": "كلمات المرور غير متطابقة",
    "Please enter a valid email": "الرجاء إدخال بريد إلكتروني صالح",
    "Email is required": "البريد الإلكتروني مطلوب",
    "Password is required": "كلمة المرور مطلوبة",
    "This account has been disabled.": "تم تعطيل هذا الحساب.",
    "No user found with this email.": "لم يتم العثور على مستخدم بهذا البريد الإلكتروني.",
    
    # Art & Artists
    "Art": "فن",
    "Artwork": "عمل فني",
    "Artworks": "الأعمال الفنية",
    "Artist": "فنان",
    "Artists": "الفنانين",
    "Gallery": "معرض",
    "Galleries": "المعارض",
    "Collection": "مجموعة",
    "Collections": "المجموعات",
    "Exhibition": "معرض",
    "Exhibitions": "المعارض",
    "My Artwork": "أعمالي الفنية",
    "My Art": "فني",
    "Upload Artwork": "رفع عمل فني",
    "Create Artwork": "إنشاء عمل فني",
    "Edit Artwork": "تعديل العمل الفني",
    "Delete Artwork": "حذف العمل الفني",
    "View Artwork": "عرض العمل الفني",
    "Browse Artwork": "تصفح الأعمال الفنية",
    "Featured Artists": "الفنانون المميزون",
    "Popular Artists": "الفنانون المشهورون",
    "Artist Profile": "ملف الفنان الشخصي",
    "Become an Artist": "كن فنانًا",
    "Follow": "متابعة",
    "Unfollow": "إلغاء المتابعة",
    "Followers": "المتابعون",
    "Following": "يتابع",
    "Likes": "الإعجابات",
    "Comments": "التعليقات",
    "Views": "المشاهدات",
    "Title": "العنوان",
    "Description": "الوصف",
    "Category": "الفئة",
    "Categories": "الفئات",
    "Tags": "الوسوم",
    "Style": "الأسلوب",
    "Styles": "الأساليب",
    "Medium": "الوسيط",
    "Mediums": "الوسائط",
    "Price": "السعر",
    "For Sale": "للبيع",
    "Not For Sale": "غير معروض للبيع",
    "Sold": "مباع",
    
    # Messaging
    "Messages": "الرسائل",
    "Message": "رسالة",
    "New Message": "رسالة جديدة",
    "Send Message": "إرسال رسالة",
    "Type a message...": "اكتب رسالة...",
    "No messages yet": "لا توجد رسائل بعد",
    "No messages": "لا توجد رسائل",
    "Chat": "محادثة",
    "Chats": "المحادثات",
    "New Chat": "محادثة جديدة",
    "Group Chat": "محادثة جماعية",
    "Create Group": "إنشاء مجموعة",
    "Group Name": "اسم المجموعة",
    "Add Members": "إضافة أعضاء",
    "Members": "الأعضاء",
    "Leave Group": "مغادرة المجموعة",
    "Block User": "حظر المستخدم",
    "Unblock User": "إلغاء حظر المستخدم",
    "Blocked Users": "المستخدمون المحظورون",
    "Report User": "الإبلاغ عن المستخدم",
    "User blocked successfully": "تم حظر المستخدم بنجاح",
    "User unblocked successfully": "تم إلغاء حظر المستخدم بنجاح",
    "Failed to send message": "فشل في إرسال الرسالة",
    "Chat Settings": "إعدادات المحادثة",
    "Mute Notifications": "كتم الإشعارات",
    "Delete Chat": "حذف المحادثة",
    "Search Messages": "البحث في الرسائل",
    "Online Users": "المستخدمون المتصلون",
    "Recent Chats": "المحادثات الأخيرة",
    
    # Art Walks
    "Art Walk": "جولة فنية",
    "Art Walks": "الجولات الفنية",
    "My Art Walks": "جولاتي الفنية",
    "Create Art Walk": "إنشاء جولة فنية",
    "Start Art Walk": "بدء جولة فنية",
    "Complete Walk": "إكمال الجولة",
    "Pause Walk": "إيقاف الجولة مؤقتًا",
    "Resume Walk": "استئناف الجولة",
    "Nearby Art": "الفن القريب",
    "Discover": "اكتشف",
    "Explore": "استكشف",
    "Browse": "تصفح",
    "Captures": "الالتقاطات",
    "My Captures": "التقاطاتي",
    "Take Photo": "التقاط صورة",
    "Upload Capture": "رفع التقاط",
    "Featured": "مميز",
    "Trending": "رائج",
    "Popular": "شائع",
    "Recent": "حديث",
    "New": "جديد",
    
    # Achievements
    "Achievements": "الإنجازات",
    "My Achievements": "إنجازاتي",
    "Level": "المستوى",
    "Points": "النقاط",
    "Progress": "التقدم",
    "Your Progress": "تقدمك",
    "Complete": "مكتمل",
    "completed": "مكتمل",
    "In Progress": "قيد التقدم",
    "Badge": "شارة",
    "Badges": "الشارات",
    "Reward": "مكافأة",
    "Rewards": "المكافآت",
    
    # Events & Community
    "Events": "الأحداث",
    "Event": "حدث",
    "Community": "المجتمع",
    "Community Feed": "موجز المجتمع",
    "Feed": "الموجز",
    "Activity": "النشاط",
    "Posts": "المنشورات",
    "Post": "منشور",
    "Create Post": "إنشاء منشور",
    "Like": "إعجاب",
    "Unlike": "إلغاء الإعجاب",
    "Comment": "تعليق",
    
    # Transactions
    "Transaction": "معاملة",
    "Transactions": "المعاملات",
    "Payment": "دفع",
    "Purchase": "شراء",
    "Buy": "شراء",
    "Sell": "بيع",
    "Total": "الإجمالي",
    "Order": "طلب",
    "Orders": "الطلبات",
    "Processing": "جارٍ المعالجة",
    "Refund": "استرداد",
    "Request Refund": "طلب استرداد",
    
    # General
    "Yes": "نعم",
    "No": "لا",
    "OK": "موافق",
    "Got it": "فهمت",
    "All": "الكل",
    "None": "لا شيء",
    "More": "المزيد",
    "View All": "عرض الكل",
    "Details": "التفاصيل",
    "Help": "مساعدة",
    "Support": "الدعم",
    "Contact": "اتصل",
    "Feedback": "الملاحظات",
    "Report": "الإبلاغ",
    "Version": "الإصدار",
    "Skip": "تخطي",
    "Finish": "إنهاء",
    "Get Started": "ابدأ",
    "Welcome": "مرحبًا",
    "Thanks": "شكرًا",
}

# Create Arabic translation
ar_data = {}
for key, en_value in en_data.items():
    if en_value in ARABIC_TRANSLATIONS:
        ar_data[key] = ARABIC_TRANSLATIONS[en_value]
    else:
        # Keep placeholder for untranslated entries
        ar_data[key] = f"[{en_value}]"

# Save Arabic translation file
ar_file = os.path.join(translations_dir, 'ar.json')
with open(ar_file, 'w', encoding='utf-8') as f:
    json.dump(ar_data, f, ensure_ascii=False, indent=2)

# Count translations
total = len(ar_data)
translated = sum(1 for v in ar_data.values() if not (isinstance(v, str) and v.startswith('[') and v.endswith(']')))
untranslated = total - translated

print(f"{'='*60}")
print(f"Arabic Translation File Created")
print(f"{'='*60}")
print(f"Total entries: {total}")
print(f"Translated: {translated} ({(translated/total*100):.1f}%)")
print(f"Remaining (bracketed): {untranslated} ({(untranslated/total*100):.1f}%)")
print(f"\nFile saved: {ar_file}")
print(f"\nNote: Bracketed entries need manual translation.")
print(f"This initial file provides ~{len(ARABIC_TRANSLATIONS)} common Arabic translations.")
print(f"{'='*60}")
