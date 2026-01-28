# Workflows du Projet OutlookLocalAI

Ce document modélise les interactions et les flux de données de l'agent OutlookLocalAI.

## 1. Workflow Global de l'Application (Séquence)

Ce diagramme illustre le flux de traitement d'une commande utilisateur, de l'entrée CLI jusqu'à l'exécution dans Outlook et la réponse finale.

```mermaid
sequenceDiagram
    actor User as Utilisateur
    participant CLI as CLI (Spectre.Console)
    participant Orch as AgentOrchestrator
    participant LLM as LLMService
    participant Outlook as OutlookProvider

    User->>CLI: Saisie commande (ex: "Trouve le devis de Michel")
    activate CLI
    CLI->>Orch: ProcessUserRequestAsync("Trouve le devis de Michel")
    activate Orch
    
    note right of Orch: 1. Compréhension (NLP)
    Orch->>LLM: ExtractSearchCriteriaAsync(UserPrompt)
    activate LLM
    LLM-->>Orch: SearchCriteria { Sender="Michel", Keywords="Devis" }
    deactivate LLM

    note right of Orch: 2. Recherche Technique (Outlook)
    Orch->>Outlook: SearchEmails(Criteria)
    activate Outlook
    Outlook->>Outlook: Appliquer filtres DASL
    Outlook-->>Orch: Retourne 15 EmailItems
    deactivate Outlook

    note right of Orch: 3. Analyse Sémantique (IA)
    Orch->>LLM: AnalyzeEmailAsync(Body, "Est-ce un devis ?")
    activate LLM
    LLM-->>Orch: Résultat pertinent (Top 3)
    deactivate LLM

    Orch-->>CLI: Réponse textuelle formatée
    deactivate Orch
    
    CLI->>User: Affiche les résultats
    deactivate CLI
```

## 2. Stratégie de Recherche en Entonnoir (Flowchart)

Ce diagramme détaille la logique de filtrage pour optimiser les performances et la pertinence.

```mermaid
flowchart TD
    Start(["Requete Utilisateur"]) --> NLP["Analyse LLM"]
    NLP --> Criteria{"Critères Identifiés ?"}
    
    Criteria -- Oui --> FastSearch["Recherche Outlook DASL"]
    Criteria -- Non --> Fallback["Scan Inbox 7 jours"]
    
    FastSearch --> RawResults["Résultats Bruts 50 items"]
    Fallback --> RawResults
    
    RawResults --> MetaFilter["Filtrage Métadonnées"]
    MetaFilter --> candidates["Candidats 10 items"]
    
    subgraph DeepAnalysis ["Analyse Approfondie LLM"]
        candidates --> FetchBody["Lecture Corps Email"]
        FetchBody --> SemanticCheck{"Pertinent ?"}
    end
    
    SemanticCheck -- Oui --> FinalList["Résultats Finaux"]
    SemanticCheck -- Non --> Ignore["Ignorer"]
    
    FinalList --> Response(["Réponse Utilisateur"])
```

## 3. Architecture des Données (Class Diagram)

Ce diagramme représente les entités principales manipulées par le cœur de l'application.

```mermaid
classDiagram
    class EmailItem {
        +string EntryID
        +string Subject
        +string SenderName
        +string SenderEmailAddress
        +string Body
        +DateTime ReceivedTime
        +bool HasAttachments
    }

    class SearchCriteria {
        +DateTime? FromDate
        +DateTime? ToDate
        +string SenderNameContains
        +string SubjectContains
        +bool? HasAttachments
        +int MaxResults
    }

    class IOutlookProvider {
        <<interface>>
        +EnsureConnection()
        +SearchEmails(SearchCriteria) IEnumerable~EmailItem~
        +GetEmail(string entryId) EmailItem
    }

    class ILLMService {
        <<interface>>
        +ExtractSearchCriteriaAsync(string input) Task~SearchCriteria~
        +AnalyzeEmailAsync(string body, string query) Task~string~
    }

    IOutlookProvider ..> EmailItem : Returns
    IOutlookProvider ..> SearchCriteria : Uses
```