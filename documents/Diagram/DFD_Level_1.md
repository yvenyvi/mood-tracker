# Data Flow Diagram (DFD) Level 1 - Mood Tracker App

## 1. Diagram

```mermaid
graph TD
    %% Styling
    classDef process fill:#f9f9f9,stroke:#333,stroke-width:2px,rx:10,ry:10;
    classDef store fill:#fff,stroke:#333,stroke-width:2px,stroke-dasharray: 5, 5;
    classDef entity fill:#e1f5fe,stroke:#0277bd,stroke-width:2px;

    %% Components
    User[User]:::entity

    P1[["1.0 Manage
    Authentication"]]:::process
    P2[["2.0 Manage
    Mood Entries"]]:::process
    P3[["3.0 Analyze
    Moods"]]:::process
    P4[["4.0 Manage
    Profile"]]:::process

    D1[(D1 User Profiles)]:::store
    D2[(D2 Mood History)]:::store
    D3[(D3 Custom Emotions)]:::store

    %% Structure: User on top, Processes in center column
    User -->|Update Settings| P4
    User -->|Credentials| P1
    User -->|Mood Data| P2
    User -->|Req. Insights| P3

    %% Right Side: User Profiles (interacts with P1, P4)
    P1 <-->|Read/Write
    Profile| D1
    P4 <-->|Update
    Profile| D1

    %% Left Side: Mood Data (interacts with P2, P3)
    D3 <-->|Save/Load
    Emotion| P2
    D2 <-->|Save/Load
    Entry| P2
    D2 -->|Raw Data| P3

    %% Process Flow / Logic Connections
    P1 -.->|User
    Context| P2
    P2 -.->|Entry
    Data| P3

    %% Output Flows
    P3 -->|Visuals/Stats| User
    P2 -->|History View| User
    P1 -->|Auth Session| User
    P4 -->|Profile View| User

    %% Positioning Hints (Invisible links to maintain column structure if possible)
    P1 ~~~ P2 ~~~ P3 ~~~ P4
```

## 2. Components Description

### External Entities

- **User**: The individual interacting with the application.

### Processes

- **1.0 Manage Authentication**: Handles registration, login, and session validation.
- **2.0 Manage Mood Entries**: Handles creation, reading, updating, and deleting of mood logs and custom emotions.
- **3.0 Analyze Moods**: Generates insights and statistics from mood history.
- **4.0 Manage Profile**: Handles user settings and profile updates.

### Data Stores

- **D1 User Profiles**: Stores user identity and preferences (Right side).
- **D2 Mood History**: Stores mood logs (Left side).
- **D3 Custom Emotions**: Stores custom emotion tags (Left side).
