#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Final Chinese Translation - Messaging Entries
Translates remaining English messaging entries to Chinese
"""

import json

# Chinese translations for messaging entries
MESSAGING_TRANSLATIONS = {
    # Messaging Actions
    "Add Attachment": "添加附件",
    "Add Member": "添加成员",
    "Add Members": "添加成员",
    "Allow Messages": "允许消息",
    "Archive": "归档",
    "Badges": "徽章",
    "Are you sure you want to block this user?": "确定要阻止此用户吗？",
    "Block User": "阻止用户",
    "Blocked Users": "已阻止的用户",
    "This chat is archived": "此聊天已归档",
    "Chat Info": "聊天信息",
    "Chat not found": "未找到聊天",
    "Clear Search": "清除搜索",
    "Create": "创建",
    "Create Group": "创建群组",
    "Delete": "删除",
    "Start a conversation with fellow artists and connect with the Artbeat community": "与艺术家同行开始对话并与Artbeat社区联系",
    "Enable Notifications": "启用通知",
    
    # Error Messages
    "Failed to block user": "阻止用户失败",
    "Error loading chat": "加载聊天时出错",
    "Failed to create group": "创建群组失败",
    "Failed to leave group": "离开群组失败",
    "Failed to load contacts": "加载联系人失败",
    "Failed to load messages": "加载消息失败",
    "Error loading chats": "加载聊天时出错",
    "Failed to send message": "发送消息失败",
    "Error al enviar mensaje": "发送消息时出错",
    "Failed to unblock user": "取消阻止用户失败",
    
    # Files & Media
    "Files": "文件",
    
    # Filters
    "All": "全部",
    "Artists": "艺术家",
    "Collectors": "收藏家",
    "Galleries": "画廊",
    
    # Group Chat
    "Group Chat": "群聊",
    "Group created successfully": "群组已成功创建",
    "Group Description (optional)": "群组描述（可选）",
    "Group Info": "群组信息",
    "You left the group": "您已离开群组",
    "Members": "成员",
    "Group Name": "群组名称",
    "Enter a name for your group": "输入您的群组名称",
    "Groups": "群组",
    "Leave Group": "离开群组",
    "Loading conversations...": "正在加载对话...",
    "Loading media...": "正在加载媒体...",
    "Loading users...": "正在加载用户...",
    "Mark as Read": "标记为已读",
    "Mark as Unread": "标记为未读",
    "Media": "媒体",
    "Message": "消息",
    "Message sent": "消息已发送",
    "Mute": "静音",
    "New Conversation": "新对话",
    "No chats yet": "还没有聊天",
    "No conversations yet": "还没有对话",
    "No files shared": "没有共享文件",
    "No media shared": "没有共享媒体",
    "No members": "没有成员",
    "No messages": "没有消息",
    "No results found": "未找到结果",
    "Online": "在线",
    "Pin Chat": "固定聊天",
    "Recently Active": "最近活跃",
    "Remove Member": "移除成员",
    "Reply": "回复",
    "Search": "搜索",
    "Search chats": "搜索聊天",
    "Search conversations": "搜索对话",
    "Search messages": "搜索消息",
    "Search users": "搜索用户",
    "Select Members": "选择成员",
    "Send": "发送",
    "Sent": "已发送",
    "Tap to view": "点击查看",
    "Type a message": "输入消息",
    "Typing...": "正在输入...",
    "Unblock": "取消阻止",
    "Unblock User": "取消阻止用户",
    "Unmute": "取消静音",
    "Unpin Chat": "取消固定聊天",
    "View Media": "查看媒体",
    "View Profile": "查看个人资料",
    "You": "您",
    "You unblocked this user": "您已取消阻止此用户",
    "You blocked this user": "您已阻止此用户",
    
    # Additional messaging terms
    "Attach": "附加",
    "Camera": "相机",
    "Gallery": "图库",
    "Location": "位置",
    "Voice": "语音",
    "Document": "文档",
    "Contact": "联系人",
    "Sticker": "贴纸",
    "GIF": "GIF",
    "Poll": "投票",
    "Schedule": "计划",
    "Broadcast": "广播",
    "Forward": "转发",
    "Quote": "引用",
    "React": "反应",
    "Mention": "提及",
    "Thread": "话题",
    "Draft": "草稿",
    "Sent from": "发送自",
    "Delivered": "已送达",
    "Read": "已读",
    "Failed": "失败",
    "Pending": "待处理",
    "Offline": "离线",
    "Away": "离开",
    "Busy": "忙碌",
    "Do Not Disturb": "请勿打扰",
    "Last seen": "最后在线",
    "Active now": "现在活跃",
    "Today": "今天",
    "Yesterday": "昨天",
    "This week": "本周",
    "Last week": "上周",
    "This month": "本月",
    "Last month": "上个月",
}

def translate_messaging_entries():
    """Translate remaining English messaging entries to Chinese"""
    # Load current translations
    file_path = '/Users/kristybock/artbeat/assets/translations/zh.json'
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    translated_count = 0
    
    # Translate messaging entries
    for key, value in data.items():
        if isinstance(value, str):
            # Check if it's an English text that we have a translation for
            if value in MESSAGING_TRANSLATIONS:
                data[key] = MESSAGING_TRANSLATIONS[value]
                translated_count += 1
                if translated_count <= 20:
                    print(f'  ✓ "{value}" → "{data[key]}"')
    
    # Save the updated translations
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"\n{'='*60}")
    print(f"Chinese Messaging Translation - FINAL")
    print(f"{'='*60}")
    print(f"Translated: {translated_count}")
    print(f"File saved: {file_path}")
    print(f"{'='*60}")

if __name__ == '__main__':
    translate_messaging_entries()
