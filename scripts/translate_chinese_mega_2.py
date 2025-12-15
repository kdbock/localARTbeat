#!/usr/bin/env python3
"""
Chinese Translation - Mega Pass 2
Continue comprehensive Chinese translations
"""

import json

ZH_MEGA_TRANSLATIONS_2 = {
    # Achievements & Bonuses
    "  ✓ Perfect completion bonus (+50 XP)": "  ✓ 完美完成奖励（+50 XP）",
    "  ✓ Photo documentation bonus (+30 XP)": "  ✓ 照片记录奖励（+30 XP）",
    "  ✓ Speed bonus (+25 XP)": "  ✓ 速度奖励（+25 XP）",
    
    # Messages & Notifications
    '"${artwork.title}" has been deleted successfully': '"${artwork.title}"已成功删除',
    "+${artist.mediums.length - 2}": "+${artist.mediums.length - 2}",
    "Achievement posted to community feed!": "成就已发布到社区动态！",
    "Art Walk created successfully!": "艺术漫步创建成功！",
    "Art Walk updated successfully!": "艺术漫步更新成功！",
    "Art walk completed! 🎉": "艺术漫步完成！🎉",
    "Art walk deleted successfully": "艺术漫步删除成功",
    "Art walk not found": "未找到艺术漫步",
    "Artist profile created successfully!": "艺术家资料创建成功！",
    "Artist profile saved successfully": "艺术家资料保存成功",
    "Artist profile not found": "未找到艺术家资料",
    "Artist removed from gallery successfully": "艺术家已从画廊移除",
    "Artwork added to art walk successfully": "作品已成功添加到艺术漫步",
    "Ad posted successfully!": "广告发布成功！",
    "Ad deleted": "广告已删除",
    
    # IP & Network
    "10.0.0.0/8": "10.0.0.0/8",
    "192.168.1.0/24": "192.168.1.0/24",
    "Add IP Range": "添加IP范围",
    "Access Control": "访问控制",
    "Access denied. Admin privileges required.": "访问被拒绝。需要管理员权限。",
    
    # Art Walk
    "Abandon": "放弃",
    "Abandon Walk": "放弃漫步",
    "Abandon Walk?": "放弃漫步？",
    "Art Walk Details": "艺术漫步详情",
    "Art Walk Map": "艺术漫步地图",
    "Art Walk Not Found": "未找到艺术漫步",
    "Already at the beginning of the route": "已到达路线起点",
    
    # Account & Profile
    "Accept & Continue": "接受并继续",
    "Account Type": "账户类型",
    "Add Artwork": "添加作品",
    "Add Payment Method": "添加支付方式",
    "Add Post": "添加帖子",
    "Add new artwork to your portfolio": "将新作品添加到您的作品集",
    "Artist Profile": "艺术家资料",
    "Artist Dashboard": "艺术家仪表板",
    "Artist: ${capture.artistName!}": "艺术家：${capture.artistName!}",
    
    # Admin
    "Admin Command Center": "管理员指挥中心",
    "Admin Dashboard": "管理员仪表板",
    "Admin Panel": "管理员面板",
    "Admin Search": "管理员搜索",
    "All admin functions in one place": "所有管理功能集中在一处",
    "ARTbeat Uadmin Module": "ARTbeat 管理员模块",
    
    # Ads
    "Ad Campaign Management": "广告活动管理",
    "Ad Content": "广告内容",
    "Ad Migration": "广告迁移",
    "Ad Performance Analytics": "广告效果分析",
    "Active Ads ({count})": "活跃广告（{count}）",
    "Artist Approved Ads": "艺术家批准的广告",
    
    # Art & Artwork
    "Art Capture": "艺术捕获",
    "Art Captured!": "艺术已捕获！",
    "Art events and spaces near you": "您附近的艺术活动和空间",
    "Artwork Management": "作品管理",
    "Artwork Post": "作品帖子",
    "Artwork Sold": "作品已售出",
    "Artwork Views": "作品浏览量",
    "Artbeat Home": "Artbeat 首页",
    
    # Capture
    "Approve Capture": "批准捕获",
    "Are you sure you want to approve this capture?": "确定要批准此捕获吗？",
    "Are you sure you want to delete this capture?": "确定要删除此捕获吗？",
    "Are you sure you want to reject this capture?": "确定要拒绝此捕获吗？",
    
    # Chat & Messages
    "Are you sure you want to delete this chat?": "确定要删除此聊天吗？",
    
    # Financial
    "Are you sure you want to process this refund?": "确定要处理此退款吗？",
    "Amount: ${transaction.formattedAmount}": "金额：${transaction.formattedAmount}",
    
    # Content Approval
    "Approving content...": "正在批准内容...",
    "Approval Status Tracking": "审批状态跟踪",
    
    # Time & Date
    "All Time": "所有时间",
    
    # Additional & Misc
    "Additional Details: Success": "其他详情：成功",
    "An unexpected error occurred: ${error}": "发生意外错误：${error}",
    "Announce upcoming events": "公布即将举行的活动",
    "Apply": "应用",
    "Apply Filters": "应用筛选",
    
    # Audit
    "Audit Log Details": "审计日志详情",
    "Audit Logs": "审计日志",
    
    # Authentication
    "Authentication failed: ${message}": "身份验证失败：${message}",
    
    # Auto features
    "Auto-delete spam": "自动删除垃圾邮件",
    "Auto-download Media": "自动下载媒体",
    "Automatically download photos and videos": "自动下载照片和视频",
    
    # More common terms
    "Add": "添加",
    "Address": "地址",
    "Amount": "金额",
    "Archive": "归档",
    "Archived": "已归档",
    "Attachment": "附件",
    "Automatically": "自动",
    
    # Business & Commission
    "Business Analytics": "业务分析",
    "Business Management": "业务管理",
    "Business Plan": "商业计划",
    "Commission": "佣金",
    "Commission Hub": "佣金中心",
    "Commission Request": "佣金请求",
    "Commission Wizard": "佣金向导",
    "Community Views": "社区浏览量",
    
    # Capture related
    "Capture approved successfully": "捕获批准成功",
    "Capture deleted permanently": "捕获已永久删除",
    "Capture deleted successfully": "捕获删除成功",
    "Capture Details": "捕获详情",
    "Capture rejected": "捕获已拒绝",
    "Capture updated successfully": "捕获更新成功",
    
    # Cancel & Clear
    "Cancel Invitation": "取消邀请",
    "Clear Chat History": "清除聊天历史",
    "Clear Filters": "清除筛选",
    "Clear Reports": "清除报告",
    "Clear Review": "清除审核",
    "Clear Search": "清除搜索",
    
    # Coupon
    "Create New Coupon": "创建新优惠券",
    "Edit Coupon": "编辑优惠券",
    "Coupon created successfully": "优惠券创建成功",
    "Coupon updated successfully": "优惠券更新成功",
    "Coupon Management": "优惠券管理",
    "Create and manage discount coupons": "创建和管理折扣优惠券",
    
    # Creator
    "Creator Plan": "创作者计划",
    
    # Dashboard & Management
    "Unified Dashboard": "统一仪表板",
    "Management Console": "管理控制台",
    "Business Management": "业务管理",
    "Content Management": "内容管理",
    
    # Dark mode
    "Dark": "深色",
    "Dark Mode": "深色模式",
    
    # Discovery
    "Discover Features": "发现功能",
    "Discover Local ARTbeat": "发现本地 ARTbeat",
    "Discover new art": "发现新艺术",
    "Discover art and artists": "发现艺术和艺术家",
    "Discover and join art communities": "发现并加入艺术社区",
    "Discover art captures near you": "发现您附近的艺术捕获",
    "Discover, Create, Connect": "发现、创建、连接",
    "Discover, create, and connect with art lovers worldwide": "发现、创建并与全球艺术爱好者联系",
    "Discover. Capture. Explore.": "发现。捕获。探索。",
    
    # Download
    "Download": "下载",
    
    # Dry Run
    "Dry Run (Preview Only)": "模拟运行（仅预览）",
    
    # Enable/Disable
    "Enable": "启用",
    "Disable": "禁用",
    
    # Error messages
    "Error": "错误",
    "Error $_error": "错误 $_error",
    
    # Export
    "Export Report": "导出报告",
    
    # Failed messages
    "Failed to approve capture": "批准捕获失败",
    "Failed to check migration status: ${error}": "检查迁移状态失败：${error}",
    "Failed to clear review: $e": "清除审核失败：$e",
    "Failed to clear reports": "清除报告失败",
    "Failed to create coupon: {error}": "创建优惠券失败：{error}",
    "Failed to delete capture": "删除捕获失败",
    "Failed to delete content: $e": "删除内容失败：$e",
    "Failed to load migration status": "加载迁移状态失败",
    "Failed to reject capture": "拒绝捕获失败",
    "Failed to update capture": "更新捕获失败",
    "Failed to update content: $e": "更新内容失败：$e",
    "Failed to update coupon: {error}": "更新优惠券失败：{error}",
}

def translate_chinese_mega_2():
    """Apply mega comprehensive Chinese translations - Pass 2"""
    
    print("=" * 70)
    print("Chinese Translation - MEGA COMPREHENSIVE PASS 2")
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
            
            if english_text in ZH_MEGA_TRANSLATIONS_2:
                chinese_text = ZH_MEGA_TRANSLATIONS_2[english_text]
                data[key] = chinese_text
                translated_count += 1
                if translated_count <= 50:
                    print(f"✓ {english_text[:45]} → {chinese_text[:30]}")
    
    remaining_count = sum(1 for v in data.values() 
                         if isinstance(v, str) and v.startswith('[') and v.endswith(']') and not v.startswith('[ZH]'))
    
    with open('assets/translations/zh.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "=" * 70)
    print("MEGA PASS 2 SUMMARY")
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
    translate_chinese_mega_2()
