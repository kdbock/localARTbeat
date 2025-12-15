#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Arabic Translation Script - Mega Pass 8
Focus: Error Messages, Event Management, and User Actions
"""

import json

# Mega Pass 8: Error messages, Events, and Actions
AR_MEGA_TRANSLATIONS_8 = {
    # Input & Entry
    "Enter a valid email address": "أدخل عنوان بريد إلكتروني صحيح",
    "Enter event title": "أدخل عنوان الحدث",
    "Enter search name": "أدخل اسم البحث",
    "Enter the essential details of your artwork": "أدخل التفاصيل الأساسية لعملك الفني",
    "Enter your email to receive a password reset link": "أدخل بريدك الإلكتروني لتلقي رابط إعادة تعيين كلمة المرور",
    "Equipment Used (Optional)": "المعدات المستخدمة (اختياري)",
    
    # Error Messages - Walk & Navigation
    "Error abandoning walk: $e": "خطأ في إلغاء الجولة: $e",
    "Error advancing navigation: $e": "خطأ في التنقل المتقدم: $e",
    "Error completing art walk: ${e.toString()}": "خطأ في إكمال الجولة الفنية: ${e.toString()}",
    "Error completing walk: $e": "خطأ في إكمال الجولة: $e",
    "Error deleting art walk: $e": "خطأ في حذف الجولة الفنية: $e",
    "Error deleting walk: $e": "خطأ في حذف الجولة: $e",
    "Error loading art walk: $e": "خطأ في تحميل الجولة الفنية: $e",
    "Error loading art walks: $e": "خطأ في تحميل الجولات الفنية: $e",
    "Error marking as visited: $e": "خطأ في وضع علامة كمزار: $e",
    "Error pausing walk: $e": "خطأ في إيقاف الجولة مؤقتًا: $e",
    "Error resuming walk: $e": "خطأ في استئناف الجولة: $e",
    "Error starting art walk: $e": "خطأ في بدء الجولة الفنية: $e",
    "Error stopping navigation: $e": "خطأ في إيقاف التنقل: $e",
    "Error unsaving walk: $e": "خطأ في إلغاء حفظ الجولة: $e",
    "Error updating art walk: $e": "خطأ في تحديث الجولة الفنية: $e",
    
    # Error Messages - Artwork & Content
    "Error creating artist profile: $e": "خطأ في إنشاء ملف الفنان: $e",
    "Error deleting artwork: {error}": "خطأ في حذف العمل الفني: {error}",
    "Error loading art pieces: $e": "خطأ في تحميل القطع الفنية: $e",
    "Error loading artwork: {error}": "خطأ في تحميل العمل الفني: {error}",
    "Error loading artists: $e": "خطأ في تحميل الفنانين: $e",
    "Error loading artist profile: $e": "خطأ في تحميل ملف الفنان: $e",
    "Error loading featured artists: $e": "خطأ في تحميل الفنانين المميزين: $e",
    "Error loading verified artists: $e": "خطأ في تحميل الفنانين الموثقين: $e",
    "Error loading nearby art: $e": "خطأ في تحميل الأعمال الفنية القريبة: $e",
    "Error updating artwork: {error}": "خطأ في تحديث العمل الفني: {error}",
    "Failed to delete artwork: $e": "فشل في حذف العمل الفني: $e",
    "Failed to delete artwork: {error}": "فشل في حذف العمل الفني: {error}",
    "Failed to load artworks": "فشل في تحميل الأعمال الفنية",
    "Failed to load artists": "فشل في تحميل الفنانين",
    
    # Error Messages - Capture
    "Error capturing selfie: $e": "خطأ في التقاط صورة السيلفي: $e",
    "Error loading captures: $e": "خطأ في تحميل اللقطات: $e",
    "Failed to approve capture": "فشل في الموافقة على اللقطة",
    "Failed to delete capture": "فشل في حذف اللقطة",
    "Failed to delete capture: $e": "فشل في حذف اللقطة: $e",
    "Failed to reject capture": "فشل في رفض اللقطة",
    
    # Error Messages - Chat & Messaging
    "Error loading chat": "خطأ في تحميل المحادثة",
    "Error loading chats": "خطأ في تحميل المحادثات",
    "Failed to archive chat: $e": "فشل في أرشفة المحادثة: $e",
    "Failed to clear chat: $e": "فشل في مسح المحادثة: $e",
    "Failed to delete chat: $e": "فشل في حذف المحادثة: $e",
    "Failed to restore chat: $e": "فشل في استعادة المحادثة: $e",
    
    # Error Messages - Users & Blocking
    "Error loading blocked users: $e": "خطأ في تحميل المستخدمين المحظورين: $e",
    "Error loading blocked users: {error}": "خطأ في تحميل المستخدمين المحظورين: {error}",
    "Error unblocking user: $e": "خطأ في إلغاء حظر المستخدم: $e",
    "Failed to block user": "فشل في حظر المستخدم",
    "Failed to block user: $e": "فشل في حظر المستخدم: $e",
    "Failed to block user: {error}": "فشل في حظر المستخدم: {error}",
    "Failed to report user: $e": "فشل في الإبلاغ عن المستخدم: $e",
    
    # Error Messages - Profile & Data
    "Error loading profile: $e": "خطأ في تحميل الملف الشخصي: $e",
    "Error loading profile: {error}": "خطأ في تحميل الملف الشخصي: {error}",
    "Error loading data: $e": "خطأ في تحميل البيانات: $e",
    "Error loading feed: $e": "خطأ في تحميل الموجز: $e",
    "Error loading followers: {error}": "خطأ في تحميل المتابعين: {error}",
    "Error loading participants: $e": "خطأ في تحميل المشاركين: $e",
    "Error saving profile: $e": "خطأ في حفظ الملف الشخصي: $e",
    "Error updating follow status: {error}": "خطأ في تحديث حالة المتابعة: {error}",
    
    # Error Messages - Analytics & Reports
    "Error clearing reports: $e": "خطأ في مسح التقارير: $e",
    "Error exporting analytics": "خطأ في تصدير التحليلات",
    "Error loading analytics": "خطأ في تحميل التحليلات",
    "Error loading analytics data: ${e.toString()}": "خطأ في تحميل بيانات التحليلات: ${e.toString()}",
    "Error loading analytics: $e": "خطأ في تحميل التحليلات: $e",
    "Failed to clear reports": "فشل في مسح التقارير",
    "Failed to clear review: $e": "فشل في مسح المراجعة: $e",
    
    # Error Messages - Events
    "Error loading events": "خطأ في تحميل الأحداث",
    "Error loading moderation data": "خطأ في تحميل بيانات الإشراف",
    "Failed to load event": "فشل في تحميل الحدث",
    "Failed to load events: ": "فشل في تحميل الأحداث: ",
    
    # Error Messages - Location & Search
    "Error getting location: ${e.toString()}": "خطأ في الحصول على الموقع: ${e.toString()}",
    "Failed to get location: $e": "فشل في الحصول على الموقع: $e",
    "Error performing search": "خطأ في تنفيذ البحث",
    "Error saving search": "خطأ في حفظ البحث",
    "Error searching artists: ${e.toString()}": "خطأ في البحث عن الفنانين: ${e.toString()}",
    
    # Error Messages - File Upload & Processing
    "Error picking image: $e": "خطأ في اختيار الصورة: $e",
    "Error picking image: {error}": "خطأ في اختيار الصورة: {error}",
    "Error processing audio file: $0": "خطأ في معالجة الملف الصوتي: $0",
    "Error processing file: $0": "خطأ في معالجة الملف: $0",
    "Error processing video file: $0": "خطأ في معالجة ملف الفيديو: $0",
    "Error selecting audio file: $0": "خطأ في اختيار الملف الصوتي: $0",
    "Error selecting audio: $0": "خطأ في اختيار الصوت: $0",
    "Error selecting file: $0": "خطأ في اختيار الملف: $0",
    "Error selecting image: $0": "خطأ في اختيار الصورة: $0",
    "Error selecting image: ${e.toString()}": "خطأ في اختيار الصورة: ${e.toString()}",
    "Error selecting thumbnail: $0": "خطأ في اختيار الصورة المصغرة: $0",
    "Error selecting video file: $0": "خطأ في اختيار ملف الفيديو: $0",
    "Error uploading audio content: $0": "خطأ في تحميل المحتوى الصوتي: $0",
    "Error uploading content: $0": "خطأ في تحميل المحتوى: $0",
    "Error uploading video content: $0": "خطأ في تحميل محتوى الفيديو: $0",
    
    # Error Messages - General & Misc
    "Error during {{operation}}: {{error}}": "خطأ أثناء {{operation}}: {{error}}",
    "Error sharing: ${e.toString()}": "خطأ في المشاركة: ${e.toString()}",
    "Error submitting review: $e": "خطأ في إرسال المراجعة: $e",
    "Error with previous step: $e": "خطأ في الخطوة السابقة: $e",
    "Error: ": "خطأ: ",
    "Error: $_error": "خطأ: $_error",
    "Error: ${e.toString()}": "خطأ: ${e.toString()}",
    "Error: ${snapshot.error}": "خطأ: ${snapshot.error}",
    "Error: {error}": "خطأ: {error}",
    
    # Failed Actions
    "Failed to cancel invitation: $e": "فشل في إلغاء الدعوة: $e",
    "Failed to change password": "فشل في تغيير كلمة المرور",
    "Failed to check migration status: ${error}": "فشل في التحقق من حالة الترحيل: ${error}",
    "Failed to create coupon: {error}": "فشل في إنشاء القسيمة: {error}",
    "Failed to create group": "فشل في إنشاء المجموعة",
    "Failed to create group: ${e.toString()}": "فشل في إنشاء المجموعة: ${e.toString()}",
    "Failed to delete content: $e": "فشل في حذف المحتوى: $e",
    "Failed to download media": "فشل في تنزيل الوسائط",
    "Failed to leave group": "فشل في مغادرة المجموعة",
    "Failed to load contacts": "فشل في تحميل جهات الاتصال",
    "Failed to load earnings data": "فشل في تحميل بيانات الأرباح",
    "Failed to load galleries": "فشل في تحميل المعارض",
    "Failed to load migration status": "فشل في تحميل حالة الترحيل",
    "Failed to load privacy settings": "فشل في تحميل إعدادات الخصوصية",
    "Failed to post achievement: $e": "فشل في نشر الإنجاز: $e",
    "Failed to post ad: $e": "فشل في نشر الإعلان: $e",
    "Failed to remove artist from gallery: $e": "فشل في إزالة الفنان من المعرض: $e",
    "Failed to request data deletion": "فشل في طلب حذف البيانات",
    "Failed to request data download": "فشل في طلب تنزيل البيانات",
    "Failed to resend invitation: $e": "فشل في إعادة إرسال الدعوة: $e",
    
    # Event Management
    "Event Banner": "لافتة الحدث",
    "Event Images": "صور الحدث",
    "Event Management": "إدارة الأحداث",
    "Event Moderation": "إشراف الأحداث",
    "Event Not Found": "الحدث غير موجود",
    "Event Post": "منشور الحدث",
    "Event Title": "عنوان الحدث",
    "Event created successfully!": "تم إنشاء الحدث بنجاح!",
    "Event not found or no longer available": "الحدث غير موجود أو لم يعد متاحًا",
    "Event saved successfully": "تم حفظ الحدث بنجاح",
    "Event updated successfully!": "تم تحديث الحدث بنجاح!",
    
    # Exploration & Discovery
    "Experimental": "تجريبي",
    "Expired Ads ({count})": "الإعلانات المنتهية ({count})",
    "Explore Art Walks": "استكشف الجولات الفنية",
    "Explore More": "استكشف المزيد",
    "Explore art collections and galleries": "استكشف مجموعات الفن والمعارض",
    "Explore art nearby": "استكشف الأعمال الفنية القريبة",
    "Explore beautiful artworks from Local ARTbeat talented artists around you": "استكشف الأعمال الفنية الجميلة من الفنانين الموهوبين المحليين من حولك",
    "Explore nearby": "استكشف القريب",
    "Explore similar audio content": "استكشف محتوى صوتي مشابه",
    
    # Export & Analytics
    "Export Analytics": "تصدير التحليلات",
    "Export Report": "تصدير التقرير",
    "Extracting audio metadata...": "جارٍ استخراج البيانات الوصفية الصوتية...",
    
    # Time & Progress
    "Estimated time remaining: {time}": "الوقت المتبقي المقدر: {time}",
    
    # Security & Login
    "Factory Reset": "إعادة تعيين المصنع",
    "Factory reset completed": "اكتملت إعادة تعيين المصنع",
    "Failed Logins": "عمليات تسجيل الدخول الفاشلة",
    "Failed login attempt blocked": "تم حظر محاولة تسجيل الدخول الفاشلة",
}

def apply_translations():
    """Apply Arabic mega translations pass 8 to ar.json"""
    input_file = '/Users/kristybock/artbeat/assets/translations/ar.json'
    output_file = input_file
    
    print("\n" + "="*60)
    print("Arabic Translation - Mega Pass 8")
    print("Focus: Error Messages, Events, User Actions")
    print("="*60 + "\n")
    
    # Load current translations
    with open(input_file, 'r', encoding='utf-8') as f:
        translations = json.load(f)
    
    # Track progress
    applied_count = 0
    
    # Apply translations
    for english_text, arabic_text in AR_MEGA_TRANSLATIONS_8.items():
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
    print("Arabic Translation - Mega Pass 8 Complete")
    print("="*60)
    print(f"Translations applied: {applied_count}")
    print(f"Remaining bracketed entries: {remaining}")
    print(f"Overall progress: {completed}/{total} ({percentage:.1f}%)")
    print(f"File saved: {output_file}")
    print("="*60 + "\n")

if __name__ == "__main__":
    apply_translations()
