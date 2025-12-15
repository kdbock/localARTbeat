#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Remove [ZH] Prefixes and Translate to Chinese
Processes all entries with [ZH] prefix in zh.json
"""

import json
import re

# Chinese translations for [ZH] prefix entries
ZH_PREFIX_TRANSLATIONS = {
    # Admin Dashboard & Analytics
    "Active Users": "活跃用户",
    "All systems operational": "所有系统正常运行",
    "Analytics": "分析",
    "API": "API",
    "Artists": "艺术家",
    "Artworks": "作品",
    "Business Analytics": "业务分析",
    "Configure App": "配置应用",
    "Content Moderation": "内容审核",
    "Database": "数据库",
    "Detailed Insights": "详细见解",
    "Key Metrics": "关键指标",
    "Manage Users": "管理用户",
    "Management Actions": "管理操作",
    "Monitoring": "监控",
    "Monthly Performance": "每月表现",
    "Normal": "正常",
    "Online": "在线",
    "Pending": "待处理",
    "Pending Reviews": "待审核",
    "Pending Verification": "待验证",
    "Recent Alerts": "最近警报",
    "Reports": "报告",
    "Revenue": "收入",
    "Revenue Growth": "收入增长",
    "Review Reports": "审核报告",
    "Server Load": "服务器负载",
    "Servers": "服务器",
    "Storage": "存储",
    "Storage capacity reaching maximum": "存储容量接近上限",
    "System Health": "系统健康",
    "Total": "总计",
    "Total Revenue": "总收入",
    "Total Users": "总用户数",
    "Trending": "趋势",
    "Users": "用户",
    "Verified": "已验证",
    "Warning": "警告",
    
    # Performance & Metrics
    "Average Response Time": "平均响应时间",
    "CPU Usage": "CPU使用率",
    "Daily Active Users": "每日活跃用户",
    "Error Rate": "错误率",
    "Memory Usage": "内存使用率",
    "Monthly Active Users": "每月活跃用户",
    "Network Traffic": "网络流量",
    "Peak Hours": "高峰时段",
    "Performance": "性能",
    "Request Rate": "请求速率",
    "Success Rate": "成功率",
    "Uptime": "正常运行时间",
    
    # Content & Management
    "Approved": "已批准",
    "Banned": "已封禁",
    "Categories": "类别",
    "Comments": "评论",
    "Deleted": "已删除",
    "Draft": "草稿",
    "Featured": "精选",
    "Flagged": "已举报",
    "Hidden": "已隐藏",
    "Published": "已发布",
    "Rejected": "已拒绝",
    "Removed": "已移除",
    "Suspended": "已暂停",
    
    # Actions & Operations
    "Backup": "备份",
    "Configure": "配置",
    "Deploy": "部署",
    "Export": "导出",
    "Import": "导入",
    "Migrate": "迁移",
    "Optimize": "优化",
    "Restore": "恢复",
    "Sync": "同步",
    "Update": "更新",
    "Upgrade": "升级",
    "Validate": "验证",
    
    # Status & States
    "Active": "活跃",
    "Archived": "已归档",
    "Completed": "已完成",
    "Failed": "失败",
    "Inactive": "不活跃",
    "In Progress": "进行中",
    "Processing": "处理中",
    "Queued": "已排队",
    "Running": "运行中",
    "Scheduled": "已安排",
    "Stopped": "已停止",
    "Success": "成功",
    
    # Security & Access
    "Access Control": "访问控制",
    "Admin": "管理员",
    "Authentication": "身份验证",
    "Authorization": "授权",
    "Firewall": "防火墙",
    "Permissions": "权限",
    "Privacy": "隐私",
    "Security": "安全",
    "SSL": "SSL",
    "Token": "令牌",
    "Two-Factor Authentication": "双因素身份验证",
    
    # Notifications & Communication
    "Alerts": "提醒",
    "Email": "电子邮件",
    "Messages": "消息",
    "Notifications": "通知",
    "Push Notifications": "推送通知",
    "SMS": "短信",
    
    # Time & Scheduling
    "Daily": "每日",
    "Hourly": "每小时",
    "Monthly": "每月",
    "Real-time": "实时",
    "Weekly": "每周",
    "Yearly": "每年",
    
    # General Terms
    "Dashboard": "仪表板",
    "Overview": "概览",
    "Settings": "设置",
    "Statistics": "统计",
    "Summary": "摘要",
    "Details": "详情",
    "History": "历史",
    "Logs": "日志",
    "Audit": "审计",
    "Activity": "活动",
    "Events": "事件",
    "Tasks": "任务",
    "Queue": "队列",
    "Cache": "缓存",
    "Session": "会话",
    "Version": "版本",
    "License": "许可证",
    "Documentation": "文档",
    "Support": "支持",
    "Feedback": "反馈",
    "Help": "帮助",
    "About": "关于",
    "Contact": "联系",
    "Terms": "条款",
    "Policy": "政策",
    "Legal": "法律",
}

def remove_zh_prefixes():
    """Remove [ZH] prefixes and translate to Chinese"""
    # Load current translations
    file_path = '/Users/kristybock/artbeat/assets/translations/zh.json'
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    translated_count = 0
    not_found = []
    
    # Process [ZH] prefixes
    for key, value in data.items():
        if isinstance(value, str) and value.startswith('[ZH]'):
            # Extract the English text (remove '[ZH] ')
            english_text = value[4:].strip()
            
            # Check if we have a translation
            if english_text in ZH_PREFIX_TRANSLATIONS:
                data[key] = ZH_PREFIX_TRANSLATIONS[english_text]
                translated_count += 1
                if translated_count <= 20:
                    print(f'  ✓ "{english_text}" → "{data[key]}"')
            else:
                not_found.append(english_text)
    
    # Save the updated translations
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    # Count remaining [ZH] prefixes
    remaining_count = 0
    for key, value in data.items():
        if isinstance(value, str) and value.startswith('[ZH]'):
            remaining_count += 1
    
    print(f"\n{'='*60}")
    print(f"Chinese [ZH] Prefix Removal - Pass 1")
    print(f"{'='*60}")
    print(f"Translated: {translated_count}")
    print(f"Remaining [ZH] prefixes: {remaining_count}")
    if not_found:
        print(f"\nNot found in dictionary ({len(not_found)} unique):")
        unique_not_found = list(dict.fromkeys(not_found))
        for i, text in enumerate(unique_not_found[:20], 1):
            print(f"  {i}. {text}")
    print(f"\nFile saved: {file_path}")
    print(f"{'='*60}")

if __name__ == '__main__':
    remove_zh_prefixes()
