#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Mega Chinese Translation Pass 4
Translates bracketed English placeholders to Chinese in zh.json
"""

import json
import re

# Comprehensive Chinese translations - Pass 4
# Covering remaining entries: content review, security, ads, art walks, navigation, achievements
ZH_MEGA_TRANSLATIONS_4 = {
    # Content Review & Moderation
    "✅ Approved: ${review.title}": "✅ 已批准：${review.title}",
    "❌ Rejected: ${review.title}": "❌ 已拒绝：${review.title}",
    "Navigation Error": "导航错误",
    "Search users, content, transactions...": "搜索用户、内容、交易...",
    "No content found": "未找到内容",
    "No transactions found": "未找到交易",
    "No users found": "未找到用户",
    "Selected content: {title}": "已选内容：{title}",
    "Selected transaction: {id}": "已选交易：{id}",
    "Type: ${content.type} • Status: ${content.status}": "类型：${content.type} • 状态：${content.status}",
    "By: ${review.authorName}": "作者：${review.authorName}",
    "Type: ${review.contentType.displayName}": "类型：${review.contentType.displayName}",
    "Content approved successfully": "内容已成功批准",
    "Content rejected successfully": "内容已成功拒绝",
    "No recent activity": "无最近活动",
    "No recent ad activity": "无最近广告活动",
    
    # Security & Logging
    "Failed login attempt blocked": "已阻止失败的登录尝试",
    "New admin user added": "已添加新管理员用户",
    "Password policy updated": "密码策略已更新",
    "Security scan completed": "安全扫描已完成",
    "Suspicious data access detected": "检测到可疑数据访问",
    "Blocked IPs": "已阻止的IP",
    "Failed Logins": "登录失败",
    "Security Score": "安全评分",
    "Error: $_error": "错误：$_error",
    
    # Ads System
    "Payout #${index + 1}": "支付 #${index + 1}",
    "Loading stats...": "加载统计中...",
    "Migrate Ads (Overwrite Existing)": "迁移广告（覆盖现有）",
    "Migrate Ads (Skip Existing)": "迁移广告（跳过现有）",
    "Migration in progress...": "迁移进行中...",
    "⚠️ Overwrite Warning": "⚠️ 覆盖警告",
    "Failed to post ad: $e": "发布广告失败：$e",
    "Failed to upload image: $e": "上传图片失败：$e",
    "Create Ad": "创建广告",
    "Promote Your Art": "推广您的艺术",
    "Reach Art Lovers": "触达艺术爱好者",
    "Image (Optional)": "图片（可选）",
    "Tap to select image": "点击选择图片",
    "Where to Display": "展示位置",
    "Select Zone": "选择区域",
    "Size and Duration": "尺寸和时长",
    "Select Size": "选择尺寸",
    "Select Duration": "选择时长",
    "Post Ad for $price": "发布广告，价格 $price",
    "Error: ${snapshot.error}": "错误：${snapshot.error}",
    'No results for "${_searchController.text}"': '未找到"${_searchController.text}"的结果',
    "Browse Ads": "浏览广告",
    "Delete Ad?": "删除广告？",
    "My Ads": "我的广告",
    "This action cannot be undone.": "此操作无法撤销。",
    "Expired Ads ({count})": "过期广告（{count}）",
    
    # Art Walks
    "Error clearing reports: $e": "清除报告时出错：$e",
    "Error deleting art walk: $e": "删除艺术漫步时出错：$e",
    "Error loading art walks: $e": "加载艺术漫步时出错：$e",
    "Reports cleared successfully": "报告已成功清除",
    "Delete Art Walk": "删除艺术漫步",
    "Reported": "已报告",
    "Error completing art walk: ${e.toString()}": "完成艺术漫步时出错：${e.toString()}",
    "Error: ${e.toString()}": "错误：${e.toString()}",
    "Error sharing: ${e.toString()}": "分享时出错：${e.toString()}",
    "Failed to start navigation: $e": "启动导航失败：$e",
    "Navigation stopped": "导航已停止",
    "The requested art walk could not be found.": "找不到请求的艺术漫步。",
    "Unable to start navigation. No art pieces found.": "无法启动导航。未找到艺术作品。",
    "You must be logged in to complete art walks": "您必须登录才能完成艺术漫步",
    "Error loading art walk: $e": "加载艺术漫步时出错：$e",
    "Error picking image: $e": "选择图片时出错：$e",
    "Error updating art walk: $e": "更新艺术漫步时出错：$e",
    "Edit Art Walk": "编辑艺术漫步",
    "Make this art walk visible to other users": "让其他用户可以看到此艺术漫步",
    "Public Art Walk": "公共艺术漫步",
    "This artwork is already in your art walk": "此作品已在您的艺术漫步中",
    "Search Art Walks": "搜索艺术漫步",
    "Clear All": "清除全部",
    "Load More Art Walks": "加载更多艺术漫步",
    "Select difficulty": "选择难度",
    "Select sorting": "选择排序",
    
    # Achievements & Progress
    "Failed to post achievement: $e": "发布成就失败：$e",
    "Explore More": "探索更多",
    "Share Achievement": "分享成就",
    "You earned new achievements!": "您获得了新成就！",
    "Level up your art journey!": "提升您的艺术之旅！",
    "Review Your Art Walk": "查看您的艺术漫步",
    "View Quest History": "查看任务历史",
    
    # Discovery & Browse
    "Error loading nearby art: $e": "加载附近艺术时出错：$e",
    "Browse Artwork": "浏览作品",
    "Discover local and featured artists": "发现本地和精选艺术家",
    "Explore art collections and galleries": "探索艺术收藏和画廊",
    "Find Artists": "查找艺术家",
    "Getting your location...": "正在获取您的位置...",
    "Local Scene": "本地场景",
    "No art nearby. Try moving to a different location!": "附近没有艺术品。尝试移动到其他位置！",
    "Popular artists and trending art": "热门艺术家和流行艺术",
    "View and edit your profile": "查看和编辑您的个人资料",
    "Your Location": "您的位置",
    "No captures found nearby": "附近未找到捕获",
    "Error capturing selfie: $e": "拍摄自拍时出错：$e",
    "Error starting art walk: $e": "启动艺术漫步时出错：$e",
    
    # Common UI Elements
    "SCREEN_TITLE": "屏幕标题",
    "Loading...": "加载中...",
    "Error": "错误",
    "Success": "成功",
    "Failed": "失败",
    "Retry": "重试",
    "Try Again": "重试",
    "Go Back": "返回",
    "Not Found": "未找到",
    "Something went wrong": "出了点问题",
    "Please try again": "请重试",
    "Unknown error": "未知错误",
    
    # Messages & Prompts
    "Are you sure?": "确定吗？",
    "This cannot be undone": "这无法撤销",
    "Confirm action": "确认操作",
    "Success!": "成功！",
    "Failed!": "失败！",
    "Warning": "警告",
    "Notice": "通知",
    "Alert": "提醒",
    
    # Actions
    "View Details": "查看详情",
    "View All": "查看全部",
    "See More": "查看更多",
    "Show Less": "收起",
    "Expand": "展开",
    "Collapse": "收起",
    "Select": "选择",
    "Deselect": "取消选择",
    "Choose": "选择",
    "Pick": "挑选",
    "Browse": "浏览",
    "Open": "打开",
    "Start": "开始",
    "Stop": "停止",
    "Pause": "暂停",
    "Resume": "继续",
    "Restart": "重新开始",
    "Exit": "退出",
    "Leave": "离开",
    "Join": "加入",
    "Follow": "关注",
    "Unfollow": "取消关注",
    "Like": "喜欢",
    "Unlike": "取消喜欢",
    "Favorite": "收藏",
    "Unfavorite": "取消收藏",
    "Bookmark": "书签",
    "Report": "报告",
    "Block": "阻止",
    "Unblock": "取消阻止",
    "Mute": "静音",
    "Unmute": "取消静音",
    "Hide": "隐藏",
    "Show": "显示",
    "Enable": "启用",
    "Disable": "禁用",
    "Activate": "激活",
    "Deactivate": "停用",
    "Lock": "锁定",
    "Unlock": "解锁",
    "Archive": "归档",
    "Unarchive": "取消归档",
    "Restore": "恢复",
    "Duplicate": "复制",
    "Move": "移动",
    "Rename": "重命名",
    "Add": "添加",
    "Remove": "移除",
    "Create": "创建",
    "Update": "更新",
    "Modify": "修改",
    "Change": "更改",
    "Replace": "替换",
    "Insert": "插入",
    "Append": "追加",
    "Prepend": "前置",
    "Merge": "合并",
    "Split": "拆分",
    "Combine": "组合",
    "Separate": "分离",
    "Group": "分组",
    "Ungroup": "取消分组",
    "Link": "链接",
    "Unlink": "取消链接",
    "Connect": "连接",
    "Disconnect": "断开连接",
    "Attach": "附加",
    "Detach": "分离",
    "Pin": "固定",
    "Unpin": "取消固定",
    "Mark": "标记",
    "Unmark": "取消标记",
    "Tag": "标签",
    "Untag": "取消标签",
    "Rate": "评分",
    "Review": "审核",
    "Comment": "评论",
    "Reply": "回复",
    "Forward": "转发",
    "Send": "发送",
    "Receive": "接收",
    "Request": "请求",
    "Accept": "接受",
    "Decline": "拒绝",
    "Approve": "批准",
    "Reject": "拒绝",
    "Allow": "允许",
    "Deny": "拒绝",
    "Grant": "授予",
    "Revoke": "撤销",
    "Invite": "邀请",
    "Subscribe": "订阅",
    "Unsubscribe": "取消订阅",
    "Upgrade": "升级",
    "Downgrade": "降级",
    "Purchase": "购买",
    "Buy": "购买",
    "Sell": "出售",
    "Pay": "支付",
    "Refund": "退款",
    "Charge": "收费",
    "Credit": "信用",
    "Debit": "借记",
    "Transfer": "转账",
    "Withdraw": "提取",
    "Deposit": "存入",
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
                if english_text in ZH_MEGA_TRANSLATIONS_4:
                    data[key] = ZH_MEGA_TRANSLATIONS_4[english_text]
                    translated_count += 1
                    if translated_count <= 20:
                        print(f'  ✓ "{english_text}" → "{data[key]}"')
    
    # Save the updated translations
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    # Count remaining bracketed entries
    remaining_count = 0
    for key, value in data.items():
        if isinstance(value, str) and value.startswith('[') and value.endswith(']') and not value.startswith('[ZH]'):
            remaining_count += 1
    
    print(f"\n{'='*60}")
    print(f"Chinese Translation - Mega Pass 4 Complete")
    print(f"{'='*60}")
    print(f"Translations applied: {translated_count}")
    print(f"Remaining bracketed entries: {remaining_count}")
    print(f"Overall progress: {total_count - remaining_count}/{total_count} ({((total_count - remaining_count) / total_count * 100):.1f}%)")
    print(f"File saved: {file_path}")
    print(f"{'='*60}")

if __name__ == '__main__':
    translate_chinese()
