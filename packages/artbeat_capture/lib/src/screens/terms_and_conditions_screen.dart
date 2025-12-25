import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

/// Terms and Conditions Screen
class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07060F), // World background base
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // World background with blobs
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF07060F),
                  Color(0xFF0A1330),
                  Color(0xFF071C18),
                ],
              ),
            ),
          ),
          // Blobs (simplified)
          Positioned(
            top: 100,
            left: 50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF22D3EE).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            right: 50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C4DFF).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Vignette
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Colors.transparent,
                  const Color(0xFF07060F).withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📄 TERMS OF SERVICE (DRAFT TEMPLATE)',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSection('1. Introduction', '''
Welcome to Local ARTbeat ("we", "our", "us"). These Terms of Service ("Terms") govern your access to and use of our mobile app, website, and related services (collectively, the "Service").

By creating an account, accessing, or using the Service, you agree to be bound by these Terms. If you do not agree, you may not use the Service.

You must be at least 13 years old (or the minimum age required in your country) to use Local ARTbeat.
'''),
                        _buildSection('2. Your Account', '''
You are responsible for:

keeping your login credentials secure

any activity on your account

providing accurate information

We may suspend or terminate accounts that:

violate these Terms

attempt to misuse or disrupt the Service

create risk or legal exposure for us or others
'''),
                        _buildSection('3. Content You Share', '''
Local ARTbeat allows users to upload photos, descriptions, comments, and other content ("User Content").

You retain ownership of your content.

By posting, you grant Local ARTbeat a worldwide, non‑exclusive, royalty‑free license to:

host

store

display

reproduce

share

distribute

modify (for formatting or display)

solely for operating and improving the Service.

You confirm that:

you own the content, OR you have permission to share it

your content does not violate copyright, privacy, trademark, or other rights

your content complies with our Community Guidelines

We may remove or restrict content that violates these Terms or the law.
'''),
                        _buildSection('4. Prohibited Activities', '''
You agree NOT to:

post illegal, abusive, hateful, or sexually explicit content

upload others' private information without consent

impersonate another person or entity

attempt to hack, scrape, reverse engineer, or disrupt the Service

use Local ARTbeat for harassment, spam, or scams

upload malware, bots, or automated scripts
'''),
                        _buildSection('5. Intellectual Property', '''
All parts of the Service — including logos, branding, designs, code, and features — are owned by Local ARTbeat or licensed to us.

You may not copy, modify, sell, or distribute our platform or branding without permission.
'''),
                        _buildSection('6. Location & Mapping Features', '''
Local ARTbeat may display art locations, user‑submitted map pins, routes, or walk paths.

We do not guarantee accuracy. You are responsible for your own safety when exploring.

Do not trespass, enter dangerous areas, or violate local laws.
'''),
                        _buildSection(
                          '7. Disclaimer & Limitation of Liability',
                          '''
The Service is provided "as‑is" without warranties of any kind.

Local ARTbeat is not responsible for:

user‑generated content

loss of data

personal injury or damages

availability or accuracy of third‑party links or maps

To the fullest extent permitted by law, our liability is limited to the amount paid to us (if any) over the last 12 months.
''',
                        ),
                        _buildSection('8. Termination', '''
We may suspend or terminate your account at any time if:

you violate these Terms

we believe your actions create risk or legal liability

You may stop using the Service at any time.
'''),
                        _buildSection('9. Changes to These Terms', '''
We may update these Terms from time to time. Continued use constitutes acceptance.
'''),
                        _buildSection('10. Contact Us', '''
If you have questions about these Terms, contact:

support@localartbeat.com
 (replace with your real address)
'''),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🔐 PRIVACY POLICY (DRAFT TEMPLATE)',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSection('1. Information We Collect', '''
We collect:

Information you provide:

name, username, email

profile info and preferences

photos and posts

comments, likes, favorites

Automatically collected:

device + OS information

app usage analytics

IP address and general location (approx., not precise unless granted)

crash logs

Optional:

precise GPS location only if you allow it

camera + photos access only if you allow it

We do not sell personal information.
'''),
                        _buildSection('2. How We Use Information', '''
We use data to:

operate and improve the Service

personalize your experience

recommend content and walks

moderate harmful content and abuse

respond to support requests

comply with legal obligations
'''),
                        _buildSection('3. Sharing Your Information', '''
We may share limited data with:

service providers (hosting, analytics, authentication)

law enforcement when legally required

other users (for content you choose to share publicly)

We never sell personal information.
'''),
                        _buildSection('4. Cookies & Analytics', '''
We may use cookies and analytics tools to improve functionality and performance.

You can control cookie preferences in your device settings.
'''),
                        _buildSection('5. Data Retention', '''
We retain information as long as needed to provide the Service or comply with law.

You may request account deletion at any time.
'''),
                        _buildSection('6. Your Rights', '''
Depending on your location, you may:

access your data

correct inaccurate info

delete your account

withdraw consent to certain processing

Contact us to make a request.
'''),
                        _buildSection('7. Security', '''
We use reasonable technical and organizational safeguards, but no system is 100% secure.
'''),
                        _buildSection('8. Children', '''
We do not knowingly collect data from children under 13 (or local minimum age).
'''),
                        _buildSection('9. Changes to This Policy', '''
We may update this policy occasionally. Continued use means acceptance.
'''),
                        _buildSection('10. Contact', '''
privacy@localartbeat.com
 (replace with real)
'''),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🌱 COMMUNITY GUIDELINES',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSection('', '''
Local ARTbeat exists to celebrate creativity and public art.

To keep it safe and welcoming:

Be respectful

Do not harass, bully, threaten, or shame others.

Credit artists

Whenever possible, credit artists and creators.

Share responsibly

Do not post:

hateful or violent content

sexual content involving minors

illegal activity

copyrighted work without permission

private info or faces where consent is required

trespassing or dangerous behavior

Keep locations safe

Avoid publishing sensitive locations that may cause damage, vandalism, or crowding.

Report problems

Use reporting tools to flag harmful content.
'''),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        const SizedBox(height: 8),
        Text(
          content.trim(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.8),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
