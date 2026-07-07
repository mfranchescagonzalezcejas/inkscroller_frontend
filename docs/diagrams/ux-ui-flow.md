# InkScroller UX/UI Flow Diagram

This document is the canonical planning source for the product-level UX/UI flow diagram. It connects the Phase 6 visual refresh with the user journeys that reviewers, designers, and implementers need to reason about.

> Jira: [INK-83](https://devdigi.atlassian.net/browse/INK-83)  
> Design source of truth: [`design/DESIGN.md`](../../design/DESIGN.md) + `design/designApp`  
> Product source: [`docs/PRD/phase-6-visual-refresh.md`](../PRD/phase-6-visual-refresh.md)

> **Recommended editable source:** [`ux-ui-flow.drawio`](ux-ui-flow.drawio).  
> Mermaid remains useful as a textual sketch, but draw.io is the preferred artifact for this UX/UI flow because the product map needs manual layout control.

## Quick path

1. Open [`ux-ui-flow.drawio`](ux-ui-flow.drawio) in diagrams.net or the VS Code Draw.io extension.
2. Use the planning table to confirm the flow boundaries.
3. Keep the Mermaid source below as a lightweight textual sketch, not the primary review artifact.

## Diagram plan

| Area | Flow responsibility |
|------|---------------------|
| App entry | Start the user in the shell and account state check. |
| Main navigation | Keep Home, Explore, Library, and Profile as the primary product tabs. |
| Discovery | Let users browse editorial content, search, and open title detail. |
| Reading | Move from title detail to readable chapters, external chapters, or reader settings. |
| Account state | Show different Profile paths for guest and logged-in users without blocking app-level settings. |
| Support surfaces | Keep Settings and About reachable from Profile, not the bottom navigation. |
| Runtime states | Make loading, empty, error, and offline/fallback states first-class outcomes. |

## Mermaid source

```mermaid
flowchart TD
    AppStart([Open InkScroller]) --> Shell[Main App Shell]
    Shell --> AccountState{User signed in?}

    AccountState -->|Guest| GuestMode[Guest app mode]
    AccountState -->|Signed in| SignedInMode[Signed-in app mode]

    GuestMode --> BottomNav[Primary bottom navigation]
    SignedInMode --> BottomNav


    BottomNav --> Home[Home]
    BottomNav --> Explore[Explore]
    BottomNav --> Library[Library]
    BottomNav --> Profile[Profile]

    Home --> HeroCarousel[Cinematic hero carousel]
    Home --> ContinueReading[Continue Reading]
    Home --> Trending[Trending Now]
    Home --> NewChapters[New Chapters]

    Explore --> Search[Search manga]
    Explore --> RecentSearches[Recent searches]
    Explore --> TrendingList[Numbered trending list]
    Explore --> GenreGrid[Genre grid]

    Library --> SavedTitles[Saved titles]
    Library --> LibraryEmpty{Library has content?}
    LibraryEmpty -->|No| EmptyArchive[Premium empty archive state]
    LibraryEmpty -->|Yes| SavedTitles

    HeroCarousel --> TitleDetail[Title Detail]
    ContinueReading --> Reader[Reader]
    Trending --> TitleDetail
    NewChapters --> TitleDetail
    Search --> TitleDetail
    TrendingList --> TitleDetail
    GenreGrid --> TitleDetail
    SavedTitles --> TitleDetail

    TitleDetail --> OfficialAvailability[Official availability]
    TitleDetail --> ReadDecision{Chapter source}
    TitleDetail --> TitlePrefs[Per-title reader settings]
    TitleDetail --> CommunityTeaser[Community teaser]

    ReadDecision -->|Readable in app| Reader
    ReadDecision -->|External only| ExternalSource[[Open official/external source]]

    Reader --> ReaderControls[Glass reader controls]
    ReaderControls --> ReaderSettings[Reader settings overlay]
    TitlePrefs --> ReaderSettings

    Profile --> ProfileState{Profile mode}
    ProfileState -->|Guest| GuestProfile[Guest profile hub]
    ProfileState -->|Signed in| LoggedInProfile[Logged-in profile]

    GuestProfile --> SignIn[Sign in / register]
    GuestProfile --> LocalPrefs[Local reading preferences]
    LoggedInProfile --> AccountInfo[Account information]
    LoggedInProfile --> SyncedPrefs[Reading preferences]

    GuestProfile --> Settings[Settings]
    LoggedInProfile --> Settings
    GuestProfile --> About[About / legal hub]
    LoggedInProfile --> About

    Settings --> RuntimeBoards[Runtime state boards]
    RuntimeBoards --> Loading[Loading]
    RuntimeBoards --> Empty[Empty]
    RuntimeBoards --> Error[Error]
    RuntimeBoards --> OfflineFallback[Offline / fallback]

    OfflineFallback --> CachedReader{Cached pages available?}
    CachedReader -->|Yes| Reader
    CachedReader -->|No| Reconnect[Reconnect guidance]

    classDef primary fill:#1A2122,stroke:#80D5CB,color:#E2E4E6;
    classDef decision fill:#242B2C,stroke:#F4C95D,color:#E2E4E6;
    classDef external fill:#111416,stroke:#888D93,color:#E2E4E6;

    class Shell,BottomNav,Home,Explore,Library,Profile,TitleDetail,Reader primary;
    class AccountState,LibraryEmpty,ReadDecision,ProfileState,CachedReader decision;
    class ExternalSource,Reconnect external;
```

## Review checklist

- [ ] The diagram keeps Settings and About under Profile, matching the Phase 6 navigation decision.
- [ ] Guest users can still access local preferences and support/legal surfaces.
- [ ] Title Detail clearly separates in-app reading from external/official source links.
- [ ] Offline/fallback behavior preserves cached reader access when available.
- [ ] The diagram remains documentation/tooling only; it does not require Flutter app code changes.

## Mermaid MCP setup

OpenCode now has a local MCP entry named `mcp-mermaid` in the user config:

```json
"mcp-mermaid": {
  "command": ["cmd", "/c", "npx", "-y", "mcp-mermaid"],
  "enabled": true,
  "type": "local"
}
```

Restart OpenCode after this change so the MCP server is discovered.
