# MarkPress

**MarkPress** is a modern, lightweight, and powerful Markdown viewer for Windows built with Flutter. It allows you to view multiple Markdown files in tabs, navigate seamlessly, and export your documents to high-quality PDFs with a single click.

![MarkPress Logo](logo/mdviewer32x32.jpg)

## ✨ Fonctionnalités Principales

*   **🎨 Interface Material 3** : Une UI fluide et moderne avec des animations soignées (powered by Flutter).
*   **📊 Diagrammes Mermaid** : Affichez flowcharts, diagrammes de séquence et plus directement dans vos fichiers Markdown.
*   **📄 Moteur d'Export PDF Robuste** :
    *   Conversion fidèle du Markdown vers PDF.
    *   Gestion intelligente des blocs de code massifs (K8s, Logs) grâce au "Smart Chunking" (plus de crashs sur les longs fichiers !).
    *   Intégration des diagrammes Mermaid dans les PDFs exportés.
    *   Support des polices spéciales et fallback automatique pour les symboles.
    *   Gestion sécurisée des Emojis (nettoyage automatique si non supportés).
*   **🖼️ Gestion des Médias** :
    *   Affichage des images locales et distantes dans l'éditeur.
    *   Dans le PDF : Remplacement automatique des images par des placeholders visuels [IMG] si nécessaire.
*   **🌍 Multi-Langue** : Entièrement localisé en Français, Anglais, Allemand, Italien et Espagnol.
*   **🔒 100% Local** : Vos fichiers ne quittent jamais votre machine. Sécurité et confidentialité totales.
*   **🔗 Navigation Avancée** : Support des liens internes (ancres) et liens externes sécurisés.

## 🛠️ Améliorations Techniques (v2.0.0)

*   Correction du crash "Widget won't fit" lors de l'export PDF de très longs fichiers (ex: manifestes Kubernetes).
*   Support des diagrammes Mermaid via mermaid.ink.
*   Optimisation du parsing Markdown (GitHub Flavored).
*   Installeur Windows optimisé (Setup léger).

## ⬇️ Installation

1.  Téléchargez le fichier **`MarkPress_Setup_v2.0.0.exe`** depuis la [page des Releases](https://github.com/BLULAR/MarkPress/releases/latest).
2.  Lancez l'installation (SmartScreen peut apparaître car le certificat est auto-signé, cliquez sur "Informations complémentaires" > "Exécuter quand même").
3.  Profitez de vos fichiers Markdown !

---

## 🚀 Getting Started (Developers)

### Prerequisites

*   [Flutter SDK](https://flutter.dev/docs/get-started/install/windows)
*   Visual Studio (with C++ desktop development workload) for Windows build support.

### Installation & Run

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/BLULAR/MarkPress.git
    cd MarkPress
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    ```bash
    flutter run -d windows
    ```

### Building the Installer

To create a standalone `.exe` installer for distribution:

1.  Build the release version:
    ```bash
    flutter build windows
    ```
2.  Open `installers/markpress_setup.iss` with **Inno Setup**.
3.  Click **Run** to generate the installer in the `installers/` folder.

## 🛠️ Built With

*   **Flutter** - UI Toolkit
*   **flutter_markdown** - Markdown rendering
*   **printing** & **pdf** - PDF generation
*   **flex_color_scheme** - Theming (Material 3)
*   **flutter_animate** - Animations
*   **mermaid.ink** - Diagram rendering

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Developer

Developed by **Serge Toulzac**.