# Streambert iOS

A **SwiftUI** iOS port of [Streambert](https://github.com/bnb549/streambert) — stream Movies, TV Series, and Anime using TMDB metadata and VidSrc, Videasy, and Vidking video sources.

---

## Features

- Trending movies and TV on the home screen
- Search across movies and TV (people and incomplete results are filtered)
- Detailed view with poster, overview, rating, and library toggle
- Local watchlist shared across screens (stored in UserDefaults)
- For TV shows, pick a season and episode before stream buttons appear
- Full-screen WKWebView player
- Settings to update the TMDB token

---

## Setup in Xcode

1. Clone this repo
2. Open `StreambertiOS.xcodeproj`
3. Build & run on your iPhone or simulator (iOS 16+)
4. On first launch, paste your free **TMDB API Read Access Token** (the long JWT that starts with `eyJ`)
   - Get one at https://www.themoviedb.org/settings/api
   - The app sends it as a Bearer header. A short v3 API key is also accepted as a query parameter.

---

## Stream Sources

Current embed providers:

- **VidSrc** — `vsembed.su`
- **Videasy** — `player.videasy.to`
- **Vidking** — `vidking.net`

TV titles require a selected season and episode; otherwise no stream URL is generated.

---

## Project Structure

```
StreambertiOS/
├── StreambertiOSApp.swift       # App entry point + environment objects
├── Models/
│   ├── MediaItem.swift          # Movie/TV data model
│   └── TVSeason.swift           # Season & Episode models
├── Services/
│   ├── APIKeyStore.swift        # Stores TMDB key in UserDefaults
│   ├── TMDBService.swift        # TMDB API calls (Bearer token support, null-safe decoding)
│   └── StreamSources.swift      # VidSrc / Videasy / Vidking URLs
└── Views/
    ├── SetupView.swift          # First-launch API key screen
    ├── ContentView.swift        # Tab bar
    ├── HomeView.swift           # Trending rows
    ├── SearchView.swift         # Search
    ├── MediaDetailView.swift    # Detail + stream buttons (episode picker for TV)
    ├── TVSeasonPicker.swift     # Season & episode picker
    ├── PlayerView.swift         # WKWebView full-screen player
    ├── MediaCard.swift          # Poster card component
    ├── LibraryView.swift        # Local watchlist (shared LibraryStore)
    └── SettingsView.swift       # API key + about
```

---

## Requirements

- iOS 16+
- Xcode 15+
- A free TMDB API Read Access Token
- No third-party packages — pure SwiftUI + WebKit

---

## Notes

- Playback relies on third-party embed sites. Availability and quality can change.
- Watchlist is local only (UserDefaults).
- TMDB multi-search and trending can return people or null fields; the app filters those out so only valid movie/TV items appear.
