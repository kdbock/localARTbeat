#!/usr/bin/env python3
"""
Chinese Translation - Mega Comprehensive Pass 1
Based on Portuguese/French/Spanish translation patterns
"""

import json

ZH_MEGA_TRANSLATIONS_1 = {
    # Admin & Management
    "Take Action": "采取行动",
    "No flagged ads": "没有标记的广告",
    "No ads pending review": "没有待审核的广告",
    "No pending reports": "没有待处理的报告",
    "Failed to approve ad: {error}": "批准广告失败：{error}",
    "Failed to load ad management data: {error}": "加载广告管理数据失败：{error}",
    "Failed to reject ad: {error}": "拒绝广告失败：{error}",
    "All": "全部",
    "Flagged": "已标记",
    "Pending Review": "待审核",
    "Reports": "报告",
    "Advertisement Management": "广告管理",
    "Approved via admin dashboard": "通过管理员控制台批准",
    "Action taken by admin": "管理员已采取行动",
    "Report dismissed by admin": "管理员已驳回报告",
    'Ad "{title}" approved successfully': '广告"{title}"已成功批准',
    'Ad "{title}" rejected': '广告"{title}"已被拒绝',
    "View Details": "查看详情",
    
    # Errors
    "Error: $e": "错误：$e",
    "Error loading artwork: $e": "加载作品时出错：$e",
    "Error loading details: $e": "加载详情时出错：$e",
    
    # Common UI
    "Description": "描述",
    "Artwork status updated to $newStatus": "作品状态已更新为 $newStatus",
    "Approve": "批准",
    "Artwork deleted": "作品已删除",
    "Delete": "删除",
    "Reject": "拒绝",
    "Cancel": "取消",
    "Save": "保存",
    "Edit": "编辑",
    "Update": "更新",
    "Create": "创建",
    "Submit": "提交",
    "Close": "关闭",
    "Back": "返回",
    "Next": "下一步",
    "Previous": "上一步",
    "Continue": "继续",
    "Confirm": "确认",
    "Yes": "是",
    "No": "否",
    "OK": "确定",
    
    # Status
    "Active": "活跃",
    "Inactive": "不活跃",
    "Pending": "待处理",
    "Approved": "已批准",
    "Rejected": "已拒绝",
    "Completed": "已完成",
    "Failed": "失败",
    "Success": "成功",
    "Loading": "加载中",
    "Loading...": "加载中...",
    
    # Details & Info
    "Details": "详情",
    "Export": "导出",
    "Export Selected": "导出所选",
    "Clear Selection": "清除选择",
    "Select All": "全选",
    "Deselect All": "取消全选",
    "Filter": "筛选",
    "Sort": "排序",
    "Search": "搜索",
    "Refresh": "刷新",
    "Retry": "重试",
    "Try Again": "重试",
    
    # Payment & Transaction
    "Payment Management": "支付管理",
    "Transaction Details": "交易详情",
    "Total Transactions": "总交易数",
    "Total Refunds": "总退款数",
    "Transaction ID: ${transaction.id}": "交易ID：${transaction.id}",
    "Amount: \\${amount}": "金额：\\${amount}",
    "Payment Amount:": "支付金额：",
    "Payment ID:": "支付ID：",
    
    # Analytics & Dashboard
    "Analytics": "分析",
    "Analytics Dashboard": "分析仪表板",
    "Dashboard": "仪表板",
    "View Analytics": "查看分析",
    "View All": "查看全部",
    "Overview": "概览",
    "Statistics": "统计",
    "Chart will be implemented with fl_chart package": "图表将使用 fl_chart 包实现",
    
    # Navigation
    "Start Navigation": "开始导航",
    "Stop Navigation": "停止导航",
    "Navigation": "导航",
    "Go Back": "返回",
    "Go to Dashboard": "前往仪表板",
    
    # Art & Artists
    "Art Walks": "艺术漫步",
    "Create Art Walk": "创建艺术漫步",
    "Artist": "艺术家",
    "Artists": "艺术家",
    "Artwork": "艺术作品",
    "Artworks": "艺术作品",
    "Gallery": "画廊",
    "Galleries": "画廊",
    "Captures": "捕获",
    "My Captures": "我的捕获",
    
    # Discovery & Browse
    "Discover": "发现",
    "Browse": "浏览",
    "Explore": "探索",
    "Featured": "精选",
    "Popular": "热门",
    "Trending": "趋势",
    "Recent": "最近",
    "New": "新建",
    
    # User Management
    "User Management": "用户管理",
    "User Details": "用户详情",
    "Active Users": "活跃用户",
    "Online Users": "在线用户",
    "Peak Today": "今日高峰",
    "Edit User": "编辑用户",
    "Add User": "添加用户",
    "Remove": "移除",
    "Block User": "屏蔽用户",
    "Unblock User": "解除屏蔽用户",
    "User blocked": "用户已屏蔽",
    
    # Profile
    "Profile": "个人资料",
    "My Profile": "我的个人资料",
    "Edit Profile": "编辑个人资料",
    "View Profile": "查看个人资料",
    "Save Changes": "保存更改",
    "Profile Image": "个人资料图片",
    "Cover Image": "封面图片",
    "Change Cover Image": "更改封面图片",
    "Remove Profile Image": "移除个人资料图片",
    
    # Settings
    "Settings": "设置",
    "Admin Settings": "管理员设置",
    "General Settings": "常规设置",
    "Notification Settings": "通知设置",
    "Security Settings": "安全设置",
    "Privacy Settings": "隐私设置",
    "Content Settings": "内容设置",
    "System Settings": "系统设置",
    "Maintenance Settings": "维护设置",
    "Settings saved successfully": "设置保存成功",
    "Failed to save settings: $e": "保存设置失败：$e",
    
    # Authentication
    "Invalid password.": "密码无效。",
    "Password is required.": "密码为必填项。",
    "Email is required.": "电子邮件为必填项。",
    "Please enter your email": "请输入您的电子邮件",
    "Please enter your password": "请输入您的密码",
    
    # Content Moderation
    "Content Moderation": "内容审核",
    "Moderate": "审核",
    "Moderate art walks and manage reports": "审核艺术漫步并管理报告",
    "Moderate captures and manage reports": "审核捕获并管理报告",
    "Content Review": "内容审核",
    "Art Walk Moderation": "艺术漫步审核",
    "Capture Moderation": "捕获审核",
    
    # Notifications & Alerts
    "Notifications": "通知",
    "No recent alerts": "没有最近的警报",
    "Recent Alerts": "最近的警报",
    "Push Notifications": "推送通知",
    "Event Notifications": "活动通知",
    "Chat Notifications": "聊天通知",
    
    # Events
    "Events": "活动",
    "Create Event": "创建活动",
    "Event": "活动",
    "Event saved successfully": "活动保存成功",
    "Event Post": "活动帖子",
    "Public Event": "公共活动",
    "Event Organizer": "活动组织者",
    
    # Backup & Cache
    "Backup": "备份",
    "Backup Database": "备份数据库",
    "Backup created successfully": "备份创建成功",
    "Create a backup of the database": "创建数据库备份",
    "Clear": "清除",
    "Clear Cache": "清除缓存",
    "Clear all cached data": "清除所有缓存数据",
    "Cache cleared successfully": "缓存清除成功",
    "Are you sure you want to clear all cached data?": "确定要清除所有缓存数据吗？",
    
    # Factory Reset
    "Factory Reset": "恢复出厂设置",
    "Factory reset completed": "恢复出厂设置已完成",
    "Reset": "重置",
    "Reset Settings": "重置设置",
    "Reset All Settings": "重置所有设置",
    "Reset all settings to default values": "将所有设置重置为默认值",
    "Settings reset successfully": "设置重置成功",
    "Are you absolutely sure you want to proceed?": "您确定要继续吗？",
    "WARNING: This will delete all data": "警告：这将删除所有数据",
    "WARNING: This will delete all data and cannot be undone.": "警告：这将删除所有数据且无法撤消。",
    
    # Security & Threats
    "Security": "安全",
    "Security Center": "安全中心",
    "Security Overview": "安全概览",
    "Active Threats": "活跃威胁",
    "Threat Detection": "威胁检测",
    "Detection Settings": "检测设置",
    "Recent Security Events": "最近的安全事件",
    "Automated Threat Response": "自动威胁响应",
    "Monitor security events in real-time": "实时监控安全事件",
    "Suspicious Login Activity": "可疑登录活动",
    "Multiple failed login attempts from IP 192.168.1.100": "来自IP 192.168.1.100的多次登录失败尝试",
    "Unusual Data Access Pattern": "异常数据访问模式",
    "User accessing large amounts of user data": "用户访问大量用户数据",
    "Threat marked as resolved": "威胁已标记为已解决",
    "Severity: $severity": "严重程度：$severity",
    "User: user_${index + 1}": "用户：user_${index + 1}",
    "User Agent: Mozilla/5.0...": "用户代理：Mozilla/5.0...",
    "Role: ${roles[index]}": "角色：${roles[index]}",
    "• Monitor the IP address": "• 监控IP地址",
    "• Consider blocking if pattern continues": "• 如果模式继续，请考虑屏蔽",
    "• Review access logs": "• 查看访问日志",
}

