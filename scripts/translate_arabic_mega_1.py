#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Arabic Translation - Mega Pass 1
Translates bracketed English placeholders to Arabic in ar.json
"""

import json

# Comprehensive Arabic translations - Pass 1
# Covering: Admin, errors, management, UI elements, security, authentication
AR_MEGA_TRANSLATIONS_1 = {
    # Admin & Ad Management
    "Failed to approve ad: {error}": "فشل في الموافقة على الإعلان: {error}",
    "Failed to load ad management data: {error}": "فشل في تحميل بيانات إدارة الإعلانات: {error}",
    "Failed to reject ad: {error}": "فشل في رفض الإعلان: {error}",
    "Failed to review report: {error}": "فشل في مراجعة التقرير: {error}",
    "Flagged": "مبلغ عنه",
    "Pending Review": "قيد المراجعة",
    "Approved via admin dashboard": "تمت الموافقة عليه عبر لوحة تحكم المشرف",
    "Action taken by admin": "تم اتخاذ إجراء من قبل المشرف",
    "Report dismissed by admin": "تم رفض التقرير من قبل المشرف",
    "Report {status}": "التقرير {status}",
    'Ad "{title}" approved successfully': 'تمت الموافقة على الإعلان "{title}" بنجاح',
    'Ad "{title}" rejected': 'تم رفض الإعلان "{title}"',
    "View Details": "عرض التفاصيل",
    "Error: $e": "خطأ: $e",
    "Error loading artwork: $e": "خطأ في تحميل العمل الفني: $e",
    "Error loading details: $e": "خطأ في تحميل التفاصيل: $e",
    "Artwork status updated to $newStatus": "تم تحديث حالة العمل الفني إلى $newStatus",
    "Artwork deleted": "تم حذف العمل الفني",
    "Artwork Management": "إدارة الأعمال الفنية",
    "Comment deleted": "تم حذف التعليق",
    "Delete Comment": "حذف التعليق",
    "Flag": "إبلاغ",
    "No artwork found": "لم يتم العثور على أعمال فنية",
    "Reject Artwork": "رفض العمل الفني",
    "Select artwork to view details": "اختر عملاً فنياً لعرض التفاصيل",
    
    # Transactions & Payments
    "Click below to copy CSV content:": "انقر أدناه لنسخ محتوى CSV:",
    "Mark as Failed": "وضع علامة كفشل",
    "Download $fileName": "تنزيل $fileName",
    "User: ${transaction.userName}": "المستخدم: ${transaction.userName}",
    "Description: ${transaction.description}": "الوصف: ${transaction.description}",
    "Amount: ${transaction.formattedAmount}": "المبلغ: ${transaction.formattedAmount}",
    "Are you sure you want to process this refund?": "هل أنت متأكد من رغبتك في معالجة هذا الاسترداد؟",
    "Avg Transaction": "متوسط المعاملات",
    "Bulk Refund": "استرداد جماعي",
    "Clear All Filters": "مسح جميع الفلاتر",
    "Copy to Clipboard": "نسخ إلى الحافظة",
    "CSV content copied to clipboard": "تم نسخ محتوى CSV إلى الحافظة",
    "Date Range": "النطاق الزمني",
    "\\$${entry.value.toStringAsFixed(2)}": "\\$${entry.value.toStringAsFixed(2)}",
    "Export Selected": "تصدير المحدد",
    "Mark as Completed": "وضع علامة كمكتمل",
    "Mark as Pending": "وضع علامة كقيد الانتظار",
    "Payment Management": "إدارة المدفوعات",
    "Payment Method: ${transaction.paymentMethod}": "طريقة الدفع: ${transaction.paymentMethod}",
    "Process Bulk Refunds": "معالجة الاستردادات الجماعية",
    "Process Refund": "معالجة الاسترداد",
    "Total Refunds": "إجمالي الاستردادات",
    "Total Transactions": "إجمالي المعاملات",
    "Transaction Details": "تفاصيل المعاملة",
    "Transaction ID: ${transaction.id}": "معرف المعاملة: ${transaction.id}",
    "Transaction: ${transaction.id}": "المعاملة: ${transaction.id}",
    "Item: ${transaction.itemTitle}": "العنصر: ${transaction.itemTitle}",
    "Update Status": "تحديث الحالة",
    
    # Security & Admin
    "Email Alerts": "تنبيهات البريد الإلكتروني",
    "Send email notifications for threats": "إرسال إشعارات البريد الإلكتروني للتهديدات",
    "Automatically block suspicious activity": "حظر النشاط المشبوه تلقائياً",
    "Disable Account": "تعطيل الحساب",
    "Edit Permissions": "تعديل الأذونات",
    "IP Address: 192.168.1.${100 + index}": "عنوان IP: 192.168.1.${100 + index}",
    "IP range added to whitelist": "تمت إضافة نطاق IP إلى القائمة البيضاء",
    "Log ID: LOG_${1000 + index}": "معرف السجل: LOG_${1000 + index}",
    "Office Network": "شبكة المكتب",
    "Real-time Monitoring": "المراقبة في الوقت الفعلي",
    "Recommended Actions:": "الإجراءات الموصى بها:",
    "Remove Admin": "إزالة المشرف",
    "Resolve": "حل",
    "VPN Network": "شبكة VPN",
    "Danger Zone": "منطقة الخطر",
    "No settings available": "لا توجد إعدادات متاحة",
    "User Settings": "إعدادات المستخدم",
    "Error loading system data: $e": "خطأ في تحميل بيانات النظام: $e",
    
    # System Monitoring
    "Avg Session": "متوسط الجلسة",
    "CPU Usage": "استخدام المعالج",
    "Critical Alerts": "تنبيهات حرجة",
    "Memory Usage": "استخدام الذاكرة",
    "No system alerts": "لا توجد تنبيهات النظام",
    "Response Time": "وقت الاستجابة",
    "System Monitoring": "مراقبة النظام",
    "Warning Alerts": "تنبيهات تحذيرية",
    
    # User Profile Management
    "Failed to remove profile image: $e": "فشل في إزالة صورة الملف الشخصي: $e",
    "Failed to update profile: $e": "فشل في تحديث الملف الشخصي: $e",
    "Failed to update featured status: $e": "فشل في تحديث حالة المميز: $e",
    "Failed to update user type: $e": "فشل في تحديث نوع المستخدم: $e",
    "Failed to update verification status: $e": "فشل في تحديث حالة التحقق: $e",
    "Profile image removed successfully": "تمت إزالة صورة الملف الشخصي بنجاح",
    "User profile updated successfully": "تم تحديث الملف الشخصي للمستخدم بنجاح",
    "User type updated to ${newType.name}": "تم تحديث نوع المستخدم إلى ${newType.name}",
    "By: ${_currentUser.suspendedBy}": "بواسطة: ${_currentUser.suspendedBy}",
    "Reason: ${_currentUser.suspensionReason}": "السبب: ${_currentUser.suspensionReason}",
    
    # Navigation & Development
    "Return to main app": "العودة إلى التطبيق الرئيسي",
    "Transaction & refund management": "إدارة المعاملات والاستردادات",
    "Edit this file to add navigation buttons to module screens": "قم بتعديل هذا الملف لإضافة أزرار التنقل إلى شاشات الوحدة",
    "Standalone development environment": "بيئة تطوير مستقلة",
    "Uadmin Module Demo": "عرض توضيحي لوحدة Uadmin",
    "Example Button": "زر تجريبي",
    
    # Migration & Data
    "Migrate Geo Fields": "ترحيل الحقول الجغرافية",
    "Rollback Migration": "التراجع عن الترحيل",
    "Run Migration": "تشغيل الترحيل",
    "Migration failed: ${error}": "فشل الترحيل: ${error}",
    "Geo field migration failed: ${error}": "فشل ترحيل الحقل الجغرافي: ${error}",
    "Rollback failed: ${error}": "فشل التراجع: ${error}",
    "Moderation Status Migration": "ترحيل حالة الإشراف",
    "Migration completed successfully!": "تم الترحيل بنجاح!",
    "Geo field migration completed successfully!": "تم ترحيل الحقل الجغرافي بنجاح!",
    "Rollback completed successfully!": "تم التراجع بنجاح!",
    "Data Migration": "ترحيل البيانات",
    "Migrate Geo Fields for Captures": "ترحيل الحقول الجغرافية للالتقاطات",
    "Rollback": "تراجع",
    "Refresh Status": "تحديث الحالة",
    
    # Content Moderation
    "❌ Failed to approve content: $e": "❌ فشل في الموافقة على المحتوى: $e",
    "❌ Failed to reject content: $e": "❌ فشل في رفض المحتوى: $e",
    'Deleted "${content.title}" successfully': 'تم حذف "${content.title}" بنجاح',
    'Updated "${newTitle}" successfully': 'تم تحديث "${newTitle}" بنجاح',
    "Rejecting content...": "جارٍ رفض المحتوى...",
    
    # Common UI Elements
    "Cancel": "إلغاء",
    "Confirm": "تأكيد",
    "Delete": "حذف",
    "Edit": "تعديل",
    "Close": "إغلاق",
    "Submit": "إرسال",
    "Filter": "تصفية",
    "Export": "تصدير",
    "Import": "استيراد",
    "Undo": "تراجع",
    "Redo": "إعادة",
    "Deselect": "إلغاء الاختيار",
    "Reload": "إعادة تحميل",
    "Skip": "تخطي",
    "Finish": "إنهاء",
    "Apply": "تطبيق",
    "Count": "العدد",
    "Type": "النوع",
    "Status": "الحالة",
    "Date": "التاريخ",
    "Time": "الوقت",
    "Author": "المؤلف",
    "Owner": "المالك",
    "Creator": "المنشئ",
    "Modified": "معدل",
    "Created": "تم الإنشاء",
    "Updated": "تم التحديث",
    "Public": "عام",
    "Private": "خاص",
    "Options": "خيارات",
    
    # Status messages
    "Successfully updated": "تم التحديث بنجاح",
    "Successfully created": "تم الإنشاء بنجاح",
    "Successfully deleted": "تم الحذف بنجاح",
    "Operation completed": "تمت العملية",
    "Action completed": "تم الإجراء",
    "Changes saved": "تم حفظ التغييرات",
    "No changes made": "لم يتم إجراء تغييرات",
    "Invalid input": "إدخال غير صالح",
    "Required field": "حقل مطلوب",
    "Field is required": "الحقل مطلوب",
    "Invalid format": "تنسيق غير صالح",
    "Value too long": "القيمة طويلة جداً",
    "Value too short": "القيمة قصيرة جداً",
    "Out of range": "خارج النطاق",
    "Already exists": "موجود بالفعل",
    "Not allowed": "غير مسموح",
    "Permission denied": "تم رفض الإذن",
    "Access denied": "تم رفض الوصول",
    "Unauthorized": "غير مصرح",
    "Forbidden": "محظور",
    "Not available": "غير متاح",
    "Coming soon": "قريباً",
    "Under maintenance": "قيد الصيانة",
    "Temporarily unavailable": "غير متاح مؤقتاً",
}

def translate_arabic():
    """Translate bracketed English text to Arabic"""
    file_path = '/Users/kristybock/artbeat/assets/translations/ar.json'
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    total_count = 0
    translated_count = 0
    
    for key, value in data.items():
        if isinstance(value, str):
            total_count += 1
    
    for key, value in data.items():
        if isinstance(value, str):
            if value.startswith('[') and value.endswith(']'):
                english_text = value[1:-1]
                
                if english_text in AR_MEGA_TRANSLATIONS_1:
                    data[key] = AR_MEGA_TRANSLATIONS_1[english_text]
                    translated_count += 1
                    if translated_count <= 20:
                        print(f'  ✓ "{english_text[:60]}" → "{data[key][:60]}"')
    
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    remaining_count = 0
    for key, value in data.items():
        if isinstance(value, str) and value.startswith('[') and value.endswith(']'):
            remaining_count += 1
    
    print(f"\n{'='*60}")
    print(f"Arabic Translation - Mega Pass 1 Complete")
    print(f"{'='*60}")
    print(f"Translations applied: {translated_count}")
    print(f"Remaining bracketed entries: {remaining_count}")
    print(f"Overall progress: {total_count - remaining_count}/{total_count} ({((total_count - remaining_count) / total_count * 100):.1f}%)")
    print(f"File saved: {file_path}")
    print(f"{'='*60}")

if __name__ == '__main__':
    translate_arabic()
