import sys
from pathlib import Path
sys.path.append(str(Path(__file__).resolve().parent))

import json
import requests
from deploy_draft_release import get_token, REPO
import build_and_deploy_v135

RELEASE_ID = 441246829

def verify_and_publish():
    token = get_token()
    headers = {'Authorization': f'token {token}', 'Accept': 'application/vnd.github.v3+json'}
    
    # 1. Inspect current release
    url = f"https://api.github.com/repos/{REPO}/releases/{RELEASE_ID}"
    res = requests.get(url, headers=headers)
    if res.status_code != 200:
        print(f"Error fetching release: {res.status_code} {res.text}")
        return
    
    rel = res.json()
    print(f"Current Release ID: {rel['id']}")
    print(f"Current Name: {rel['name']}")
    print(f"Current Draft: {rel['draft']}")
    print(f"Current Tag: {rel['tag_name']}")
    print(f"Current HTML URL: {rel['html_url']}")
    print("Assets:")
    for a in rel.get('assets', []):
        print(f"  - {a['name']} ({a['size']} bytes, downloads: {a['download_count']}, updated_at: {a['updated_at']})")
    
    # 2. Prepare clean notes and title
    body = rel.get('body', '')
    draft_banner_substr = "> **ESTADO DE PUBLICACIÓN**: **BORRADOR PRIVADO (DRAFT: TRUE)**."
    if draft_banner_substr in body:
        lines = body.splitlines()
        cleaned_lines = []
        skip = False
        for line in lines:
            if "> **ESTADO DE PUBLICACIÓN**:" in line:
                skip = True
                continue
            if skip:
                if line.strip() == "---":
                    skip = False
                continue
            cleaned_lines.append(line)
        body = "\n".join(cleaned_lines).lstrip()
    
    official_header = "> **VERSIÓN PÚBLICA OFICIAL (PRODUCCIÓN)**  \n> Publicación oficial disponible para actualización automática (OTA) y descarga directa.\n\n---\n"
    if not body.startswith("> **VERSIÓN PÚBLICA OFICIAL"):
        body = official_header + body
        
    title = "📜 Berea Interlineal v1.3.5 - Edición Léxica e Integridad Bíblica"
    
    patch_payload = {
        "tag_name": "v1.3.5",
        "name": title,
        "body": body,
        "draft": False,
        "prerelease": False
    }
    
    print("\nPatching release to public (draft=False)...")
    patch_res = requests.patch(url, headers=headers, json=patch_payload)
    if patch_res.status_code == 200:
        updated = patch_res.json()
        print("Successfully published v1.3.5!")
        print(f"Name: {updated['name']}")
        print(f"Draft: {updated['draft']}")
        print(f"Prerelease: {updated['prerelease']}")
        print(f"URL: {updated['html_url']}")
        print(f"Published at: {updated['published_at']}")
    else:
        print(f"Failed to publish: {patch_res.status_code} {patch_res.text}")
        return

    # 3. Verify public releases list from perspective of unauthenticated / app user
    print("\nVerifying public release endpoint (unauthenticated)...")
    pub_res = requests.get(f"https://api.github.com/repos/{REPO}/releases")
    pub_releases = pub_res.json()
    print("Public releases visible:")
    for r in pub_releases:
        print(f"  - Tag: {r.get('tag_name')}, Draft: {r.get('draft')}, Prerelease: {r.get('prerelease')}, Name: {r.get('name')}")

if __name__ == '__main__':
    verify_and_publish()
