#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Remove [ZH] Prefixes - Pass 2 FINAL
Translates all remaining [ZH] prefix entries to Chinese
"""

import json

# Chinese translations for remaining [ZH] prefix entries
ZH_PREFIX_TRANSLATIONS_2 = {
    # System & Admin
    "Storage Warning": "存储警告",
    "System Overview": "系统概览",
    "System Settings": "系统设置",
    "System Status": "系统状态",
    "User Management": "用户管理",
    "View All": "查看全部",
    "Welcome back, Admin": "欢迎回来，管理员",
    
    # Onboarding & Welcome
    "Loading dashboard...": "正在加载仪表板...",
    "Preparing your personalized experience": "正在准备您的个性化体验",
    "Add bio and profile photo": "添加个人简介和照片",
    "Art Walks": "艺术漫步",
    "Follow guided art experiences and discover hidden gems": "跟随引导的艺术体验，发现隐藏的宝藏",
    "{count} artists online": "{count} 位艺术家在线",
    "Begin your artistic journey today": "今天开始您的艺术之旅",
    "Capture a beautiful moment": "捕捉美好时刻",
    "Captures": "捕获",
    "Share your artistic perspective with photo captures": "通过照片捕获分享您的艺术视角",
    "Community": "社区",
    "Connect with artists and art lovers worldwide": "与全球艺术家和艺术爱好者联系",
    "Connect with thousands of artists and art enthusiasts": "与数千名艺术家和艺术爱好者联系",
    "Complete Your Profile": "完善您的个人资料",
    "Connect with fellow artists": "与艺术家同仁联系",
    "Browse, commission, and collect from local artists. Support creativity by gifting promo credits that help artists shine.": "浏览、委托和收藏本地艺术家的作品。通过赠送促销积分支持创意，帮助艺术家大放异彩。",
    "Connect with Artists": "与艺术家联系",
    "Continue": "继续",
    "Share your art, spark conversations, and connect through a creative feed. Chat 1-on-1 or in groups—where inspiration meets community.": "分享您的艺术，激发对话，通过创意动态联系。一对一或群组聊天——灵感与社区的交汇处。",
    "Create & Share": "创作与分享",
    "Discover, Create, Connect": "发现、创作、联系",
    "Discover Features": "发现功能",
    "Turn every mural into a mission—complete quests, earn badges, and level up your art adventure.": "将每一幅壁画变成任务——完成任务，赢得徽章，提升您的艺术冒险。",
    "Explore art nearby": "探索附近的艺术",
    "Discover. Capture. Explore.": "发现。捕获。探索。",
    "Find Friends": "寻找朋友",
    "Get Started": "开始",
    "Join the Community": "加入社区",
    "members joined": "位成员已加入",
    "Add your bio, photo, and preferences to get started": "添加您的简介、照片和偏好以开始",
    "Quick Setup": "快速设置",
    "Ready to Start?": "准备开始了吗？",
    "Let's get you set up": "让我们为您设置",
    "Start an Art Walk": "开始艺术漫步",
    "Step {step} of {total}": "第 {step} 步，共 {total} 步",
    "Take Your First Photo": "拍摄您的第一张照片",
    "Discover, create, and connect with art lovers worldwide": "发现、创作并与全球艺术爱好者联系",
    "Welcome to Artbeat": "欢迎来到Artbeat",
    "Welcome to Local ARTbeat": "欢迎来到本地ARTbeat",
    "Welcome, {username}!": "欢迎，{username}！",
    "Your Journey": "您的旅程",
    
    # Dashboard & Navigation
    "Achievements": "成就",
    "Browse": "浏览",
    "Community Feed": "社区动态",
    "completed": "已完成",
    "Connect artists": "联系艺术家",
    "Connect with artists": "与艺术家联系",
    "Daily Challenge": "每日挑战",
    "Discover Local ARTbeat": "发现本地ARTbeat",
    "Explore beautiful artworks from Local ARTbeat talented artists around you": "探索您周围本地ARTbeat才华横溢的艺术家的精美作品",
    "Discover new art": "发现新艺术",
    "Explore More": "探索更多",
    "Explore nearby": "探索附近",
    "Find art": "寻找艺术",
    "Join Conversation": "加入对话",
    "Join events": "加入活动",
    "Level": "级别",
    "Loading...": "加载中...",
    "Nearby Art Walks": "附近的艺术漫步",
    "Quick Actions": "快速操作",
    "Ready to explore some art?": "准备探索一些艺术吗？",
    "Recent Captures": "最近的捕获",
    "Start Capturing": "开始捕获",
    "Walks": "漫步",
    "Welcome, {0}!": "欢迎，{0}！",
    "Your Progress": "您的进度",
}

def remove_zh_prefixes_final():
    """Remove remaining [ZH] prefixes and translate to Chinese"""
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
            if english_text in ZH_PREFIX_TRANSLATIONS_2:
                data[key] = ZH_PREFIX_TRANSLATIONS_2[english_text]
                translated_count += 1
                if translated_count <= 20:
                    print(f'  ✓ "{english_text[:50]}" → "{data[key][:50]}"')
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
    print(f"Chinese [ZH] Prefix Removal - Pass 2 FINAL")
    print(f"{'='*60}")
    print(f"Translated: {translated_count}")
    print(f"Remaining [ZH] prefixes: {remaining_count}")
    if not_found:
        print(f"\nNot found in dictionary ({len(not_found)} unique):")
        unique_not_found = list(dict.fromkeys(not_found))
        for i, text in enumerate(unique_not_found, 1):
            print(f"  {i}. {text}")
    if remaining_count == 0:
        print(f"\n🎉 ALL [ZH] PREFIXES REMOVED! 🎉")
    print(f"\nFile saved: {file_path}")
    print(f"{'='*60}")

if __name__ == '__main__':
    remove_zh_prefixes_final()
