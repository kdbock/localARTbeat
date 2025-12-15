#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Mega Chinese Translation Pass 5 - FINAL
Translates remaining bracketed English placeholders to Chinese in zh.json
"""

import json
import re

# Comprehensive Chinese translations - Pass 5 (FINAL)
# Covering all remaining entries
ZH_MEGA_TRANSLATIONS_5 = {
    # Art Walk Navigation & Management
    "This will add geo fields (geohash and geopoint) to all captures\n with locations. This is required for instant discovery to show user captures. Continue?": "这将向所有带有位置的捕获添加地理字段（geohash和地理点）。\n这是即时发现功能显示用户捕获所必需的。继续？",
    "Error loading art pieces: $e": "加载艺术作品时出错：$e",
    "Leave Art Walk Creation?": "离开艺术漫步创建？",
    "No art pieces available.": "无可用艺术作品。",
    "Please select at least one art piece": "请至少选择一件艺术作品",
    "Stay": "留下",
    "Your progress will be lost.": "您的进度将丢失。",
    "Error abandoning walk: $e": "放弃漫步时出错：$e",
    "Error advancing navigation: $e": "前进导航时出错：$e",
    "Error completing walk: $e": "完成漫步时出错：$e",
    "Error getting location: ${e.toString()}": "获取位置时出错：${e.toString()}",
    "Error marking as visited: $e": "标记为已访问时出错：$e",
    "Error pausing walk: $e": "暂停漫步时出错：$e",
    "Error resuming walk: $e": "恢复漫步时出错：$e",
    "Error stopping navigation: $e": "停止导航时出错：$e",
    "Error with previous step: $e": "上一步出错：$e",
    
    # Walk Progress & UI
    "• Achievement progress updated": "• 成就进度已更新",
    "⬅️ At first step of this segment": "⬅️ 在此段的第一步",
    "Claim Rewards": "领取奖励",
    "Complete Now": "立即完成",
    "Complete Walk": "完成漫步",
    "Complete Walk Early?": "提前完成漫步？",
    "• +$completionBonus XP total": "• +$completionBonus XP 总计",
    "• Follow the blue route line": "• 跟随蓝色路线",
    "• ${_formatDuration(timeSpent)} duration": "• ${_formatDuration(timeSpent)} 时长",
    "Got it": "知道了",
    "• Green markers = visited": "• 绿色标记 = 已访问",
    "How to Use": "如何使用",
    "Keep Exploring": "继续探索",
    "Leave Walk?": "离开漫步？",
    "Navigation not active": "导航未激活",
    "Navigation paused while app is in background": "应用在后台时导航已暂停",
    "Navigation resumed": "导航已恢复",
    "Navigation stopped.": "导航已停止。",
    "No navigation step available": "无可用导航步骤",
    "Pause Walk": "暂停漫步",
    "• $photosCount photos taken": "• 已拍摄 $photosCount 张照片",
    "• Red markers = not yet visited": "• 红色标记 = 尚未访问",
    "Resume Walk": "恢复漫步",
    "Review Walk": "查看漫步",
    "⬅️ Showing previous navigation step": "⬅️ 显示上一个导航步骤",
    "View Progress": "查看进度",
    "🎉 Walk Completed!": "🎉 漫步已完成！",
    "Walk paused. You can resume anytime!": "漫步已暂停。您可以随时恢复！",
    "Walk Progress": "漫步进度",
    "Would you like to finish now or continue exploring?": "您想现在完成还是继续探索？",
    "• You can still claim other rewards": "• 您仍然可以领取其他奖励",
    
    # Walk Management
    "Error deleting walk: $e": "删除漫步时出错：$e",
    "Error loading data: $e": "加载数据时出错：$e",
    "Error submitting review: $e": "提交评论时出错：$e",
    "Error unsaving walk: $e": "取消保存漫步时出错：$e",
    "Failed to save review: $e": "保存评论失败：$e",
    "No saved walks yet": "还没有保存的漫步",
    "Saved": "已保存",
    "Complete your first art walk to see it here": "完成您的第一次艺术漫步即可在此查看",
    "Create Walk": "创建漫步",
    "Delete Walk?": "删除漫步？",
    "In Progress": "进行中",
    "Log In": "登录",
    "My Art Walks": "我的艺术漫步",
    "No completed walks yet": "还没有完成的漫步",
    "No walks created yet": "还没有创建的漫步",
    "No walks in progress": "没有进行中的漫步",
    "• Perfect walk - all art found!": "• 完美漫步 - 找到所有艺术品！",
    "Submit Review": "提交评论",
    "• ${widget.progress.totalPointsEarned} points earned": "• 已获得 ${widget.progress.totalPointsEarned} 点",
    "🎉 You discovered all nearby art!": "🎉 您发现了所有附近的艺术品！",
    "Weekly Goals": "每周目标",
    
    # Analytics & Data
    "Error loading analytics data: ${e.toString()}": "加载分析数据时出错：${e.toString()}",
    "No artwork data available": "无可用作品数据",
    "No location data available": "无可用位置数据",
    "No referral data available": "无可用推荐数据",
    "No visitor data available": "无可用访客数据",
    "Unknown Artwork": "未知作品",
    "Upgrade Now": "立即升级",
    "Revenue Tracking": "收入跟踪",
    
    # Artist Management
    "Error loading artists: $e": "加载艺术家时出错：$e",
    "Filter Artists": "筛选艺术家",
    "Medium: $_selectedMedium": "媒介：$_selectedMedium",
    "No artists found": "未找到艺术家",
    "Style: $_selectedStyle": "风格：$_selectedStyle",
    "Gift Received": "已收到礼物",
    "Host exhibitions and gatherings": "举办展览和聚会",
    "Manage your commissions": "管理您的佣金",
    "Photo Post": "照片帖子",
    "Set up commission settings": "设置佣金设置",
    "Share photos from your studio": "分享您工作室的照片",
    "Share updates with your community": "与您的社区分享更新",
    "Share your thoughts and updates": "分享您的想法和更新",
    "Showcase your latest creation": "展示您的最新创作",
    "Text Post": "文字帖子",
    "Track your performance": "跟踪您的表现",
    "Upload Artwork": "上传作品",
    "View All Activity": "查看所有活动",
    "Become an Artist": "成为艺术家",
    "Free Plan": "免费计划",
    "Starter Plan": "入门计划",
    "Failed to load artists": "加载艺术家失败",
    "Error creating artist profile: $e": "创建艺术家个人资料时出错：$e",
    "Error loading profile: $e": "加载个人资料时出错：$e",
    "Error saving profile: $e": "保存个人资料时出错：$e",
    "Individual Artist": "个人艺术家",
    "Mediums": "媒介",
    "Styles": "风格",
    "Error loading artist profile: $e": "加载艺术家个人资料时出错：$e",
    "Could not open $url": "无法打开 $url",
    "No artwork available": "无可用作品",
    "Please log in to follow artists": "请登录以关注艺术家",
    "Please log in to send gifts": "请登录以发送礼物",
    "You cannot send gifts to yourself": "您不能给自己发送礼物",
    "Error selecting image: ${e.toString()}": "选择图片时出错：${e.toString()}",
    "Upgrade to Pro": "升级到专业版",
    
    # Gallery & Analytics
    "Error loading featured artists: $e": "加载精选艺术家时出错：$e",
    "Gallery Analytics": "画廊分析",
    "Last 12 Months": "过去12个月",
    "Last 30 Days": "过去30天",
    "Last 7 Days": "过去7天",
    "Last 90 Days": "过去90天",
    "No artist performance data available": "无可用艺术家表现数据",
    "No revenue data available for selected time period": "所选时间段内无可用收入数据",
    "Paid Commissions": "已付佣金",
    "Pending Commissions": "待处理佣金",
    "Revenue": "收入",
    "Sales": "销售",
    "Total Commissions": "总佣金",
    "Upgrade to Gallery Plan": "升级到画廊计划",
    "Error searching artists: ${e.toString()}": "搜索艺术家时出错：${e.toString()}",
    
    # Gallery Management
    "Failed to cancel invitation: $e": "取消邀请失败：$e",
    "Failed to remove artist from gallery: $e": "从画廊移除艺术家失败：$e",
    "Failed to resend invitation: $e": "重新发送邀请失败：$e",
    "Failed to send invitation: $e": "发送邀请失败：$e",
    "Invitation sent successfully": "邀请已成功发送",
    "Gallery Artists": "画廊艺术家",
    "Invitation cancelled": "邀请已取消",
    "Invitation reminder sent": "邀请提醒已发送",
    "Please select a plan": "请选择计划",
    "Welcome! Setting up your profile...": "欢迎！正在设置您的个人资料...",
    
    # Artwork Management
    "Failed to delete artwork: $e": "删除作品失败：$e",
    "Deleting artwork...": "正在删除作品...",
    "My Artwork": "我的作品",
    "Subscribe to ${_getTierName(widget.tier)}": "订阅 ${_getTierName(widget.tier)}",
    "Set as Default": "设为默认",
    "Subscription Successful": "订阅成功",
    "Refund Request Submitted": "退款请求已提交",
    "Request Refund": "请求退款",
    "Submit Refund Request": "提交退款请求",
    "Error loading analytics: $e": "加载分析时出错：$e",
    "Manage Subscription": "管理订阅",
    "No data available for the selected period": "所选时间段无可用数据",
    "Subscription Analytics": "订阅分析",
    "This Year": "今年",
    "Error loading verified artists: $e": "加载已验证艺术家时出错：$e",
    "Filter Verified Artists": "筛选已验证艺术家",
    
    # Captures
    "Error loading captures: $e": "加载捕获时出错：$e",
    "Type: ${capture.artType!}": "类型：${capture.artType!}",
    "Delete Capture": "删除捕获",
    "Reject Capture": "拒绝捕获",
    "Save Capture": "保存捕获",
    "Failed to delete capture: $e": "删除捕获失败：$e",
    "No capture found": "未找到捕获",
    "Edit Capture": "编辑捕获",
    "GestureDetector was tapped!": "手势检测器被点击！",
    "Failed to get location: $e": "获取位置失败：$e",
    "Location permissions are denied": "位置权限被拒绝",
    "Location services are disabled.": "位置服务已禁用。",
    "Please accept the public art disclaimer": "请接受公共艺术免责声明",
    "Public Art Disclaimer": "公共艺术免责声明",
    "Upload Capture": "上传捕获",
    "Local Captures": "本地捕获",
    "Find art captures by location or type": "按位置或类型查找艺术捕获",
    "Search Captures": "搜索捕获",
    "Search for artists and their captures": "搜索艺术家及其捕获",
    "Nearby Art": "附近的艺术",
    "Popular Captures": "热门捕获",
    "See trending art discoveries": "查看热门艺术发现",
    "Take Photo": "拍照",
    "Terms & Conditions": "条款和条件",
    
    # Feed & Social
    "Error loading feed: $e": "加载动态时出错：$e",
    "Loading artist feed...": "正在加载艺术家动态...",
    "Load More": "加载更多",
    "Unable to load artist feed": "无法加载艺术家动态",
    
    # Messaging
    "Search Conversations": "搜索对话",
    "Search for artists and community members": "搜索艺术家和社区成员",
    "Find messages and chat history": "查找消息和聊天记录",
    "Message Settings": "消息设置",
    "Messages": "消息",
    "Blocked Users": "已阻止的用户",
    "Find People": "查找用户",
    "Join Groups": "加入群组",
    "Manage blocked contacts": "管理已阻止的联系人",
    "Messaging Help": "消息帮助",
    "Popular Chats": "热门聊天",
    "Privacy and notification preferences": "隐私和通知偏好",
    "See trending conversations": "查看热门对话",
    "Tips and support for messaging": "消息提示和支持",
    "Error loading blocked users: $e": "加载已阻止用户时出错：$e",
    "Error unblocking user: $e": "取消阻止用户时出错：$e",
    "Failed to report user: $e": "举报用户失败：$e",
    "Report ${user.displayName} for inappropriate behavior?": "举报 ${user.displayName} 的不当行为？",
    "User reported successfully": "用户已成功举报",
    "Report User": "举报用户",
    "Failed to send message: ${e.toString()}": "发送消息失败：${e.toString()}",
    "Failed to send image: ${e.toString()}": "发送图片失败：${e.toString()}",
    "Failed to send voice message: ${e.toString()}": "发送语音消息失败：${e.toString()}",
    "Error loading participants: $e": "加载参与者时出错：$e",
    "Failed to delete chat: $e": "删除聊天失败：$e",
    "Chat deleted": "聊天已删除",
    "Delete Chat": "删除聊天",
    "Participants": "参与者",
    "Failed to archive chat: $e": "归档聊天失败：$e",
    "Failed to restore chat: $e": "恢复聊天失败：$e",
    "New Message": "新消息",
    "Chat Settings": "聊天设置",
    "New Chat": "新聊天",
    "New Group": "新群组",
    "Show Message Previews": "显示消息预览",
    "Mute Notifications": "静音通知",
    "No messages found.": "未找到消息。",
    "No results.": "无结果。",
    "Failed to clear chat: $e": "清除聊天失败：$e",
    "Get notified about new messages": "接收新消息通知",
    "Chat history cleared": "聊天记录已清除",
    "Chat Theme": "聊天主题",
    "Select Theme": "选择主题",
    "System": "系统",
    "Initializing voice recorder...": "正在初始化语音录制器...",
    "Sending media...": "正在发送媒体...",
    "Select Wallpaper": "选择壁纸",
    "Send Broadcast Message": "发送广播消息",
    "Send Message": "发送消息",
    "Broadcast message sent successfully": "广播消息已成功发送",
    "Broadcast": "广播",
    "Messaging Dashboard": "消息仪表板",
    "Messaging Settings": "消息设置",
    "Moderation features coming soon": "审核功能即将推出",
    "No users online": "无在线用户",
    "Quiet hours": "免打扰时间",
    "Unable to start chat: User ID not found": "无法开始聊天：未找到用户ID",
    "Create Group Chat": "创建群聊",
    "Failed to create group: ${e.toString()}": "创建群组失败：${e.toString()}",
    
    # Feed Settings
    "Feed Name": "动态名称",
    "Feed settings saved!": "动态设置已保存！",
    "Edit Artist Feed": "编辑艺术家动态",
    "Feed Image (Coming soon)": "动态图片（即将推出）",
    "Posts Management (Coming soon)": "帖子管理（即将推出）",
    
    # Media & Messages
    "Failed to download media": "下载媒体失败",
    "Media saved to ${file.path}": "媒体已保存到 ${file.path}",
    "Failed to send reply": "发送回复失败",
    "No messages in this thread": "此话题中没有消息",
    "Go to message": "转到消息",
    "Message unstarred": "消息已取消星标",
    "Navigate to message in chat": "在聊天中导航到消息",
    "Starred Messages": "星标消息",
    "Remove star": "移除星标",
    "Failed to block user: $e": "阻止用户失败：$e",
    "Message": "消息",
    "Reporting functionality coming soon": "举报功能即将推出",
}

def translate_chinese():
    """Translate bracketed English text to Chinese"""
    # Load current translations
    file_path = '/Users/kristybock/artbeat/assets/translations/zh.json'
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    total_count = 0
    translated_count = 0
    
    # Count all entries
    for key, value in data.items():
        if isinstance(value, str):
            total_count += 1
    
    # Apply translations
    for key, value in data.items():
        if isinstance(value, str):
            # Check if it's a bracketed placeholder (but not [ZH] prefix)
            if value.startswith('[') and value.endswith(']') and not value.startswith('[ZH]'):
                # Extract the English text
                english_text = value[1:-1]
                
                # Check if we have a translation
                if english_text in ZH_MEGA_TRANSLATIONS_5:
                    data[key] = ZH_MEGA_TRANSLATIONS_5[english_text]
                    translated_count += 1
                    if translated_count <= 30:
                        print(f'  ✓ "{english_text[:60]}" → "{data[key][:60]}"')
    
    # Save the updated translations
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    # Count remaining bracketed entries
    remaining_count = 0
    for key, value in data.items():
        if isinstance(value, str) and value.startswith('[') and value.endswith(']') and not value.startswith('[ZH]'):
            remaining_count += 1
    
    print(f"\n{'='*60}")
    print(f"Chinese Translation - Mega Pass 5 FINAL COMPLETE")
    print(f"{'='*60}")
    print(f"Translations applied: {translated_count}")
    print(f"Remaining bracketed entries: {remaining_count}")
    print(f"Overall progress: {total_count - remaining_count}/{total_count} ({((total_count - remaining_count) / total_count * 100):.1f}%)")
    print(f"File saved: {file_path}")
    if remaining_count == 0:
        print(f"\n🎉 ALL BRACKETED ENTRIES TRANSLATED! 🎉")
    print(f"{'='*60}")

if __name__ == '__main__':
    translate_chinese()
