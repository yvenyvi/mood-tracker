# Use Case Model - Mood Tracker App

## 1. Actors

- **User**: The primary actor who interacts with the application.

## 2. Use Case Diagram

```mermaid
graph LR
    %% Styling
    classDef actor fill:#fff,stroke:#000,stroke-width:2px;
    classDef usecase fill:#f9f9f9,stroke:#333,stroke-width:1px,rx:20,ry:20;

    %% Actor
    User((User)):::actor

    %% Use Cases
    UC_Analytics(View Analytics):::usecase
    UC_Search(Search Entries):::usecase
    UC_Export(Export Data):::usecase
    UC_Profile("Manage Profile <br/> (Custom emotions)"):::usecase
    UC_Log(Log Mood Entry):::usecase
    UC_Login(Login/Register):::usecase
    UC_Comfort("Activate Comfort <br/> Mode"):::usecase

    %% User Connections (Star/Fan Pattern)
    User --> UC_Analytics
    User --> UC_Search
    User --> UC_Export
    User --> UC_Profile
    User --> UC_Log
    User --> UC_Login
    User --> UC_Comfort

    %% Inter-Use Case Relationships

    %% Login precedes Logging
    UC_Login -->|Precedes| UC_Log

    %% Log Entry saves to Profile
    UC_Log -->|Save <br/> custom entries| UC_Profile

    %% Log Entry triggers Comfort Mode
    UC_Log -->|High Intensity| UC_Comfort
```

## 3. Use Case Specifications

### Primary Flow: Log Mood Entry

- **Precedes**: User must be authenticated (`Login/Register`).
- **Triggers**: If intensity is high (>2) and mood is negative, it triggers `Activate Comfort Mode`.
- **Updates**: Saving a new custom emotion during logging updates the `Manage Profile` library.
