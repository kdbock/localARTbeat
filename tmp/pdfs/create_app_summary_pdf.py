#!/usr/bin/env python3
from pathlib import Path
import textwrap

OUT = Path('output/pdf/artbeat_app_summary_one_page.pdf')

PAGE_W = 612
PAGE_H = 792
MARGIN = 54
CONTENT_W = PAGE_W - (2 * MARGIN)


def esc(text: str) -> str:
    return text.replace('\\', '\\\\').replace('(', '\\(').replace(')', '\\)')


def add_wrapped(lines, y, text, font='F1', size=10, leading=13, indent=0, bullet=False):
    # Approximate chars per line for Helvetica/Courier at this width
    max_chars = max(30, int((CONTENT_W - indent) / (size * 0.56)))
    wraps = textwrap.wrap(text, width=max_chars)
    if not wraps:
        return y

    for i, w in enumerate(wraps):
        prefix = '- ' if bullet and i == 0 else ('  ' if bullet else '')
        line = f"{prefix}{w}"
        x = MARGIN + indent
        lines.append((font, size, x, y, line))
        y -= leading
    return y


def build_lines():
    y = PAGE_H - MARGIN
    lines = []

    lines.append(('F2', 18, MARGIN, y, 'ARTbeat App Summary (Repo-Evidenced)'))
    y -= 24
    lines.append(('F1', 9, MARGIN, y, 'Evidence basis: README.md, pubspec.yaml, lib/main.dart, lib/app.dart, lib/src/routing/app_router.dart, firebase.json, functions/src/index.js'))
    y -= 18

    lines.append(('F2', 12, MARGIN, y, 'What It Is'))
    y -= 14
    y = add_wrapped(lines, y, 'ARTbeat is a modular Flutter app for artists, galleries, and art lovers. It combines discovery, social/community tools, capture, messaging, events, art walks, and admin workflows in one cross-platform app backed by Firebase services.', size=10)
    y -= 6

    lines.append(('F2', 12, MARGIN, y, 'Who It Is For'))
    y -= 14
    y = add_wrapped(lines, y, 'Primary persona: artists (with adjacent personas: galleries/institutions and art enthusiasts).', size=10)
    y -= 6

    lines.append(('F2', 12, MARGIN, y, 'What It Does'))
    y -= 14
    features = [
        'Authentication and profile setup, with package-scoped user/profile flows.',
        'Artwork discovery, browsing, and community feed/post interactions.',
        'Art capture/media workflows and location-based art walk experiences.',
        'Events creation/discovery and route-driven feature navigation.',
        'Real-time messaging and presence-aware chat services.',
        'Monetization features (ads, sponsorships, subscriptions, in-app purchases, Stripe-backed payment paths).',
        'Admin dashboards for moderation, platform curation, settings, and analytics.',
    ]
    for item in features:
        y = add_wrapped(lines, y, item, size=10, bullet=True, leading=12)
    y -= 6

    lines.append(('F2', 12, MARGIN, y, 'How It Works (Architecture)'))
    y -= 14
    arch = [
        'Client: Flutter app entrypoint initializes localization, env/config, Firebase core, App Check, then launches MyApp.',
        'Composition: MultiProvider wires core/auth/community/messaging/artwork/event/art-walk/capture services; AppRouter dispatches routes across domain packages.',
        'Data/services: App uses Firebase SDKs directly (Auth, Firestore, Storage, Messaging, Analytics, App Check) plus Google Maps/location services and local state/providers.',
        'Backend: Firebase project config, Firestore/Storage security rules, and Cloud Functions (Node.js 22) for server-side jobs and HTTP/callable endpoints (including Stripe-related logic).',
        'Data Connect: configuration exists, but active production schema usage is Not found in repo (schema file is commented sample content).',
    ]
    for item in arch:
        y = add_wrapped(lines, y, item, size=9.5, bullet=True, leading=11.5)
    y -= 6

    lines.append(('F2', 12, MARGIN, y, 'How To Run (Minimal)'))
    y -= 14
    run_steps = [
        'Prereq: Flutter 3.38.7+ and Dart 3.10.7+ (see README.md and pubspec.yaml).',
        'Install dependencies: flutter pub get',
        'Set env file: cp .env.example .env.local and provide Firebase/Stripe/Maps keys.',
        'Start app: flutter run',
        'Platform-specific setup details (Pods/signing/etc.): see README.md sections if needed.',
    ]
    for item in run_steps:
        y = add_wrapped(lines, y, item, size=10, bullet=True, leading=12)

    if y < MARGIN:
        raise RuntimeError(f'Content overflowed single page (final y={y}).')

    return lines


def make_pdf(lines):
    stream_cmds = []
    for font, size, x, y, text in lines:
        stream_cmds.append('BT')
        stream_cmds.append(f'/{font} {size} Tf')
        stream_cmds.append(f'1 0 0 1 {x:.2f} {y:.2f} Tm')
        stream_cmds.append(f'({esc(text)}) Tj')
        stream_cmds.append('ET')
    stream = '\n'.join(stream_cmds).encode('latin-1', errors='replace')

    objects = []

    def add_obj(data: bytes):
        objects.append(data)
        return len(objects)

    font1 = add_obj(b'<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>')
    font2 = add_obj(b'<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>')

    content = add_obj(b'<< /Length ' + str(len(stream)).encode('ascii') + b' >>\nstream\n' + stream + b'\nendstream')

    resources = f'<< /Font << /F1 {font1} 0 R /F2 {font2} 0 R >> >>'.encode('ascii')
    page = add_obj(
        b'<< /Type /Page /Parent 0 0 R /MediaBox [0 0 612 792] /Resources ' +
        resources +
        f' /Contents {content} 0 R >>'.encode('ascii')
    )

    pages = add_obj(f'<< /Type /Pages /Kids [{page} 0 R] /Count 1 >>'.encode('ascii'))

    # Patch page parent reference now that /Pages object exists
    page_data = objects[page - 1].replace(b'/Parent 0 0 R', f'/Parent {pages} 0 R'.encode('ascii'))
    objects[page - 1] = page_data

    catalog = add_obj(f'<< /Type /Catalog /Pages {pages} 0 R >>'.encode('ascii'))

    pdf = bytearray()
    pdf.extend(b'%PDF-1.4\n%\xe2\xe3\xcf\xd3\n')
    offsets = [0]
    for i, obj in enumerate(objects, start=1):
        offsets.append(len(pdf))
        pdf.extend(f'{i} 0 obj\n'.encode('ascii'))
        pdf.extend(obj)
        pdf.extend(b'\nendobj\n')

    xref_pos = len(pdf)
    pdf.extend(f'xref\n0 {len(objects)+1}\n'.encode('ascii'))
    pdf.extend(b'0000000000 65535 f \n')
    for off in offsets[1:]:
        pdf.extend(f'{off:010d} 00000 n \n'.encode('ascii'))

    pdf.extend(b'trailer\n')
    pdf.extend(f'<< /Size {len(objects)+1} /Root {catalog} 0 R >>\n'.encode('ascii'))
    pdf.extend(b'startxref\n')
    pdf.extend(f'{xref_pos}\n'.encode('ascii'))
    pdf.extend(b'%%EOF\n')

    OUT.write_bytes(pdf)


if __name__ == '__main__':
    OUT.parent.mkdir(parents=True, exist_ok=True)
    lines = build_lines()
    make_pdf(lines)
    print(str(OUT.resolve()))
