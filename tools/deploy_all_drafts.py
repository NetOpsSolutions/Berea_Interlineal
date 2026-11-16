#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
deploy_all_drafts.py
Publica en GitHub de forma secuencial y atómica las 3 releases como BORRADORES (draft: true):
- v1.3.5: Edición Léxica e Integridad Bíblica
- v1.3.7: Edición Exegética y Relaciones Strong
- v1.4.0: Edición Enciclopedia y Persiana
"""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.append(str(Path(__file__).resolve().parent))

from deploy_draft_release import upload_draft_release
import build_and_deploy_v135
import build_and_deploy_v137
import build_and_deploy_v140

def main():
    print("==================================================================")
    print(" DESPLIEGUE FINAL DE BORRADORES PRIVADOS EN GITHUB (DRAFT: TRUE)")
    print("==================================================================")

    # 1. v1.3.5
    print("\n>>> Desplegando v1.3.5 (Edición Léxica e Integridad Bíblica)...")
    upload_draft_release(
        build_and_deploy_v135.TAG_NAME,
        build_and_deploy_v135.RELEASE_TITLE,
        build_and_deploy_v135.RELEASE_NOTES,
        ROOT / "release_builds" / "v1.3.5"
    )

    # 2. v1.3.7
    print("\n>>> Desplegando v1.3.7 (Edición Exegética y Relaciones Strong)...")
    upload_draft_release(
        build_and_deploy_v137.TAG_NAME,
        build_and_deploy_v137.RELEASE_TITLE,
        build_and_deploy_v137.RELEASE_NOTES,
        ROOT / "release_builds" / "v1.3.7"
    )

    # 3. v1.4.0
    print("\n>>> Desplegando v1.4.0 (Edición Enciclopedia y Persiana)...")
    upload_draft_release(
        build_and_deploy_v140.TAG_NAME,
        build_and_deploy_v140.RELEASE_TITLE,
        build_and_deploy_v140.RELEASE_NOTES,
        ROOT / "release_builds" / "v1.4.0"
    )

    print("\n==================================================================")
    print(" ¡LAS 3 RELEASES BORRADOR FUERON PUBLICADAS EXITOSAMENTE!")
    print("==================================================================")

if __name__ == "__main__":
    main()
