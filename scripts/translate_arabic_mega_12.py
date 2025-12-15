#!/usr/bin/env python3
"""
Arabic Translation - Mega Pass 12
Target: Delete/Discover/Display/Duration/Edit/Email/Enable/Enhanced sections
Coverage: ~300 translations
"""

import json

# Load current translations
with open('assets/translations/ar.json', 'r', encoding='utf-8') as f:
    translations = json.load(f)

# Mega Pass 12 Translation Dictionary (300 entries)
MEGA_12 = {
    # Delete & Deleting
    "Delete Account": "حذف الحساب",
    "Delete Ad": "حذف الإعلان",
    "Delete All": "حذف الكل",
    "Delete Art Walk": "حذف الجولة الفنية",
    "Delete Artwork": "حذف العمل الفني",
    "Delete Chat": "حذف المحادثة",
    "Delete Conversation": "حذف المحادثة",
    "Delete Coupon": "حذف القسيمة",
    "Delete Event": "حذف الحدث",
    "Delete Message": "حذف الرسالة",
    "Delete Profile": "حذف الملف الشخصي",
    "Delete Walk": "حذف الجولة",
    "Delete Your Account?": "حذف حسابك؟",
    "Delete from both users": "حذف من كلا المستخدمين",
    "Delete just for me": "حذف لي فقط",
    "Delete this message?": "حذف هذه الرسالة؟",
    "Deleted": "محذوف",
    "Deleting message...": "جارٍ حذف الرسالة...",
    "Deleting...": "جارٍ الحذف...",
    
    # Discover & Discovery
    "Discover": "اكتشف",
    "Discover Art": "اكتشف الفن",
    "Discover Art Walks": "اكتشف الجولات الفنية",
    "Discover Artists": "اكتشف الفنانين",
    "Discover Local Art": "اكتشف الفن المحلي",
    "Discover and participate in art walks": "اكتشف وشارك في الجولات الفنية",
    "Discover art events and spaces near you": "اكتشف الأحداث والمساحات الفنية بالقرب منك",
    "Discover artists and their work": "اكتشف الفنانين وأعمالهم",
    "Discover local art": "اكتشف الفن المحلي",
    "Discover local art near you": "اكتشف الفن المحلي بالقرب منك",
    "Discovering...": "جارٍ الاكتشاف...",
    "Discovery": "الاكتشاف",
    
    # Display & Displayed
    "Display Name": "اسم العرض",
    "Display Settings": "إعدادات العرض",
    "Display ads in a carousel": "عرض الإعلانات في دوّار",
    "Display featured art": "عرض الفن المميز",
    "Display images": "عرض الصور",
    "Displayed publicly on your profile": "معروض علنًا في ملفك الشخصي",
    
    # Distance & Duration
    "Distance": "المسافة",
    "Distance from your location": "المسافة من موقعك",
    "Distance: ${distance.toStringAsFixed(1)} km": "المسافة: ${distance.toStringAsFixed(1)} كم",
    "Distance: {distance} km": "المسافة: {distance} كم",
    "Duration": "المدة",
    "Duration (minutes)": "المدة (بالدقائق)",
    "Duration: ${duration} minutes": "المدة: ${duration} دقيقة",
    "Duration: {duration}": "المدة: {duration}",
    
    # Edit & Editing
    "EDIT": "تعديل",
    "Edit Ad": "تعديل الإعلان",
    "Edit Art Walk": "تعديل الجولة الفنية",
    "Edit Artist Profile": "تعديل ملف الفنان",
    "Edit Artwork": "تعديل العمل الفني",
    "Edit Cover Image": "تعديل صورة الغلاف",
    "Edit Coupon": "تعديل القسيمة",
    "Edit Details": "تعديل التفاصيل",
    "Edit Event": "تعديل الحدث",
    "Edit Info": "تعديل المعلومات",
    "Edit Location": "تعديل الموقع",
    "Edit Message": "تعديل الرسالة",
    "Edit Name": "تعديل الاسم",
    "Edit Personal Info": "تعديل المعلومات الشخصية",
    "Edit Profile": "تعديل الملف الشخصي",
    "Edit Profile Picture": "تعديل صورة الملف الشخصي",
    "Edit Route": "تعديل المسار",
    "Edit Settings": "تعديل الإعدادات",
    "Edit Text": "تعديل النص",
    "Edit Walk": "تعديل الجولة",
    "Edit Your Profile": "تعديل ملفك الشخصي",
    "Edited": "معدّل",
    "Editing...": "جارٍ التعديل...",
    
    # Email & Email Notifications
    "EMAIL": "البريد الإلكتروني",
    "Email": "البريد الإلكتروني",
    "Email Address": "عنوان البريد الإلكتروني",
    "Email Notifications": "إشعارات البريد الإلكتروني",
    "Email Settings": "إعدادات البريد الإلكتروني",
    "Email Verification": "التحقق من البريد الإلكتروني",
    "Email address": "عنوان البريد الإلكتروني",
    "Email cannot be empty": "لا يمكن أن يكون البريد الإلكتروني فارغًا",
    "Email is required": "البريد الإلكتروني مطلوب",
    "Email not verified": "البريد الإلكتروني غير محقق",
    "Email sent successfully": "تم إرسال البريد الإلكتروني بنجاح",
    "Email verification sent": "تم إرسال التحقق من البريد الإلكتروني",
    
    # Enable & Enabled
    "Enable": "تفعيل",
    "Enable Audio": "تفعيل الصوت",
    "Enable Auto-play": "تفعيل التشغيل التلقائي",
    "Enable Background Playback": "تفعيل التشغيل في الخلفية",
    "Enable Chat": "تفعيل المحادثة",
    "Enable Dark Mode": "تفعيل الوضع الداكن",
    "Enable Location": "تفعيل الموقع",
    "Enable Notifications": "تفعيل الإشعارات",
    "Enable Push Notifications": "تفعيل الإشعارات الفورية",
    "Enable Sound": "تفعيل الصوت",
    "Enable push notifications": "تفعيل الإشعارات الفورية",
    "Enabled": "مفعّل",
    
    # Enhanced & Enhancement
    "Enhanced Security": "الأمان المحسّن",
    "Enhanced User Experience": "تجربة المستخدم المحسّنة",
    "Enhancement": "تحسين",
    
    # Enter & Entry
    "Enter": "إدخال",
    "Enter Address": "إدخال العنوان",
    "Enter Amount": "إدخال المبلغ",
    "Enter Bio": "إدخال السيرة الذاتية",
    "Enter Caption": "إدخال التعليق",
    "Enter Code": "إدخال الرمز",
    "Enter Description": "إدخال الوصف",
    "Enter Details": "إدخال التفاصيل",
    "Enter Email": "إدخال البريد الإلكتروني",
    "Enter Location": "إدخال الموقع",
    "Enter Message": "إدخال الرسالة",
    "Enter Name": "إدخال الاسم",
    "Enter Password": "إدخال كلمة المرور",
    "Enter Phone": "إدخال الهاتف",
    "Enter Price": "إدخال السعر",
    "Enter Search": "إدخال البحث",
    "Enter Text": "إدخال النص",
    "Enter Title": "إدخال العنوان",
    "Enter URL": "إدخال عنوان URL",
    "Enter Username": "إدخال اسم المستخدم",
    "Enter a caption": "إدخال تعليق",
    "Enter a description": "إدخال وصف",
    "Enter a location": "إدخال موقع",
    "Enter a message": "إدخال رسالة",
    "Enter a name": "إدخال اسم",
    "Enter a price": "إدخال سعر",
    "Enter a title": "إدخال عنوان",
    "Enter amount": "إدخال المبلغ",
    "Enter bio": "إدخال السيرة الذاتية",
    "Enter caption": "إدخال التعليق",
    "Enter code": "إدخال الرمز",
    "Enter description": "إدخال الوصف",
    "Enter details": "إدخال التفاصيل",
    "Enter email": "إدخال البريد الإلكتروني",
    "Enter email address": "إدخال عنوان البريد الإلكتروني",
    "Enter location": "إدخال الموقع",
    "Enter message": "إدخال الرسالة",
    "Enter name": "إدخال الاسم",
    "Enter password": "إدخال كلمة المرور",
    "Enter phone number": "إدخال رقم الهاتف",
    "Enter price": "إدخال السعر",
    "Enter search query": "إدخال استعلام البحث",
    "Enter search term": "إدخال مصطلح البحث",
    "Enter text": "إدخال النص",
    "Enter title": "إدخال العنوان",
    "Enter username": "إدخال اسم المستخدم",
    "Enter valid email": "إدخال بريد إلكتروني صالح",
    "Enter your bio": "إدخال سيرتك الذاتية",
    "Enter your email": "إدخال بريدك الإلكتروني",
    "Enter your email address": "إدخال عنوان بريدك الإلكتروني",
    "Enter your message": "إدخال رسالتك",
    "Enter your name": "إدخال اسمك",
    "Enter your password": "إدخال كلمة المرور الخاصة بك",
    "Enter your phone number": "إدخال رقم هاتفك",
    "Enter your username": "إدخال اسم المستخدم الخاص بك",
    
    # Error & Error Messages
    "ERROR": "خطأ",
    "Error": "خطأ",
    "Error Loading": "خطأ في التحميل",
    "Error Loading Data": "خطأ في تحميل البيانات",
    "Error Occurred": "حدث خطأ",
    "Error Saving": "خطأ في الحفظ",
    "Error creating account": "خطأ في إنشاء الحساب",
    "Error creating ad": "خطأ في إنشاء الإعلان",
    "Error creating art walk": "خطأ في إنشاء الجولة الفنية",
    "Error creating artwork": "خطأ في إنشاء العمل الفني",
    "Error creating coupon": "خطأ في إنشاء القسيمة",
    "Error creating event": "خطأ في إنشاء الحدث",
    "Error creating profile": "خطأ في إنشاء الملف الشخصي",
    "Error deleting": "خطأ في الحذف",
    "Error deleting account": "خطأ في حذف الحساب",
    "Error deleting ad": "خطأ في حذف الإعلان",
    "Error deleting art walk": "خطأ في حذف الجولة الفنية",
    "Error deleting artwork": "خطأ في حذف العمل الفني",
    "Error deleting capture": "خطأ في حذف اللقطة",
    "Error deleting chat": "خطأ في حذف المحادثة",
    "Error deleting comment": "خطأ في حذف التعليق",
    "Error deleting coupon": "خطأ في حذف القسيمة",
    "Error deleting event": "خطأ في حذف الحدث",
    "Error deleting message": "خطأ في حذف الرسالة",
    "Error loading": "خطأ في التحميل",
    "Error loading art walk": "خطأ في تحميل الجولة الفنية",
    "Error loading art walks": "خطأ في تحميل الجولات الفنية",
    "Error loading artist": "خطأ في تحميل الفنان",
    "Error loading artists": "خطأ في تحميل الفنانين",
    "Error loading artwork": "خطأ في تحميل العمل الفني",
    "Error loading artworks": "خطأ في تحميل الأعمال الفنية",
    "Error loading captures": "خطأ في تحميل اللقطات",
    "Error loading chat": "خطأ في تحميل المحادثة",
    "Error loading chats": "خطأ في تحميل المحادثات",
    "Error loading comments": "خطأ في تحميل التعليقات",
    "Error loading data": "خطأ في تحميل البيانات",
    "Error loading event": "خطأ في تحميل الحدث",
    "Error loading events": "خطأ في تحميل الأحداث",
    "Error loading feed": "خطأ في تحميل الخلاصة",
    "Error loading followers": "خطأ في تحميل المتابعين",
    "Error loading following": "خطأ في تحميل المتابَعين",
    "Error loading gallery": "خطأ في تحميل المعرض",
    "Error loading image": "خطأ في تحميل الصورة",
    "Error loading likes": "خطأ في تحميل الإعجابات",
    "Error loading messages": "خطأ في تحميل الرسائل",
    "Error loading notifications": "خطأ في تحميل الإشعارات",
    "Error loading posts": "خطأ في تحميل المنشورات",
    "Error loading profile": "خطأ في تحميل الملف الشخصي",
    "Error loading reports": "خطأ في تحميل التقارير",
    "Error loading reviews": "خطأ في تحميل المراجعات",
    "Error loading search results": "خطأ في تحميل نتائج البحث",
    "Error loading settings": "خطأ في تحميل الإعدادات",
    "Error loading user": "خطأ في تحميل المستخدم",
    "Error loading users": "خطأ في تحميل المستخدمين",
    "Error loading video": "خطأ في تحميل الفيديو",
    "Error occurred": "حدث خطأ",
    "Error refreshing": "خطأ في التحديث",
    "Error saving": "خطأ في الحفظ",
    "Error saving data": "خطأ في حفظ البيانات",
    "Error saving profile": "خطأ في حفظ الملف الشخصي",
    "Error saving settings": "خطأ في حفظ الإعدادات",
    "Error sending": "خطأ في الإرسال",
    "Error sending message": "خطأ في إرسال الرسالة",
    "Error updating": "خطأ في التحديث",
    "Error updating ad": "خطأ في تحديث الإعلان",
    "Error updating art walk": "خطأ في تحديث الجولة الفنية",
    "Error updating artwork": "خطأ في تحديث العمل الفني",
    "Error updating coupon": "خطأ في تحديث القسيمة",
    "Error updating event": "خطأ في تحديث الحدث",
    "Error updating profile": "خطأ في تحديث الملف الشخصي",
    "Error updating settings": "خطأ في تحديث الإعدادات",
    "Error uploading": "خطأ في التحميل",
    "Error uploading audio": "خطأ في تحميل الصوت",
    "Error uploading file": "خطأ في تحميل الملف",
    "Error uploading image": "خطأ في تحميل الصورة",
    "Error uploading video": "خطأ في تحميل الفيديو",
    
    # Event & Events
    "Event": "حدث",
    "Event Category": "فئة الحدث",
    "Event Created": "تم إنشاء الحدث",
    "Event Deleted": "تم حذف الحدث",
    "Event Description": "وصف الحدث",
    "Event Details": "تفاصيل الحدث",
    "Event End": "نهاية الحدث",
    "Event Information": "معلومات الحدث",
    "Event Location": "موقع الحدث",
    "Event Name": "اسم الحدث",
    "Event Not Found": "الحدث غير موجود",
    "Event Settings": "إعدادات الحدث",
    "Event Start": "بداية الحدث",
    "Event Time": "وقت الحدث",
    "Event Title": "عنوان الحدث",
    "Event Type": "نوع الحدث",
    "Event Updated": "تم تحديث الحدث",
    "Event created successfully": "تم إنشاء الحدث بنجاح",
    "Event created successfully!": "تم إنشاء الحدث بنجاح!",
    "Event deleted successfully": "تم حذف الحدث بنجاح",
    "Event details": "تفاصيل الحدث",
    "Event not found": "الحدث غير موجود",
    "Event updated successfully": "تم تحديث الحدث بنجاح",
    "Event updated successfully!": "تم تحديث الحدث بنجاح!",
}

# Apply translations
applied_count = 0
for english_text, arabic_text in MEGA_12.items():
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
print("Arabic Translation - MEGA PASS 12")
print("="*60)
print(f"Translations applied: {applied_count}")
print(f"Remaining bracketed entries: {remaining}")
print(f"Overall progress: {completed}/{total} ({percentage:.1f}%)")
print(f"File saved: assets/translations/ar.json")
print("="*60)
