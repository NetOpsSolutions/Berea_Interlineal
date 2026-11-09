#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sincroniza los títulos y las notas Markdown (UTF-8 puro sin mojibake) de los
Releases publicados en GitHub (1.3.0, 1.3.1 y v1.3.2), leyendo directamente
los hashes SHA-256 desde release_builds/v<X.Y.Z>/checksums.txt y verificando
los codepoints Unicode devueltos por la API de GitHub.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import urllib.request
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
sys.stderr.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parent.parent
REPO = "NetOpsSolutions/Berea_Interlineal"


def get_github_token() -> str:
    token = os.environ.get("GITHUB_TOKEN", "").strip()
    if token:
        return token
    url = subprocess.check_output(
        ["git", "remote", "get-url", "origin"], text=True, encoding="utf-8"
    ).strip()
    match = re.search(r"https://([^@:]+)@", url)
    if match:
        return match.group(1)
    raise RuntimeError("No se encontró GITHUB_TOKEN ni credenciales en git remote.")


def read_checksums(ver: str) -> str:
    path = ROOT / "release_builds" / f"v{ver}" / "checksums.txt"
    return path.read_text(encoding="utf-8").strip()


def build_download_section(ver: str, ipa_filename: str) -> str:
    return (
        "## 📱 ¿Qué paquete descargar?\n"
        "| Archivo | Plataforma / Arquitectura | Dispositivos recomendados |\n"
        "|---|---|---|\n"
        f"| `berea_interlineal_{ver}_arm64-v8a.apk` | Android ARM 64-bit | Mayoría de teléfonos y tablets Android modernos (2017+) |\n"
        f"| `berea_interlineal_{ver}_armeabi-v7a.apk` | Android ARM 32-bit | Dispositivos Android anteriores o de 32 bits |\n"
        f"| `berea_interlineal_{ver}_x86_64.apk` | Android Intel / AMD 64-bit | Emuladores Android en PC y ChromeOS |\n"
        f"| `berea_interlineal_{ver}_universal.apk` | Android Universal (Multi-ABI) | Compatible con cualquier dispositivo Android |\n"
        f"| `{ipa_filename}` | iOS 15.0+ (iPhone / iPad) | Instalación en iPhone vía AltStore, Sideloadly o TrollStore |\n"
        "\n---\n\n"
        "## 🔒 Verificación de Integridad (SHA-256)\n"
        "```text\n"
        f"{read_checksums(ver)}\n"
        "```"
    )


