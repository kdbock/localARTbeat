#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Arabic Translation Script - Mega Pass 4
Focus: Errors, Validation, Forms, Authentication, and User Actions
"""

import json
import re

# Mega Pass 4: Errors, Validation, Forms, Authentication, User Actions
AR_MEGA_TRANSLATIONS_4 = {
    # Error Messages & Validation
    "Error": "خطأ",
    "Error loading data": "خطأ في تحميل البيانات",
    "Error loading user data": "خطأ في تحميل بيانات المستخدم",
    "Error loading profile": "خطأ في تحميل الملف الشخصي",
    "Error uploading file": "خطأ في تحميل الملف",
    "Error saving changes": "خطأ في حفظ التغييرات",
    "Error updating profile": "خطأ في تحديث الملف الشخصي",
    "Error creating account": "خطأ في إنشاء الحساب",
    "Error signing in": "خطأ في تسجيل الدخول",
    "Error processing request": "خطأ في معالجة الطلب",
    "Error processing payment": "خطأ في معالجة الدفع",
    "An error occurred": "حدث خطأ",
    "Something went wrong": "حدث خطأ ما",
    "Please try again": "يرجى المحاولة مرة أخرى",
    "Try again": "حاول مرة أخرى",
    "Failed": "فشل",
    "Success": "نجح",
    "Warning": "تحذير",
    "Info": "معلومات",
    "Required": "مطلوب",
    "Optional": "اختياري",
    "This field is required": "هذا الحقل مطلوب",
    "Please enter a value": "يرجى إدخال قيمة",
    "Please enter a valid value": "يرجى إدخال قيمة صحيحة",
    "Invalid": "غير صحيح",
    "Invalid input": "إدخال غير صحيح",
    "Invalid email": "بريد إلكتروني غير صحيح",
    "Invalid email address": "عنوان بريد إلكتروني غير صحيح",
    "Please enter a valid email address": "يرجى إدخال عنوان بريد إلكتروني صحيح",
    "Invalid password": "كلمة مرور غير صحيحة",
    "Password must be at least {length} characters": "يجب أن تتكون كلمة المرور من {length} أحرف على الأقل",
    "Password too short": "كلمة المرور قصيرة جدًا",
    "Password too weak": "كلمة المرور ضعيفة جدًا",
    "Passwords do not match": "كلمات المرور غير متطابقة",
    "Please confirm your password": "يرجى تأكيد كلمة المرور",
    "Invalid phone number": "رقم هاتف غير صحيح",
    "Invalid URL": "رابط غير صحيح",
    "Invalid date": "تاريخ غير صحيح",
    "Invalid format": "تنسيق غير صحيح",
    "Too short": "قصير جدًا",
    "Too long": "طويل جدًا",
    "Minimum {min} characters": "الحد الأدنى {min} أحرف",
    "Maximum {max} characters": "الحد الأقصى {max} أحرف",
    "Must be between {min} and {max} characters": "يجب أن يكون بين {min} و{max} حرفًا",
    "Must contain at least one number": "يجب أن يحتوي على رقم واحد على الأقل",
    "Must contain at least one letter": "يجب أن يحتوي على حرف واحد على الأقل",
    "Must contain at least one special character": "يجب أن يحتوي على حرف خاص واحد على الأقل",
    "Cannot be empty": "لا يمكن أن يكون فارغًا",
    "Already exists": "موجود بالفعل",
    "Email already in use": "البريد الإلكتروني مستخدم بالفعل",
    "Username already taken": "اسم المستخدم مأخوذ بالفعل",
    "Not found": "غير موجود",
    "User not found": "المستخدم غير موجود",
    "Page not found": "الصفحة غير موجودة",
    "Content not found": "المحتوى غير موجود",
    "Network error": "خطأ في الشبكة",
    "Connection failed": "فشل الاتصال",
    "No internet connection": "لا يوجد اتصال بالإنترنت",
    "Please check your internet connection": "يرجى التحقق من اتصالك بالإنترنت",
    "Server error": "خطأ في الخادم",
    "Service unavailable": "الخدمة غير متاحة",
    "Maintenance mode": "وضع الصيانة",
    "Timeout": "انتهت المهلة",
    "Request timeout": "انتهت مهلة الطلب",
    "Session expired": "انتهت صلاحية الجلسة",
    "Please login again": "يرجى تسجيل الدخول مرة أخرى",
    "Unauthorized": "غير مصرح",
    "Access denied": "تم رفض الوصول",
    "Forbidden": "ممنوع",
    "Permission denied": "تم رفض الإذن",
    "You don't have permission": "ليس لديك إذن",
    "Insufficient permissions": "أذونات غير كافية",
    
    # Form Fields & Actions
    "Username": "اسم المستخدم",
    "Email": "البريد الإلكتروني",
    "Email Address": "عنوان البريد الإلكتروني",
    "Password": "كلمة المرور",
    "Current Password": "كلمة المرور الحالية",
    "New Password": "كلمة المرور الجديدة",
    "Confirm Password": "تأكيد كلمة المرور",
    "Confirm New Password": "تأكيد كلمة المرور الجديدة",
    "First Name": "الاسم الأول",
    "Last Name": "اسم العائلة",
    "Full Name": "الاسم الكامل",
    "Display Name": "الاسم المعروض",
    "Bio": "السيرة الذاتية",
    "Phone": "الهاتف",
    "Phone Number": "رقم الهاتف",
    "Address": "العنوان",
    "Street Address": "عنوان الشارع",
    "City": "المدينة",
    "State": "الولاية",
    "Province": "المقاطعة",
    "Country": "البلد",
    "Postal Code": "الرمز البريدي",
    "ZIP Code": "الرمز البريدي",
    "Website": "الموقع الإلكتروني",
    "Title": "العنوان",
    "Description": "الوصف",
    "Tags": "العلامات",
    "Category": "الفئة",
    "Price": "السعر",
    "Quantity": "الكمية",
    "Date": "التاريخ",
    "Time": "الوقت",
    "Start Time": "وقت البدء",
    "End Time": "وقت الانتهاء",
    "Duration": "المدة",
    "Status": "الحالة",
    "Type": "النوع",
    "Notes": "ملاحظات",
    "Message": "رسالة",
    "Subject": "الموضوع",
    "Reason": "السبب",
    "Details": "التفاصيل",
    "Additional Information": "معلومات إضافية",
    "Search": "البحث",
    "Search...": "البحث...",
    "Filter": "تصفية",
    "Sort": "ترتيب",
    "Select": "تحديد",
    "Choose": "اختيار",
    "Browse": "تصفح",
    "Upload": "تحميل",
    "Download": "تنزيل",
    "Import": "استيراد",
    "Export": "تصدير",
    "Print": "طباعة",
    "Refresh": "تحديث",
    "Reload": "إعادة تحميل",
    "Clear": "مسح",
    "Reset": "إعادة تعيين",
    "Apply": "تطبيق",
    "Submit": "إرسال",
    "Continue": "متابعة",
    "Next": "التالي",
    "Previous": "السابق",
    "Back": "رجوع",
    "Close": "إغلاق",
    "Done": "تم",
    "Finish": "إنهاء",
    "Complete": "إكمال",
    "Skip": "تخطي",
    "Retry": "إعادة المحاولة",
    
    # Authentication & Account
    "Sign In": "تسجيل الدخول",
    "Sign Out": "تسجيل الخروج",
    "Log In": "تسجيل الدخول",
    "Log Out": "تسجيل الخروج",
    "Sign Up": "التسجيل",
    "Register": "التسجيل",
    "Create Account": "إنشاء حساب",
    "Forgot Password?": "نسيت كلمة المرور؟",
    "Forgot Password": "نسيت كلمة المرور",
    "Reset Password": "إعادة تعيين كلمة المرور",
    "Change Password": "تغيير كلمة المرور",
    "Update Password": "تحديث كلمة المرور",
    "Password changed successfully": "تم تغيير كلمة المرور بنجاح",
    "Password reset link sent": "تم إرسال رابط إعادة تعيين كلمة المرور",
    "Check your email": "تحقق من بريدك الإلكتروني",
    "Email sent": "تم إرسال البريد الإلكتروني",
    "Verification email sent": "تم إرسال بريد التحقق الإلكتروني",
    "Please verify your email": "يرجى التحقق من بريدك الإلكتروني",
    "Email verified": "تم التحقق من البريد الإلكتروني",
    "Email not verified": "لم يتم التحقق من البريد الإلكتروني",
    "Verify Email": "التحقق من البريد الإلكتروني",
    "Resend Verification": "إعادة إرسال التحقق",
    "Remember me": "تذكرني",
    "Stay signed in": "البقاء مسجلاً",
    "Sign in with Google": "تسجيل الدخول باستخدام Google",
    "Sign in with Apple": "تسجيل الدخول باستخدام Apple",
    "Sign in with Facebook": "تسجيل الدخول باستخدام Facebook",
    "Or": "أو",
    "Already have an account?": "لديك حساب بالفعل؟",
    "Don't have an account?": "ليس لديك حساب؟",
    "By signing up, you agree to our": "بالتسجيل، فإنك توافق على",
    "Terms": "الشروط",
    "and": "و",
    "Account created successfully": "تم إنشاء الحساب بنجاح",
    "Signed in successfully": "تم تسجيل الدخول بنجاح",
    "Signed out successfully": "تم تسجيل الخروج بنجاح",
    "Welcome back": "مرحبًا بك مرة أخرى",
    "Welcome to {app}": "مرحبًا بك في {app}",
    "Account": "الحساب",
    "My Account": "حسابي",
    "Profile": "الملف الشخصي",
    "Edit Profile": "تعديل الملف الشخصي",
    "Update Profile": "تحديث الملف الشخصي",
    "Profile updated": "تم تحديث الملف الشخصي",
    "Profile picture": "صورة الملف الشخصي",
    "Change profile picture": "تغيير صورة الملف الشخصي",
    "Remove profile picture": "إزالة صورة الملف الشخصي",
    "Cover photo": "صورة الغلاف",
    "Change cover photo": "تغيير صورة الغلاف",
    "Delete Account": "حذف الحساب",
    "Deactivate Account": "تعطيل الحساب",
    "Are you sure?": "هل أنت متأكد؟",
    "This action cannot be undone": "لا يمكن التراجع عن هذا الإجراء",
    "Type {text} to confirm": "اكتب {text} للتأكيد",
    "Account deleted": "تم حذف الحساب",
    "Account deactivated": "تم تعطيل الحساب",
    
    # User Actions & Status
    "Follow": "متابعة",
    "Following": "يتابع",
    "Unfollow": "إلغاء المتابعة",
    "Follower": "متابع",
    "Followers": "المتابعون",
    "Block": "حظر",
    "Blocked": "محظور",
    "Unblock": "إلغاء الحظر",
    "Report": "الإبلاغ",
    "Reported": "تم الإبلاغ عنه",
    "Report User": "الإبلاغ عن المستخدم",
    "Report Post": "الإبلاغ عن المنشور",
    "Report Content": "الإبلاغ عن المحتوى",
    "Why are you reporting this?": "لماذا تبلغ عن هذا؟",
    "Spam or misleading": "بريد مزعج أو مضلل",
    "Inappropriate content": "محتوى غير لائق",
    "Harassment or bullying": "تحرش أو تنمر",
    "Violence or dangerous organizations": "عنف أو منظمات خطيرة",
    "Hate speech": "خطاب الكراهية",
    "False information": "معلومات خاطئة",
    "Copyright infringement": "انتهاك حقوق النشر",
    "Something else": "شيء آخر",
    "Thank you for reporting": "شكرًا لك على الإبلاغ",
    "We'll review this": "سنراجع هذا",
    "Mute": "كتم",
    "Muted": "مكتوم",
    "Unmute": "إلغاء الكتم",
    "Hide": "إخفاء",
    "Hidden": "مخفي",
    "Unhide": "إظهار",
    "Pin": "تثبيت",
    "Pinned": "مثبت",
    "Unpin": "إلغاء التثبيت",
    "Feature": "مميز",
    "Featured": "مميز",
    "Unfeature": "إلغاء التمييز",
    "Archive": "أرشفة",
    "Archived": "مؤرشف",
    "Restore": "استعادة",
    "Restored": "تم الاستعادة",
    "Active": "نشط",
    "Inactive": "غير نشط",
    "Enabled": "مفعل",
    "Disabled": "معطل",
    "Available": "متاح",
    "Unavailable": "غير متاح",
    "Online": "متصل",
    "Offline": "غير متصل",
    "Busy": "مشغول",
    "Away": "بعيد",
    "Do Not Disturb": "عدم الإزعاج",
    "Verified": "موثق",
    "Unverified": "غير موثق",
    "Pending": "قيد الانتظار",
    "Approved": "تمت الموافقة",
    "Rejected": "مرفوض",
    "Suspended": "معلق",
    "Banned": "محظور",
}

def apply_translations():
    """Apply Arabic mega translations pass 4 to ar.json"""
    input_file = '/Users/kristybock/artbeat/assets/translations/ar.json'
    output_file = input_file
    
    print("\n" + "="*60)
    print("Arabic Translation - Mega Pass 4")
    print("Focus: Errors, Validation, Forms, Authentication, Actions")
    print("="*60 + "\n")
    
    # Load current translations
    with open(input_file, 'r', encoding='utf-8') as f:
        translations = json.load(f)
    
    # Track progress
    applied_count = 0
    
    # Apply translations
    for english_text, arabic_text in AR_MEGA_TRANSLATIONS_4.items():
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
    print("Arabic Translation - Mega Pass 4 Complete")
    print("="*60)
    print(f"Translations applied: {applied_count}")
    print(f"Remaining bracketed entries: {remaining}")
    print(f"Overall progress: {completed}/{total} ({percentage:.1f}%)")
    print(f"File saved: {output_file}")
    print("="*60 + "\n")

if __name__ == "__main__":
    apply_translations()
