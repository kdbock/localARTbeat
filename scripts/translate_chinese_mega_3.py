#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Mega Chinese Translation Pass 3
Translates bracketed English placeholders to Chinese in zh.json
"""

import json
import re

# Comprehensive Chinese translations - Pass 3
# Covering remaining entries: artwork, comments, users, transactions, settings, monitoring, profiles, auth, migration
ZH_MEGA_TRANSLATIONS_3 = {
    # Artwork & Comments
    "Comment deleted": "评论已删除",
    "Delete Artwork": "删除作品",
    "Delete Comment": "删除评论",
    "Flag": "举报",
    "No artwork found": "未找到作品",
    "Reject Artwork": "拒绝作品",
    "Select artwork to view details": "选择作品以查看详情",
    "Title": "标题",
    
    # Authentication & Login
    "Login": "登录",
    "Invalid email address.": "电子邮件地址无效。",
    "This account has been disabled.": "此账户已被禁用。",
    "No user found with this email.": "未找到使用此电子邮件的用户。",
    "Please enter a valid email": "请输入有效的电子邮件",
    "Password must be at least 6 characters": "密码至少需要6个字符",
    
    # Transactions & Financial
    "Click below to copy CSV content:": "点击下方复制CSV内容：",
    "Mark as Failed": "标记为失败",
    "Download $fileName": "下载 $fileName",
    "User: ${transaction.userName}": "用户：${transaction.userName}",
    "Description: ${transaction.description}": "描述：${transaction.description}",
    "Avg Transaction": "平均交易",
    "Bulk Refund": "批量退款",
    "Clear All Filters": "清除所有筛选",
    "Copy to Clipboard": "复制到剪贴板",
    "CSV content copied to clipboard": "CSV内容已复制到剪贴板",
    "Date Range": "日期范围",
    "\\$${entry.value.toStringAsFixed(2)}": "\\$${entry.value.toStringAsFixed(2)}",
    "Mark as Completed": "标记为已完成",
    "Mark as Pending": "标记为待处理",
    "Payment Method: ${transaction.paymentMethod}": "支付方式：${transaction.paymentMethod}",
    "Process Bulk Refunds": "处理批量退款",
    "Process Refund": "处理退款",
    "Total Revenue": "总收入",
    "Transaction: ${transaction.id}": "交易：${transaction.id}",
    "Update Status": "更新状态",
    "Item: ${transaction.itemTitle}": "项目：${transaction.itemTitle}",
    "Transaction & refund management": "交易和退款管理",
    
    # Security & Monitoring
    "Email Alerts": "电子邮件提醒",
    "Send email notifications for threats": "发送威胁电子邮件通知",
    "Automatically block suspicious activity": "自动阻止可疑活动",
    "Disable Account": "禁用账户",
    "Edit Permissions": "编辑权限",
    "IP Address: 192.168.1.${100 + index}": "IP地址：192.168.1.${100 + index}",
    "IP range added to whitelist": "IP范围已添加到白名单",
    "Log ID: LOG_${1000 + index}": "日志ID：LOG_${1000 + index}",
    "Office Network": "办公网络",
    "Real-time Monitoring": "实时监控",
    "Recommended Actions:": "建议操作：",
    "Remove Admin": "移除管理员",
    "Resolve": "解决",
    "VPN Network": "VPN网络",
    "Danger Zone": "危险区域",
    
    # System Settings & Monitoring
    "No settings available": "无可用设置",
    "User Settings": "用户设置",
    "Error loading system data: $e": "加载系统数据时出错：$e",
    "Avg Session": "平均会话",
    "CPU Usage": "CPU使用率",
    "Critical Alerts": "关键警报",
    "Memory Usage": "内存使用率",
    "No system alerts": "无系统警报",
    "Response Time": "响应时间",
    "System Monitoring": "系统监控",
    "Warning Alerts": "警告提醒",
    
    # User Profiles
    "Failed to remove profile image: $e": "移除个人资料图片失败：$e",
    "Failed to update profile: $e": "更新个人资料失败：$e",
    "Failed to update featured status: $e": "更新精选状态失败：$e",
    "Failed to update user type: $e": "更新用户类型失败：$e",
    "Failed to update verification status: $e": "更新验证状态失败：$e",
    "Profile image removed successfully": "个人资料图片已成功移除",
    "User profile updated successfully": "用户个人资料已成功更新",
    "User type updated to ${newType.name}": "用户类型已更新为 ${newType.name}",
    "By: ${_currentUser.suspendedBy}": "操作者：${_currentUser.suspendedBy}",
    "Reason: ${_currentUser.suspensionReason}": "原因：${_currentUser.suspensionReason}",
    "Verified": "已验证",
    
    # Navigation & Development
    "Return to main app": "返回主应用",
    "Edit this file to add navigation buttons to module screens": "编辑此文件以向模块屏幕添加导航按钮",
    "Standalone development environment": "独立开发环境",
    "Uadmin Module Demo": "Uadmin模块演示",
    "Example Button": "示例按钮",
    
    # Migration & Data
    "This will add geo fields (geohash and geopoint) to all captures\n with locations. This is required for instant discovery to show user captures. Continue?": "这将向所有带有位置的捕获添加地理字段（geohash和地理点）。\n这是即时发现功能显示用户捕获所必需的。继续？",
    "Migrate Geo Fields": "迁移地理字段",
    "This will remove the new moderation status fields from all collections. This action cannot be undone. Continue?": "这将从所有集合中删除新的审核状态字段。此操作无法撤销。继续？",
    "Rollback Migration": "回滚迁移",
    "This will add standardized moderation status fields to all content collections. This operation cannot be undone easily. Continue?": "这将向所有内容集合添加标准化的审核状态字段。此操作不易撤销。继续？",
    "Run Migration": "运行迁移",
    "Migration failed: ${error}": "迁移失败：${error}",
    "Geo field migration failed: ${error}": "地理字段迁移失败：${error}",
    "Rollback failed: ${error}": "回滚失败：${error}",
    "Moderation Status Migration": "审核状态迁移",
    "Migration completed successfully!": "迁移已成功完成！",
    "Geo field migration completed successfully!": "地理字段迁移已成功完成！",
    "Rollback completed successfully!": "回滚已成功完成！",
    "Data Migration": "数据迁移",
    "Migrate Geo Fields for Captures": "为捕获迁移地理字段",
    "Rollback": "回滚",
    "Refresh Status": "刷新状态",
    
    # Content Moderation
    "❌ Failed to approve content: $e": "❌ 批准内容失败：$e",
    "❌ Failed to reject content: $e": "❌ 拒绝内容失败：$e",
    'Deleted "${content.title}" successfully': '已成功删除"${content.title}"',
    'Updated "${newTitle}" successfully': '已成功更新"${newTitle}"',
    "Rejecting content...": "正在拒绝内容...",
    
    # Additional Common Terms
    "Loading...": "加载中...",
    "Cancel": "取消",
    "Confirm": "确认",
    "Save": "保存",
    "Delete": "删除",
    "Edit": "编辑",
    "View": "查看",
    "Close": "关闭",
    "Submit": "提交",
    "Search": "搜索",
    "Filter": "筛选",
    "Sort": "排序",
    "Export": "导出",
    "Import": "导入",
    "Download": "下载",
    "Upload": "上传",
    "Share": "分享",
    "Copy": "复制",
    "Paste": "粘贴",
    "Cut": "剪切",
    "Undo": "撤销",
    "Redo": "重做",
    "Select All": "全选",
    "Deselect": "取消选择",
    "Refresh": "刷新",
    "Reload": "重新加载",
    "Back": "返回",
    "Next": "下一步",
    "Previous": "上一步",
    "Finish": "完成",
    "Skip": "跳过",
    "Continue": "继续",
    "Yes": "是",
    "No": "否",
    "OK": "确定",
    "Apply": "应用",
    "Reset": "重置",
    "Clear": "清除",
    "All": "全部",
    "None": "无",
    "Selected": "已选",
    "Total": "总计",
    "Count": "计数",
    "Name": "名称",
    "Description": "描述",
    "Type": "类型",
    "Status": "状态",
    "Date": "日期",
    "Time": "时间",
    "Author": "作者",
    "Owner": "所有者",
    "Creator": "创建者",
    "Modified": "已修改",
    "Created": "已创建",
    "Updated": "已更新",
    "Deleted": "已删除",
    "Active": "活跃",
    "Inactive": "不活跃",
    "Enabled": "已启用",
    "Disabled": "已禁用",
    "Public": "公开",
    "Private": "私有",
    "Draft": "草稿",
    "Published": "已发布",
    "Archived": "已归档",
    "Pending": "待处理",
    "Approved": "已批准",
    "Rejected": "已拒绝",
    "Completed": "已完成",
    "Failed": "失败",
    "Success": "成功",
    "Error": "错误",
    "Warning": "警告",
    "Info": "信息",
    "Details": "详情",
    "Settings": "设置",
    "Preferences": "偏好设置",
    "Options": "选项",
    "Help": "帮助",
    "About": "关于",
    "Version": "版本",
    "Language": "语言",
    "Theme": "主题",
    "Light": "浅色",
    "Dark": "深色",
    "Auto": "自动",
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
                if english_text in ZH_MEGA_TRANSLATIONS_3:
                    data[key] = ZH_MEGA_TRANSLATIONS_3[english_text]
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
    print(f"Chinese Translation - Mega Pass 3 Complete")
    print(f"{'='*60}")
    print(f"Translations applied: {translated_count}")
    print(f"Remaining bracketed entries: {remaining_count}")
    print(f"Overall progress: {total_count - remaining_count}/{total_count} ({((total_count - remaining_count) / total_count * 100):.1f}%)")
    print(f"File saved: {file_path}")
    print(f"{'='*60}")

if __name__ == '__main__':
    translate_chinese()