def translate_chinese_mega_1():
    """Apply mega comprehensive Chinese translations - Pass 1"""
    
    print("=" * 70)
    print("Chinese Translation - MEGA COMPREHENSIVE PASS 1")
    print("=" * 70)
    
    with open('assets/translations/zh.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    initial_count = sum(1 for v in data.values() 
                       if isinstance(v, str) and v.startswith('[') and v.endswith(']') and not v.startswith('[ZH]'))
    
    print(f"Starting with {initial_count} bracketed entries\n")
    
    translated_count = 0
    for key, value in data.items():
        if isinstance(value, str) and value.startswith('[') and value.endswith(']') and not value.startswith('[ZH]'):
            english_text = value[1:-1]
            
            if english_text in ZH_MEGA_TRANSLATIONS_1:
                chinese_text = ZH_MEGA_TRANSLATIONS_1[english_text]
                data[key] = chinese_text
                translated_count += 1
                if translated_count <= 50:
                    print(f"✓ {english_text[:45]} → {chinese_text[:30]}")
    
    remaining_count = sum(1 for v in data.values() 
                         if isinstance(v, str) and v.startswith('[') and v.endswith(']') and not v.startswith('[ZH]'))
    
    with open('assets/translations/zh.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "=" * 70)
    print("MEGA PASS 1 SUMMARY")
    print("=" * 70)
    print(f"Translated: {translated_count}")
    print(f"Remaining: {remaining_count}")
    print(f"✓ File saved")
    
    total_entries = 1397
    completed = total_entries - remaining_count
    percentage = (completed / total_entries) * 100
    print(f"📊 Progress: {completed}/{total_entries} ({percentage:.1f}%)")
    print("=" * 70)

if __name__ == "__main__":
    translate_chinese_mega_1()
