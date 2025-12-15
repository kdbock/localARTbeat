#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Arabic Translation Script - Mega Pass 3
Focus: Capture, Comments, Likes, Shares, Notifications, and Settings
"""

import json
import re

# Mega Pass 3: Capture, Comments, Likes, Shares, Notifications, Settings
AR_MEGA_TRANSLATIONS_3 = {
    # Capture & Artwork Upload
    "Capture": "التقاط",
    "Take Photo": "التقاط صورة",
    "Choose from Gallery": "اختيار من المعرض",
    "Upload Artwork": "تحميل عمل فني",
    "Upload Photo": "تحميل صورة",
    "Upload": "تحميل",
    "Uploading...": "جارٍ التحميل...",
    "Upload successful": "تم التحميل بنجاح",
    "Upload failed": "فشل التحميل",
    "Failed to upload": "فشل في التحميل",
    "Failed to upload image": "فشل في تحميل الصورة",
    "File too large": "الملف كبير جدًا",
    "File size limit: {size}": "حد حجم الملف: {size}",
    "Unsupported file type": "نوع ملف غير مدعوم",
    "Supported formats: {formats}": "التنسيقات المدعومة: {formats}",
    "Crop Image": "قص الصورة",
    "Rotate": "تدوير",
    "Flip": "قلب",
    "Adjust": "ضبط",
    "Brightness": "السطوع",
    "Contrast": "التباين",
    "Saturation": "التشبع",
    "Filters": "الفلاتر",
    "Apply Filter": "تطبيق الفلتر",
    "Remove Filter": "إزالة الفلتر",
    "Original": "أصلي",
    "Edit Photo": "تعديل الصورة",
    "Editing": "التعديل",
    "Save Changes": "حفظ التغييرات",
    "Discard Changes": "تجاهل التغييرات",
    "Changes saved": "تم حفظ التغييرات",
    "Changes discarded": "تم تجاهل التغييرات",
    "Add Title": "إضافة عنوان",
    "Add Description": "إضافة وصف",
    "Add Tags": "إضافة علامات",
    "Add Location": "إضافة موقع",
    "Tag People": "وضع علامة على الأشخاص",
    "Visibility": "الرؤية",
    "Public": "عام",
    "Private": "خاص",
    "Friends Only": "الأصدقاء فقط",
    "Post": "نشر",
    "Posting...": "جارٍ النشر...",
    "Posted successfully": "تم النشر بنجاح",
    "Failed to post": "فشل في النشر",
    "Draft saved": "تم حفظ المسودة",
    "Drafts": "المسودات",
    "Publish": "نشر",
    "Schedule": "جدولة",
    "Schedule Post": "جدولة المنشور",
    "Scheduled": "مجدول",
    "Scheduled for {date}": "مجدول لـ {date}",
    
    # Comments
    "Comment": "تعليق",
    "Comments": "التعليقات",
    "Add Comment": "إضافة تعليق",
    "Write a comment...": "اكتب تعليقًا...",
    "Post Comment": "نشر التعليق",
    "Comment posted": "تم نشر التعليق",
    "Failed to post comment": "فشل في نشر التعليق",
    "Failed to load comments": "فشل في تحميل التعليقات",
    "Edit Comment": "تعديل التعليق",
    "Delete Comment": "حذف التعليق",
    "Comment updated": "تم تحديث التعليق",
    "Comment deleted": "تم حذف التعليق",
    "Reply": "رد",
    "Replies": "الردود",
    "Reply to {name}": "الرد على {name}",
    "View Replies": "عرض الردود",
    "Hide Replies": "إخفاء الردود",
    "{count} replies": "{count} ردود",
    "Show more comments": "عرض المزيد من التعليقات",
    "No comments yet": "لا توجد تعليقات بعد",
    "Be the first to comment": "كن أول من يعلق",
    "Top Comments": "أهم التعليقات",
    "Newest First": "الأحدث أولاً",
    "Oldest First": "الأقدم أولاً",
    "Sort by": "الترتيب حسب",
    "Pin Comment": "تثبيت التعليق",
    "Unpin Comment": "إلغاء تثبيت التعليق",
    "Pinned Comment": "تعليق مثبت",
    "Report Comment": "الإبلاغ عن تعليق",
    "Comment reported": "تم الإبلاغ عن التعليق",
    "Mention": "ذكر",
    "Mentions": "الإشارات",
    
    # Likes & Reactions
    "Like": "إعجاب",
    "Likes": "الإعجابات",
    "Unlike": "إلغاء الإعجاب",
    "Liked": "تم الإعجاب",
    "{count} likes": "{count} إعجاب",
    "You and {count} others": "أنت و{count} آخرون",
    "Liked by {name} and {count} others": "أعجب به {name} و{count} آخرون",
    "Be the first to like": "كن أول من يعجب",
    "Love": "حب",
    "Wow": "واو",
    "Haha": "هاها",
    "Sad": "حزين",
    "Angry": "غاضب",
    "Reaction": "تفاعل",
    "Reactions": "التفاعلات",
    "{count} reactions": "{count} تفاعلات",
    "React": "تفاعل",
    
    # Shares & Bookmarks
    "Share": "مشاركة",
    "Shared": "تمت المشاركة",
    "Share to...": "مشاركة إلى...",
    "Share on {platform}": "مشاركة على {platform}",
    "Copy Link": "نسخ الرابط",
    "Link copied": "تم نسخ الرابط",
    "Link copied to clipboard": "تم نسخ الرابط إلى الحافظة",
    "Share via": "مشاركة عبر",
    "Share with Friends": "مشاركة مع الأصدقاء",
    "Shared with {count} people": "تمت المشاركة مع {count} شخص",
    "{count} shares": "{count} مشاركة",
    "Bookmark": "إشارة مرجعية",
    "Bookmarked": "تمت الإضافة للإشارات المرجعية",
    "Remove Bookmark": "إزالة الإشارة المرجعية",
    "Add to Bookmarks": "إضافة إلى الإشارات المرجعية",
    "Bookmarks": "الإشارات المرجعية",
    "Saved": "محفوظ",
    "Save": "حفظ",
    "Unsave": "إلغاء الحفظ",
    "Saved Items": "العناصر المحفوظة",
    "No saved items": "لا توجد عناصر محفوظة",
    "Save to Collection": "حفظ في المجموعة",
    "Create Collection": "إنشاء مجموعة",
    "Add to Collection": "إضافة إلى المجموعة",
    "Remove from Collection": "إزالة من المجموعة",
    "Collection Name": "اسم المجموعة",
    "New Collection": "مجموعة جديدة",
    
    # Notifications
    "Notifications": "الإشعارات",
    "Notification": "إشعار",
    "New Notification": "إشعار جديد",
    "{count} new notifications": "{count} إشعار جديد",
    "No notifications": "لا توجد إشعارات",
    "Mark all as read": "وضع علامة على الكل كمقروء",
    "Clear all": "مسح الكل",
    "Notification settings": "إعدادات الإشعارات",
    "Push Notifications": "الإشعارات الفورية",
    "Email Notifications": "إشعارات البريد الإلكتروني",
    "In-App Notifications": "الإشعارات داخل التطبيق",
    "Notification Preferences": "تفضيلات الإشعارات",
    "Notify me when": "أخبرني عندما",
    "Someone likes my post": "يعجب شخص ما بمنشوري",
    "Someone comments on my post": "يعلق شخص ما على منشوري",
    "Someone follows me": "يتابعني شخص ما",
    "Someone mentions me": "يذكرني شخص ما",
    "Someone shares my post": "يشارك شخص ما منشوري",
    "New message": "رسالة جديدة",
    "New follower": "متابع جديد",
    "{name} liked your post": "أعجب {name} بمنشورك",
    "{name} commented on your post": "علق {name} على منشورك",
    "{name} started following you": "بدأ {name} بمتابعتك",
    "{name} mentioned you": "ذكرك {name}",
    "{name} shared your post": "شارك {name} منشورك",
    "{name} sent you a message": "أرسل لك {name} رسالة",
    "Notification sent": "تم إرسال الإشعار",
    "Failed to send notification": "فشل في إرسال الإشعار",
    "Notification deleted": "تم حذف الإشعار",
    "Earlier": "سابقًا",
    "Yesterday": "أمس",
    "This Week": "هذا الأسبوع",
    "This Month": "هذا الشهر",
    "Older": "أقدم",
    
    # Settings
    "Settings": "الإعدادات",
    "Account Settings": "إعدادات الحساب",
    "Privacy Settings": "إعدادات الخصوصية",
    "Security Settings": "إعدادات الأمان",
    "Notification Settings": "إعدادات الإشعارات",
    "Display Settings": "إعدادات العرض",
    "Language Settings": "إعدادات اللغة",
    "Preferences": "التفضيلات",
    "General": "عام",
    "Advanced": "متقدم",
    "Privacy": "الخصوصية",
    "Security": "الأمان",
    "Theme": "السمة",
    "Light Mode": "الوضع الفاتح",
    "Dark Mode": "الوضع الداكن",
    "Auto": "تلقائي",
    "System Default": "افتراضي النظام",
    "Font Size": "حجم الخط",
    "Small": "صغير",
    "Medium": "متوسط",
    "Large": "كبير",
    "Extra Large": "كبير جدًا",
    "Language": "اللغة",
    "Change Language": "تغيير اللغة",
    "Region": "المنطقة",
    "Time Zone": "المنطقة الزمنية",
    "Date Format": "تنسيق التاريخ",
    "Time Format": "تنسيق الوقت",
    "Currency": "العملة",
    "Units": "الوحدات",
    "Metric": "متري",
    "Imperial": "إمبراطوري",
    "Accessibility": "إمكانية الوصول",
    "Screen Reader": "قارئ الشاشة",
    "High Contrast": "تباين عالي",
    "Reduce Motion": "تقليل الحركة",
    "Text to Speech": "تحويل النص إلى كلام",
    "Captions": "التسميات التوضيحية",
    "Sound Effects": "المؤثرات الصوتية",
    "Vibration": "الاهتزاز",
    "Haptic Feedback": "التغذية الراجعة اللمسية",
    "Auto-play Videos": "تشغيل الفيديوهات تلقائيًا",
    "Data Saver": "توفير البيانات",
    "Download over WiFi only": "التنزيل عبر WiFi فقط",
    "Storage": "التخزين",
    "Cache": "ذاكرة التخزين المؤقت",
    "Clear Cache": "مسح ذاكرة التخزين المؤقت",
    "Cache cleared": "تم مسح ذاكرة التخزين المؤقت",
    "Storage used: {size}": "التخزين المستخدم: {size}",
    "Free up space": "تحرير المساحة",
    "App Version": "إصدار التطبيق",
    "Version {version}": "الإصدار {version}",
    "Check for Updates": "التحقق من التحديثات",
    "Update Available": "يوجد تحديث",
    "Up to Date": "محدث",
    "Terms of Service": "شروط الخدمة",
    "Privacy Policy": "سياسة الخصوصية",
    "About": "حول",
    "Help": "مساعدة",
    "Help Center": "مركز المساعدة",
    "FAQ": "الأسئلة الشائعة",
    "Contact Us": "اتصل بنا",
    "Contact Support": "اتصل بالدعم",
    "Support": "الدعم",
    "Feedback": "التعليقات",
    "Send Feedback": "إرسال تعليقات",
    "Report a Problem": "الإبلاغ عن مشكلة",
    "Rate Us": "قيمنا",
    "Rate App": "تقييم التطبيق",
    "Legal": "قانوني",
    "Licenses": "التراخيص",
    "Open Source": "مفتوح المصدر",
    "Credits": "الاعتمادات",
}

def apply_translations():
    """Apply Arabic mega translations pass 3 to ar.json"""
    input_file = '/Users/kristybock/artbeat/assets/translations/ar.json'
    output_file = input_file
    
    print("\n" + "="*60)
    print("Arabic Translation - Mega Pass 3")
    print("Focus: Capture, Comments, Likes, Notifications, Settings")
    print("="*60 + "\n")
    
    # Load current translations
    with open(input_file, 'r', encoding='utf-8') as f:
        translations = json.load(f)
    
    # Track progress
    applied_count = 0
    
    # Apply translations
    for english_text, arabic_text in AR_MEGA_TRANSLATIONS_3.items():
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
    print("Arabic Translation - Mega Pass 3 Complete")
    print("="*60)
    print(f"Translations applied: {applied_count}")
    print(f"Remaining bracketed entries: {remaining}")
    print(f"Overall progress: {completed}/{total} ({percentage:.1f}%)")
    print(f"File saved: {output_file}")
    print("="*60 + "\n")

if __name__ == "__main__":
    apply_translations()
