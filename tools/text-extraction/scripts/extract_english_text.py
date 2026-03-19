#!/usr/bin/env python3
"""
ArtBeat English Text Extraction Script
Extracts all hardcoded English text from Dart screen files.
"""

import os
import re
import json
from pathlib import Path
from typing import Dict, List, Set, Tuple
import argparse

class EnglishTextExtractor:
    def __init__(self, root_path: str):
        self.root_path = Path(root_path)
        self.english_texts: Dict[str, List[Dict]] = {}
        self.screen_files: List[Path] = []
        self.total_texts_found = 0
        
        # Regex patterns to find English text
        self.patterns = [
            # Standard Text widgets
            r"Text\s*\(\s*['\"]([^'\"]+)['\"]",
            # AppBar titles
            r"title:\s*Text\s*\(\s*['\"]([^'\"]+)['\"]",
            # Button labels
            r"(?:child|label):\s*Text\s*\(\s*['\"]([^'\"]+)['\"]",
            # Hint text
            r"hintText:\s*['\"]([^'\"]+)['\"]",
            # Helper text
            r"helperText:\s*['\"]([^'\"]+)['\"]",
            # Label text
            r"labelText:\s*['\"]([^'\"]+)['\"]",
            # Dialog content
            r"content:\s*Text\s*\(\s*['\"]([^'\"]+)['\"]",
            # Floating action button tooltip
            r"tooltip:\s*['\"]([^'\"]+)['\"]",
            # Snackbar content
            r"SnackBar\s*\([^)]*content:\s*Text\s*\(\s*['\"]([^'\"]+)['\"]",
            # Direct string literals (excluding imports and comments)
            r"(?<!import\s)['\"]([A-Z][^'\"]{10,})['\"]",
            # Error messages
            r"(?:error|Error).*?['\"]([^'\"]+)['\"]",
            # Dialog titles
            r"(?:title|Title).*?['\"]([^'\"]+)['\"]",
            # Tab labels
            r"Tab\s*\([^)]*text:\s*['\"]([^'\"]+)['\"]",
            # ListTile titles
            r"ListTile\s*\([^)]*title:\s*Text\s*\(\s*['\"]([^'\"]+)['\"]",
            # Card titles
            r"Card\s*\([^)]*child.*?Text\s*\(\s*['\"]([^'\"]+)['\"]",
            # AlertDialog actions
            r"TextButton\s*\([^)]*child:\s*Text\s*\(\s*['\"]([^'\"]+)['\"]",
        ]
        
        # Exclusion patterns (avoid false positives)
        self.exclusions = [
            r'^[a-z_]+$',  # Variable names
            r'^\d+$',      # Numbers only
            r'^[A-Z]{2,}$', # ALL CAPS (likely constants)
            r'package:',   # Package imports
            r'\.dart$',    # File extensions
            r'^https?://', # URLs
            r'^\w+\.\w+$', # Method calls like 'tr()'
            r'^[<>=/+\-*]+$', # Operators
            r'^\s*$',      # Empty or whitespace
        ]

    def find_screen_files(self) -> List[Path]:
        """Find all Dart screen files in the project."""
        screen_files = []
        
        # Search patterns for screen files
        patterns = [
            "**/screens/**/*.dart",
            "**/*screen*.dart",
            "**/lib/**/*screen*.dart",
        ]
        
        for pattern in patterns:
            screen_files.extend(self.root_path.glob(pattern))
        
        # Remove duplicates and filter out test files
        unique_files = list(set(screen_files))
        screen_files = [f for f in unique_files if '/test/' not in str(f) and '_test.dart' not in str(f)]
        
        return sorted(screen_files)

    def is_likely_english(self, text: str) -> bool:
        """Check if text is likely English and worth extracting."""
        if len(text) < 2:
            return False
            
        # Check exclusion patterns
        for pattern in self.exclusions:
            if re.match(pattern, text):
                return False
        
        # Must contain at least one letter
        if not re.search(r'[a-zA-Z]', text):
            return False
            
        # Skip if it looks like code (camelCase, snake_case)
        if re.match(r'^[a-z][a-zA-Z0-9_]*$', text) or re.match(r'^[a-z_]+[a-z]$', text):
            return False
            
        # Skip if it's already a translation key
        if '.tr()' in text or text.endswith('_text') or text.endswith('_title'):
            return False
            
        return True

    def extract_from_file(self, file_path: Path) -> List[Dict]:
        """Extract English text from a single Dart file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            return []

        found_texts = []
        
        for pattern in self.patterns:
            matches = re.finditer(pattern, content, re.MULTILINE | re.DOTALL)
            for match in matches:
                text = match.group(1).strip()
                
                if self.is_likely_english(text):
                    # Find line number
                    line_num = content[:match.start()].count('\n') + 1
                    
                    found_texts.append({
                        'text': text,
                        'line': line_num,
                        'pattern': pattern,
                        'context': self.get_context(content, match.start(), match.end())
                    })
        
        # Remove duplicates while preserving order
        seen = set()
        unique_texts = []
        for item in found_texts:
            if item['text'] not in seen:
                seen.add(item['text'])
                unique_texts.append(item)
        
        return unique_texts

    def get_context(self, content: str, start: int, end: int, context_chars: int = 50) -> str:
        """Get surrounding context for better understanding."""
        context_start = max(0, start - context_chars)
        context_end = min(len(content), end + context_chars)
        return content[context_start:context_end].replace('\n', ' ').strip()

    def extract_all_texts(self):
        """Extract English text from all screen files."""
        self.screen_files = self.find_screen_files()
        print(f"Found {len(self.screen_files)} screen files to analyze")
        
        for file_path in self.screen_files:
            relative_path = str(file_path.relative_to(self.root_path))
            print(f"Analyzing: {relative_path}")
            
            texts = self.extract_from_file(file_path)
            if texts:
                self.english_texts[relative_path] = texts
                self.total_texts_found += len(texts)
                print(f"  Found {len(texts)} English text strings")

    def generate_report(self) -> str:
        """Generate a comprehensive report of all found English text."""
        report = []
        report.append("# ArtBeat App - English Text on All Screens")
        report.append(f"*Generated on: {__import__('datetime').datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*")
        report.append("")
        report.append("## Summary")
        report.append(f"- **Total Screen Files Analyzed**: {len(self.screen_files)}")
        report.append(f"- **Files with English Text**: {len(self.english_texts)}")
        report.append(f"- **Total English Text Strings Found**: {self.total_texts_found}")
        report.append("")
        
        # Group by package
        packages = {}
        for file_path, texts in self.english_texts.items():
            if 'packages/' in file_path:
                package_name = file_path.split('packages/')[1].split('/')[0]
            else:
                package_name = 'main_app'
            
            if package_name not in packages:
                packages[package_name] = {}
            packages[package_name][file_path] = texts

        report.append("## By Package")
        for package_name in sorted(packages.keys()):
            package_texts = packages[package_name]
            total_in_package = sum(len(texts) for texts in package_texts.values())
            
            report.append(f"\n### {package_name} ({len(package_texts)} files, {total_in_package} texts)")
            
            for file_path in sorted(package_texts.keys()):
                texts = package_texts[file_path]
                report.append(f"\n#### {file_path} ({len(texts)} texts)")
                
                for i, text_info in enumerate(texts, 1):
                    report.append(f"{i}. **Line {text_info['line']}**: \"{text_info['text']}\"")
                    if len(text_info['context']) > len(text_info['text']) + 20:
                        report.append(f"   *Context*: `{text_info['context'][:100]}...`")

        # All texts alphabetically
        report.append("\n## All Unique English Texts (Alphabetical)")
        all_texts = set()
        for texts in self.english_texts.values():
            for text_info in texts:
                all_texts.add(text_info['text'])
        
        for i, text in enumerate(sorted(all_texts), 1):
            report.append(f"{i}. \"{text}\"")

        return "\n".join(report)

    def save_json_output(self, output_path: str):
        """Save extracted data as JSON for further processing."""
        output_data = {
            'metadata': {
                'generated_at': __import__('datetime').datetime.now().isoformat(),
                'total_files': len(self.screen_files),
                'files_with_text': len(self.english_texts),
                'total_texts': self.total_texts_found
            },
            'files': self.english_texts,
            'all_unique_texts': sorted(list(set(
                text_info['text'] 
                for texts in self.english_texts.values() 
                for text_info in texts
            )))
        }
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(output_data, f, indent=2, ensure_ascii=False)

def main():
    parser = argparse.ArgumentParser(description='Extract English text from ArtBeat screen files')
    parser.add_argument('--root', default='.', help='Root directory of the project')
    parser.add_argument(
        '--output',
        default='tools/text-extraction/data/english_texts_report.md',
        help='Output markdown file',
    )
    parser.add_argument(
        '--json',
        default='tools/text-extraction/data/english_texts_data.json',
        help='Output JSON file',
    )
    
    args = parser.parse_args()
    
    extractor = EnglishTextExtractor(args.root)
    
    print("Starting English text extraction...")
    extractor.extract_all_texts()
    
    print(f"\nGenerating report...")
    report = extractor.generate_report()
    
    with open(args.output, 'w', encoding='utf-8') as f:
        f.write(report)
    
    extractor.save_json_output(args.json)
    
    print(f"\n✅ Extraction complete!")
    print(f"📄 Report saved to: {args.output}")
    print(f"📊 Data saved to: {args.json}")
    print(f"📈 Found {extractor.total_texts_found} English text strings in {len(extractor.english_texts)} files")

if __name__ == "__main__":
    main()
