# Markdown Viewer (Flutter)

Une application simple pour visualiser des fichiers Markdown sur Windows (et autres plateformes), développée avec **Flutter**.

## Prérequis

1.  **Installer Flutter** : Suivez les instructions officielles pour installer le SDK Flutter sur votre machine : [https://flutter.dev/docs/get-started/install/windows](https://flutter.dev/docs/get-started/install/windows).
2.  Assurez-vous que la commande `flutter doctor` ne signale aucun problème critique.

## Initialisation du projet

Comme je n'ai fourni que le code source Dart et la configuration, vous devez générer les fichiers spécifiques à votre plateforme (Windows) :

1.  Ouvrez une invite de commande (terminal) dans ce dossier.
2.  Lancez la commande suivante pour télécharger les dépendances et générer les dossiers `windows`, `android`, `ios`, etc. :

    ```bash
    flutter create .
    ```

3.  Installez les paquets listés dans `pubspec.yaml` :

    ```bash
    flutter pub get
    ```

## Lancement de l'application

Pour lancer l'application en mode développement sur Windows :

```bash
flutter run -d windows
```

*(Note : La première compilation peut prendre un certain temps)*

## Créer un exécutable (.exe)

Pour construire l'application finale optimisée pour la distribution :

1.  Lancez la commande :

    ```bash
    flutter build windows
    ```

2.  L'exécutable se trouvera dans `build/windows/runner/Release/`.
