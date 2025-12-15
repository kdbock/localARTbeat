#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Arabic Translation Script - Mega Pass 2
Focus: Messaging, Chat, Art Walks, Achievements, Events, and Artist Features
"""

import json
import re

# Mega Pass 2: Messaging, Art Walks, Achievements, Events, Artist Features
AR_MEGA_TRANSLATIONS_2 = {
    # Messaging & Chat
    "No messages yet": "لا توجد رسائل بعد",
    "Start a conversation": "ابدأ محادثة",
    "Type a message...": "اكتب رسالة...",
    "Send message": "إرسال رسالة",
    "Message sent": "تم إرسال الرسالة",
    "Failed to send message": "فشل في إرسال الرسالة",
    "Failed to load messages": "فشل في تحميل الرسائل",
    "Message deleted": "تم حذف الرسالة",
    "Delete message": "حذف الرسالة",
    "Mark as read": "وضع علامة كمقروءة",
    "Mark as unread": "وضع علامة كغير مقروءة",
    "Conversation": "محادثة",
    "New message from {sender}": "رسالة جديدة من {sender}",
    "You have {count} unread messages": "لديك {count} رسالة غير مقروءة",
    "No conversations": "لا توجد محادثات",
    "Chat": "محادثة",
    "Inbox": "صندوق الوارد",
    "Sent": "تم الإرسال",
    "Message history": "سجل الرسائل",
    "Search messages": "البحث في الرسائل",
    "Block user": "حظر المستخدم",
    "Unblock user": "إلغاء حظر المستخدم",
    "Report conversation": "الإبلاغ عن المحادثة",
    "Clear conversation": "مسح المحادثة",
    "Mute notifications": "كتم الإشعارات",
    "Unmute notifications": "إلغاء كتم الإشعارات",
    "Attachment": "مرفق",
    "Send photo": "إرسال صورة",
    "Camera": "كاميرا",
    "Photo": "صورة",
    "Image": "صورة",
    "Online": "متصل",
    "Offline": "غير متصل",
    "Last seen {time}": "آخر ظهور {time}",
    "Typing...": "يكتب...",
    "Message request": "طلب رسالة",
    "Accept": "قبول",
    "Decline": "رفض",
    "Spam": "بريد مزعج",
    "Archive": "أرشيف",
    "Unarchive": "إلغاء الأرشفة",
    
    # Art Walks
    "Art Walk": "جولة فنية",
    "Art Walks": "جولات فنية",
    "Create Art Walk": "إنشاء جولة فنية",
    "Join Art Walk": "الانضمام إلى جولة فنية",
    "Leave Art Walk": "مغادرة الجولة الفنية",
    "Art Walk created": "تم إنشاء الجولة الفنية",
    "Art Walk updated": "تم تحديث الجولة الفنية",
    "Art Walk deleted": "تم حذف الجولة الفنية",
    "Failed to create art walk": "فشل في إنشاء الجولة الفنية",
    "Failed to join art walk": "فشل في الانضمام إلى الجولة الفنية",
    "Failed to load art walks": "فشل في تحميل الجولات الفنية",
    "Start Date": "تاريخ البدء",
    "End Date": "تاريخ الانتهاء",
    "Location": "الموقع",
    "Route": "المسار",
    "Participating Artists": "الفنانون المشاركون",
    "Featured Artworks": "الأعمال الفنية المميزة",
    "Upcoming Art Walks": "الجولات الفنية القادمة",
    "Past Art Walks": "الجولات الفنية السابقة",
    "Active Art Walks": "الجولات الفنية النشطة",
    "No art walks found": "لم يتم العثور على جولات فنية",
    "Walk Details": "تفاصيل الجولة",
    "Map View": "عرض الخريطة",
    "List View": "عرض القائمة",
    "Directions": "الاتجاهات",
    "Check In": "تسجيل الدخول",
    "Check Out": "تسجيل الخروج",
    "Checked in": "تم تسجيل الدخول",
    "Share Art Walk": "مشاركة الجولة الفنية",
    "Invite Friends": "دعوة الأصدقاء",
    "RSVP": "تأكيد الحضور",
    "Going": "سأحضر",
    "Maybe": "ربما",
    "Not Going": "لن أحضر",
    "{count} people going": "{count} شخص سيحضر",
    "Distance: {distance}": "المسافة: {distance}",
    "Duration: {duration}": "المدة: {duration}",
    "Stops": "محطات",
    "Next Stop": "المحطة التالية",
    "Previous Stop": "المحطة السابقة",
    "Complete Walk": "إكمال الجولة",
    "Walk Progress": "تقدم الجولة",
    "{visited} of {total} stops visited": "تمت زيارة {visited} من أصل {total} محطة",
    
    # Achievements & Rewards
    "Achievements": "الإنجازات",
    "Achievement unlocked": "تم فتح الإنجاز",
    "Congratulations!": "تهانينا!",
    "You've unlocked: {achievement}": "لقد فتحت: {achievement}",
    "Rewards": "المكافآت",
    "Claim Reward": "استلام المكافأة",
    "Reward claimed": "تم استلام المكافأة",
    "Points": "نقاط",
    "Badges": "شارات",
    "Level": "المستوى",
    "Level {level}": "المستوى {level}",
    "Experience": "الخبرة",
    "XP": "نقاط الخبرة",
    "{current}/{total} XP": "{current}/{total} نقاط خبرة",
    "Next Level": "المستوى التالي",
    "{xp} XP to next level": "{xp} نقاط خبرة للمستوى التالي",
    "Leaderboard": "لوحة المتصدرين",
    "Rank": "الترتيب",
    "Ranking": "التصنيف",
    "Top Artists": "أفضل الفنانين",
    "Top Collectors": "أفضل الجامعين",
    "My Rank: {rank}": "ترتيبي: {rank}",
    "Progress": "التقدم",
    "Milestone": "معلم",
    "Milestones": "معالم",
    "Streak": "سلسلة",
    "{days} day streak": "سلسلة {days} يوم",
    "Daily Streak": "السلسلة اليومية",
    "Weekly Challenge": "التحدي الأسبوعي",
    "Monthly Goal": "الهدف الشهري",
    "Completed": "مكتمل",
    "In Progress": "قيد التقدم",
    "Locked": "مقفل",
    "Unlocked": "مفتوح",
    "Unlock Condition": "شرط الفتح",
    "{completed}/{total} completed": "تم إكمال {completed} من أصل {total}",
    
    # Events
    "Event": "حدث",
    "Events": "الأحداث",
    "Create Event": "إنشاء حدث",
    "Edit Event": "تعديل الحدث",
    "Delete Event": "حذف الحدث",
    "Event created": "تم إنشاء الحدث",
    "Event updated": "تم تحديث الحدث",
    "Event deleted": "تم حذف الحدث",
    "Failed to create event": "فشل في إنشاء الحدث",
    "Failed to load events": "فشل في تحميل الأحداث",
    "Upcoming Events": "الأحداث القادمة",
    "Past Events": "الأحداث السابقة",
    "Featured Events": "الأحداث المميزة",
    "Event Details": "تفاصيل الحدث",
    "Event Name": "اسم الحدث",
    "Event Description": "وصف الحدث",
    "Event Date": "تاريخ الحدث",
    "Event Time": "وقت الحدث",
    "Event Location": "موقع الحدث",
    "Venue": "المكان",
    "Organizer": "المنظم",
    "Register": "التسجيل",
    "Registration": "التسجيل",
    "Registration Required": "التسجيل مطلوب",
    "Registration Closed": "التسجيل مغلق",
    "Registered": "مسجل",
    "Register Now": "سجل الآن",
    "Unregister": "إلغاء التسجيل",
    "{count} attendees": "{count} حاضر",
    "Attendees": "الحضور",
    "Capacity": "السعة",
    "{current}/{max} spots filled": "تم ملء {current}/{max} مقعد",
    "Sold Out": "نفدت التذاكر",
    "Free Event": "حدث مجاني",
    "Ticket Price": "سعر التذكرة",
    "Buy Ticket": "شراء تذكرة",
    "Tickets": "التذاكر",
    "Virtual Event": "حدث افتراضي",
    "In-Person Event": "حدث حضوري",
    "Hybrid Event": "حدث مختلط",
    "Join Online": "الانضمام عبر الإنترنت",
    "Event Link": "رابط الحدث",
    "Add to Calendar": "إضافة إلى التقويم",
    "Share Event": "مشاركة الحدث",
    "Reminder Set": "تم تعيين التذكير",
    "Set Reminder": "تعيين تذكير",
    "Event starts in {time}": "يبدأ الحدث خلال {time}",
    
    # Artist Features
    "Artist Profile": "الملف الشخصي للفنان",
    "Verified Artist": "فنان موثق",
    "Featured Artist": "فنان مميز",
    "Artist Statement": "بيان الفنان",
    "Artist Bio": "السيرة الذاتية للفنان",
    "Portfolio": "المعرض",
    "Artworks": "الأعمال الفنية",
    "Collections": "المجموعات",
    "Exhibitions": "المعارض",
    "Current Exhibition": "المعرض الحالي",
    "Past Exhibitions": "المعارض السابقة",
    "Upcoming Exhibitions": "المعارض القادمة",
    "Solo Exhibition": "معرض فردي",
    "Group Exhibition": "معرض جماعي",
    "Gallery": "معرض",
    "Studio": "استوديو",
    "Commission": "عمولة",
    "Available for Commission": "متاح للعمولة",
    "Commission Request": "طلب عمولة",
    "Request Commission": "طلب عمولة",
    "Commission Accepted": "تم قبول العمولة",
    "Commission Declined": "تم رفض العمولة",
    "Commission Price": "سعر العمولة",
    "Medium": "الوسيط",
    "Style": "الأسلوب",
    "Technique": "التقنية",
    "Materials": "المواد",
    "Dimensions": "الأبعاد",
    "Year Created": "سنة الإنشاء",
    "Original": "أصلي",
    "Print": "طباعة",
    "Limited Edition": "طبعة محدودة",
    "Edition of {number}": "طبعة من {number}",
    "Series": "سلسلة",
    "Framed": "مؤطر",
    "Unframed": "غير مؤطر",
    "Signed": "موقع",
    "Certificate of Authenticity": "شهادة أصالة",
    "Provenance": "المصدر",
    "Artist's Website": "موقع الفنان",
    "Artist Contact": "الاتصال بالفنان",
    "Contact Artist": "الاتصال بالفنان",
    "Follow Artist": "متابعة الفنان",
    "Unfollow Artist": "إلغاء متابعة الفنان",
    "{count} followers": "{count} متابع",
    "{count} following": "يتابع {count}",
    "Similar Artists": "فنانون مشابهون",
    "Featured Works": "أعمال مميزة",
    "Latest Works": "أحدث الأعمال",
    "Popular Works": "أعمال شائعة",
    "Sold Works": "أعمال مباعة",
}

def apply_translations():
    """Apply Arabic mega translations pass 2 to ar.json"""
    input_file = '/Users/kristybock/artbeat/assets/translations/ar.json'
    output_file = input_file
    
    print("\n" + "="*60)
    print("Arabic Translation - Mega Pass 2")
    print("Focus: Messaging, Art Walks, Achievements, Events, Artists")
    print("="*60 + "\n")
    
    # Load current translations
    with open(input_file, 'r', encoding='utf-8') as f:
        translations = json.load(f)
    
    # Track progress
    applied_count = 0
    
    # Apply translations
    for english_text, arabic_text in AR_MEGA_TRANSLATIONS_2.items():
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
    print("Arabic Translation - Mega Pass 2 Complete")
    print("="*60)
    print(f"Translations applied: {applied_count}")
    print(f"Remaining bracketed entries: {remaining}")
    print(f"Overall progress: {completed}/{total} ({percentage:.1f}%)")
    print(f"File saved: {output_file}")
    print("="*60 + "\n")

if __name__ == "__main__":
    apply_translations()