def build_releases_payload() -> list[dict]:
    return [
        {
            "tag": "1.3.0",
            "id": 422130560,
            "name": "Berea Interlineal v1.3.0 - Motor OTA & Arranque Rápido",
            "body": (
                "## 🚀 Novedades en Berea Interlineal v1.3.0 (Build 4)\n\n"
                "### 🧭 Guía Interactiva de Bienvenida y Funciones Base\n"
                "- **Recorrido animado automático en el primer inicio**: Presenta paso a paso la lectura bíblica interlineal palabra por palabra, la búsqueda global unificada, los léxicos Strong (Hebreo y Griego), Mi Estudio personal y el Modo Oscuro.\n"
                "- **Disponible bajo demanda**: Puedes volver a consultarla en cualquier momento desde *Ajustes → Ver guía de uso*.\n\n"
                "### 🔄 Sistema de Actualización In-App (GitHub OTA)\n"
                "- **Detección automática de actualizaciones**: Consulta periódica y directa contra GitHub Releases con aviso en la bandeja nativa de notificaciones de Android.\n"
                "- **Descarga e instalación sin tiendas externas**: Selección automática por arquitectura de procesador (`arm64-v8a`, `armeabi-v7a`, `x86_64`, `universal`) e invocación nativa del instalador mediante `FileProvider`.\n\n"
                "### 🎬 Splash Screen e Identidad Oficial Berea Interlineal\n"
                "- **Pantalla de bienvenida con animación fluida (~1.6 s)**: Logotipo oficial inspirado en Hechos 17:11 y desempaquetado optimizado de la base bíblica SQLite offline en pocos segundos.\n"
                "- **Accesos directos y filtros en Mi Estudio**: Toca Marcadores, Notas o Historial en Ajustes para abrirlos directamente con chips interactivos (*Todas*, *En versículos*, *En palabras Strong*).\n\n"
                "---\n\n"
                f"{build_download_section('1.3.0', 'Logos_K_Logos_1.3.0.ipa')}"
            ),
        },
        {
            "tag": "1.3.1",
            "id": 422149278,
            "name": "Berea Interlineal v1.3.1: Edición Manuscrito Alejandrino",
            "body": (
                "# 📜 Berea Interlineal v1.3.1: Edición Manuscrito Alejandrino\n\n"
                "### 🎨 Nueva Experiencia Visual y Didáctica\n"
                "* **Fondo de Pergamino Alejandrino**: Reemplazo del blanco digital por un tono cálido de papiro y arena marfil (`#F5EEDB`) en Modo Claro, y códice en penumbra (`#181412`) en Modo Oscuro. Cero líneas de libreta, cero distracciones.\n"
                "* **Pantalla de Bienvenida Solemne**: Presentación majestuosa con atmósfera de cuero antiguo, resplandor dorado, barra de carga en oro ámbar y el lema oficial de **Hechos 17:11** (*«...escudriñando cada día las Escrituras»*).\n\n"
                "### 💾 Persistencia y Rendimiento\n"
                "* **Persistencia Real en SQLite**: Base de datos dedicada permanente (`logos_user_data.db`) para marcadores, notas e historial.\n"
                "* **Actualizador In-App OTA**: Descarga optimizada según la arquitectura de procesador del teléfono.\n"
                "* **Navegación Léxica Mejorada**: Hipervínculos entre códigos Strong derivados y acordeón de ocurrencias por libro.\n\n"
                "---\n\n"
                f"{build_download_section('1.3.1', 'Logos_K_Logos_1.3.1.ipa')}"
            ),
        },
        {
            "tag": "v1.3.2",
            "id": 425000889,
            "name": "Berea Interlineal v1.3.2 - Nueva Identidad, Alternador Rápido Sol/Luna & Guía Visual",
            "body": (
                "## 🚀 Novedades en Berea Interlineal v1.3.2 (Build 7)\n\n"
                "### ☀️/🌙 Novedad Destacada: Alternador Rápido de Modo Claro y Oscuro (Sol y Luna)\n"
                "- **Acceso Inmediato en la Barra Superior**: A partir de la versión 1.3.2 ya no es necesario acceder a la sección de Ajustes para alternar entre el modo claro (*Pergamino Diurno*) y el modo oscuro (*Noche Alejandrina*). Ahora cuentas con un botón accesible directamente en la barra superior (`AppBar`) de todas las pantallas principales (Biblia, Diccionario y Mi Estudio).\n"
                "- **Icono Dinámico Alternante**: El icono alterna inteligentemente: muestra un Sol radiante (☀️) en modo oscuro para volver al día con un solo toque, y una Luna solemne (🌙) en modo claro para proteger la vista en lecturas nocturnas sin distracciones.\n"
                "- **Sincronización Total en Caliente**: Cambio de ambiente visual instantáneo en toda la aplicación preservando tu posición exacta de lectura y estudio.\n\n"
                "### 🧭 Guía Visual Interactiva Contextual (Tour v1.3.2 Actualizado)\n"
                "- **Paso Didáctico Dedicado al Alternador Sol/Luna**: El recorrido guiado interactivo de 7 pasos señala e ilustra el uso del nuevo botón alternador en la barra superior para que el usuario aproveche esta mejora ergonómica desde el primer momento.\n"
                "- **Aparición Inteligente y Repetible**: Se muestra automáticamente una sola vez al instalar o actualizar, y queda siempre disponible bajo demanda en *Ajustes → Ver guía de uso*.\n\n"
                "### ✨ Transición Oficial a Berea Interlineal (Hechos 17:11)\n"
                "- **Nueva Identidad Visual Oficial**: Logotipo renovado inspirado en Hechos 17:11 (Biblia sagrada abierta iluminada con la lente de aumento exegética en oro pulido y destellos azul zafiro).\n"
                "- **Iconos Adaptativos Multi-resolución**: Integrados en Android (`mipmap-*` y adaptativo v26) e iOS (`AppIcon.appiconset`).\n"
                "- **Repositorio Oficial**: `https://github.com/NetOpsSolutions/Berea_Interlineal`, manteniendo compatibilidad continua de actualizaciones OTA para todas las instalaciones previas.\n\n"
                "### 📖 Experiencia de Lectura por Capítulo Completo (Fase 3 UI/UX)\n"
                "- **Lectura Continua de Capítulos Bíblicos**: Desplazamiento vertical fluido de capítulos completos con despliegue interlineal al instante al tocar cualquier versículo.\n"
                "- **Gestos Táctiles Swipe**: Desliza a la izquierda o a la derecha para avanzar o retroceder de capítulo con naturalidad.\n\n"
                "### 🔤 Tipografías Académicas SIL OFL & 5 Resaltadores Teológicos\n"
                "- **Fuentes Especializadas Offline**: Soporte nativo para *Ezra SIL* y *Frank Ruhl Libre* (Hebreo BHS con nikud y cantilaciones) y *Cardo* / *Gentium Plus* (Griego Koiné politónico), configurables desde el botón rápido «TT».\n"
                "- **Resaltadores Teológicos en SQLite**: Clasificación cromática persistente en 5 categorías (*Promesas*, *Mandamientos*, *Atributos de Dios*, *Advertencias* y *Doctrina y Profecía*) por versículo o por frase seleccionada.\n\n"
                "### 🔔 Notificaciones Nativas OTA y Contraste WCAG AAA\n"
                "- **Avisos en el Sistema Android**: Integración directa con el Centro de Notificaciones nativo (`POST_NOTIFICATIONS`) e interfaz de avisos emergentes con contraste garantizado en modo claro y oscuro.\n\n"
                "### 🍏 Distribución iOS (`.ipa`)\n"
                "- Paquete instalador oficial `Berea_Interlineal_1.3.2.ipa` para iPhone e iPad (iOS 15.0+), instalable vía AltStore, Sideloadly o TrollStore.\n\n"
                "---\n\n"
                f"{build_download_section('1.3.2', 'Berea_Interlineal_1.3.2.ipa')}"
            ),
        },
    ]


