#!/usr/bin/env python3
"""
Simple local HTML validator script.
Performs lightweight checks (doctype, head/body/title, lang attribute, link tags, unescaped ampersands).
Not a full W3C validator, but catches common issues.
"""
import re
import sys
from pathlib import Path

def read(path):
    return Path(path).read_text(encoding='utf-8', errors='replace')


def find_links(content):
    return re.findall(r'<link\s+([^>]+)>', content, flags=re.I)


def attr_has(attrs, name):
    return re.search(rf'{name}\s*=\s*("[^"]*"|\'[^\']*\')', attrs, re.I) is not None


def check_unescaped_ampersands(content):
    problems = []
    for i, line in enumerate(content.splitlines(), start=1):
        for m in re.finditer(r'&(?!(#[0-9]+|#x[0-9a-fA-F]+|[a-zA-Z]+);)', line):
            problems.append((i, line.strip()))
            break
    return problems


def run_checks(path):
    content = read(path)
    results = []
    # 1. DOCTYPE
    results.append(("DOCTYPE declaration present", bool(re.search(r'<!DOCTYPE\s+html', content, re.I)), "Add <!DOCTYPE html> at top if missing."))
    # 2. single html tag
    html_open = len(re.findall(r'<html\b', content, re.I))
    html_close = len(re.findall(r'</html>', content, re.I))
    results.append(("Single <html> open/close", html_open == 1 and html_close == 1, f"Found <html> opens: {html_open}, closes: {html_close}."))
    # 3. lang attribute on html
    results.append(("<html> has lang attribute", bool(re.search(r'<html[^>]*\blang\s*=\s*([\"\\\'])(.*?)\1', content, re.I)), "Add lang=\"en\" (or appropriate language) to the <html> tag for accessibility."))
    # 4. head and body presence
    head_open = bool(re.search(r'<head\b', content, re.I))
    head_close = bool(re.search(r'</head>', content, re.I))
    body_open = len(re.findall(r'<body\b', content, re.I))
    body_close = len(re.findall(r'</body>', content, re.I))
    results.append(("<head> present and closed", head_open and head_close, "Ensure <head>...</head> exists and is properly closed."))
    results.append(("<body> present and single closed", body_open == 1 and body_close == 1, f"Found <body> opens: {body_open}, closes: {body_close}."))
    # 5. title inside head
    title_in_head = bool(re.search(r'<head[\s\S]*?<title>.*?</title>', content, re.I))
    results.append(("<title> present inside <head>", title_in_head, "Add a <title> inside <head> to improve accessibility and SEO."))
    # 6. link tags have rel and href
    links = find_links(content)
    link_problems = []
    for attrs in links:
        if not attr_has(attrs, 'href') or not attr_has(attrs, 'rel'):
            link_problems.append(attrs)
    results.append(("All <link> tags have href and rel", len(link_problems) == 0, f"Problematic <link> tags: {len(link_problems)}"))
    # 7. unescaped ampersands
    amps = check_unescaped_ampersands(content)
    results.append(("No unescaped ampersands", len(amps) == 0, f"Found {len(amps)} line(s) with literal '&' that may need escaping."))

    return results, amps


def print_report(path, results, amps):
    print(f"Validating: {path}\n")
    ok_count = 0
    for desc, passed, msg in results:
        status = 'PASS' if passed else 'FAIL'
        print(f"{status}: {desc}")
        if not passed:
            print(f"  -> {msg}")
        else:
            ok_count += 1
    print('\nSummary:')
    total = len(results)
    print(f"  {ok_count}/{total} checks passed.")
    if amps:
        print('\nUnescaped ampersand examples:')
        for lineno, line in amps[:10]:
            print(f"  Line {lineno}: {line}")
    print('\nNotes: This is a lightweight local checker, not a full W3C validation. For full validation consider the W3C validator (validator.w3.org).')


if __name__ == '__main__':
    path = sys.argv[1] if len(sys.argv) > 1 else r'c:\Users\bdavi\OneDrive\index.html\week03-ex01\index.html week3 -ex01'
    p = Path(path)
    if not p.exists():
        print(f"File not found: {path}")
        sys.exit(2)
    results, amps = run_checks(path)
    print_report(path, results, amps)
    # exit code 0 if all pass, 1 otherwise
    all_pass = all(passed for _, passed, _ in results)
    sys.exit(0 if all_pass else 1)
