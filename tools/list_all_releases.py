#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, sys, requests, subprocess, re

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

url = subprocess.check_output(['git', 'remote', 'get-url', 'origin'], text=True).strip()
token = re.search(r'https://([^@:]+)@', url).group(1)
headers = {'Authorization': f'token {token}', 'Accept': 'application/vnd.github.v3+json'}
r = requests.get('https://api.github.com/repos/NetOpsSolutions/Berea_Interlineal/releases', headers=headers)

print("=" * 90)
print(f"{'TAG':<10} | {'DRAFT':<6} | {'PREREL':<6} | {'ASSETS':<6} | {'TITLE'}")
print("=" * 90)
for rel in r.json():
    tag = rel.get('tag_name') or 'untagged'
    draft = str(rel.get('draft', False))
    prerel = str(rel.get('prerelease', False))
    assets_cnt = len(rel.get('assets', []))
    name = rel.get('name') or ''
    print(f"{tag:<10} | {draft:<6} | {prerel:<6} | {assets_cnt:<6} | {name}")
    for a in rel.get('assets', []):
        size_mb = a['size'] / (1024 * 1024)
        print(f"   ↳ {a['name']:<45} ({size_mb:5.2f} MB)")
print("=" * 90)