def verify_no_mojibake(label: str, text: str) -> None:
    forbidden = ["\ufffd", "Ã¡", "Ã©", "Ã­", "Ã³", "Ãº", "Ã±", "Â¿", "ðŸ", "â€"]
    for bad in forbidden:
        if bad in text:
            raise AssertionError(f"Se detectó secuencia corrupta {bad!r} en {label}")
    # Verificar que no haya '?' pegado dentro de palabras acentuadas (ej. Gu?a, R?pido, Qu?)
    if re.search(r"[A-Za-z]\?[a-z]", text) or "¿Qu?" in text:
        raise AssertionError(f"Se detectó signo '?' sustituto en {label}")


def main() -> None:
    token = get_github_token()
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "Content-Type": "application/json; charset=utf-8",
        "User-Agent": "Berea-UTF8-Release-Sync",
    }

    for item in build_releases_payload():
        verify_no_mojibake(f"{item['tag']} local name", item["name"])
        verify_no_mojibake(f"{item['tag']} local body", item["body"])

        # Serializar con ensure_ascii=True (\uXXXX) hace imposible cualquier corrupción de transporte
        payload_bytes = json.dumps(
            {"name": item["name"], "body": item["body"]}, ensure_ascii=True
        ).encode("ascii")

        req = urllib.request.Request(
            f"https://api.github.com/repos/{REPO}/releases/{item['id']}",
            data=payload_bytes,
            method="PATCH",
            headers=headers,
        )
        with urllib.request.urlopen(req) as resp:
            raw_resp = resp.read().decode("utf-8")
            updated = json.loads(raw_resp)

        verify_no_mojibake(f"{item['tag']} remote name", updated["name"])
        verify_no_mojibake(f"{item['tag']} remote body", updated["body"])
        assert updated["name"] == item["name"], f"Name mismatch on {item['tag']}"
        assert updated["body"] == item["body"], f"Body mismatch on {item['tag']}"

        print(f"[OK] {item['tag']} (ID {item['id']}): '{updated['name']}'")
        for sample_line in updated["body"].splitlines()[:6]:
            if sample_line.strip():
                print(f"     {sample_line}")


if __name__ == "__main__":
    main()
