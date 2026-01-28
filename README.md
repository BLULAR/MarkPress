# MarkPress

**MarkPress** is a modern, lightweight, and powerful Markdown viewer for Windows built with Flutter. It allows you to view multiple Markdown files in tabs, navigate seamlessly, and export your documents to high-quality PDFs with a single click.

![MarkPress Logo](logo/mdviewer32x32.jpg)

## ✨ Features

*   **🗂️ Multi-Tab Interface**: Open and manage multiple `.md` files simultaneously in a browser-like tabbed interface.
*   **📊 Mermaid Diagrams**: Render flowcharts, sequence diagrams, and more directly in your Markdown.
*   **📄 Professional PDF Export**: Convert your Markdown notes into beautifully formatted PDF documents with embedded diagrams.
*   **🌍 Multi-Language Support**: Fully localized in English, French, German, Italian, and Spanish.
*   **🎨 Modern Design**: Built with Material 3 and `FlexColorScheme` for a polished, native Windows 11 feel.
*   **🚀 Fast & Lightweight**: optimized for desktop performance.
*   **🔒 Secure**: Safe link handling and local file processing (no cloud dependencies).

## ⬇️ Download & Installation

For regular users who just want to use MarkPress, you don't need to build from source.

1.  Go to the [Latest Releases](https://github.com/votre-user/votre-repo/releases/latest) page.
2.  Download the **`MarkPress_Setup_v1.0.0.exe`** file.
3.  Run the installer.

### ⚠️ Windows SmartScreen Warning
Since MarkPress is a free and open-source tool, the installer is not digitally signed with a paid certificate. Windows might show a blue or red "Windows protected your PC" screen. 

**Don't worry, it's safe!** To proceed:
1.  Click on **"More info"** (Informations complémentaires).
2.  Click on the **"Run anyway"** (Exécuter quand même) button.

---

## 🚀 Getting Started (Developers)

### Prerequisites

*   [Flutter SDK](https://flutter.dev/docs/get-started/install/windows)
*   Visual Studio (with C++ desktop development workload) for Windows build support.

### Installation & Run

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/YOUR_USERNAME/markpress.git
    cd markpress
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
*   **flex_color_scheme** - Theming
*   **flutter_animate** - Animations
*   **shared_preferences** - Local settings storage

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Developer

Developed by **SergeT**.