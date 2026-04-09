# Streambert iOS

A **SwiftUI** iOS port of [Streambert](https://github.com/bnb549/streambert) — stream Movies, TV Series, and Anime using TMDB metadata and VidSrc/Videasy/2Embed video sources.

---

## Setup in Xcode

1. Clone this repo
2. Open `StreambertiOS.xcodeproj` (or create a new Xcode project and drag in the `StreambertiOS/` folder)
3. Build & run on your iPhone or simulator (iOS 16+)
4. On first launch, paste your free **TMDB API Read Access Token**
   - Get one at https://www.themoviedb.org/settings/api

---

## Project Structure

```
StreambertiOS/
├── StreambertiOSApp.swift       # App entry point
├── Models/
│   ├── MediaItem.swift          # Movie/TV data model
│   └── TVSeason.swift           # Season & Episode models
├── Services/
│   ├── APIKeyStore.swift        # Stores TMDB key in UserDefaults
│   ├── TMDBService.swift        # All TMDB API calls
│   └── StreamSources.swift      # VidSrc / Videasy / 2Embed URLs
└── Views/
    ├── SetupView.swift          # First-launch API key screen
    ├── ContentView.swift        # Tab bar
    ├── HomeView.swift           # Trending rows
    ├── SearchView.swift         # Search
    ├── MediaDetailView.swift    # Movie/TV detail + stream buttons
    ├── TVSeasonPicker.swift     # Season & episode picker
    ├── PlayerView.swift         # WKWebView full-screen player
    ├── MediaCard.swift          # Poster card component
    ├── LibraryView.swift        # Local watchlist
    └── SettingsView.swift       # API key + about
```

---

## Requirements

- iOS 16+
- Xcode 15+
- A free TMDB API Read Access Token
- No third-party packages needed — pure SwiftUI + WebKit
