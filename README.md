# Rebase — Developer Social Network (iOS)

A native iOS application for **Rebase**, a social network built for developers. The app mirrors the GitHub iOS dark-mode aesthetic and connects to a REST backend for authentication, feeds, and social interactions.

---

## Features

| Area | Details |
|------|---------|
| **Auth** | Register, login (username + password), auto-refresh JWT, secure Keychain storage |
| **Feed** | Commit posts with code snippets, image attachments, LGTM reactions, and comments |
| **Compose** | Rich post composer — freeform message, code snippet with syntax highlighting, optional image |
| **Profile** | Avatar, bio, recent commits list |
| **Dark theme** | GitHub-faithful dark palette (`#000000` canvas, `#161B22` cards, `#2F81F7` accent) |

---

## Architecture

```
rebase-ios/
├── App/                        # Entry point, AppState, RootView, MainTabView
├── Core/
│   ├── Config/                 # AppConfig (base URL)
│   ├── Extensions/             # Date+Relative
│   ├── Networking/             # APIClient, APIRequest, APIEndpoints, APIError, HTTPMethod
│   ├── Security/               # KeychainService, SessionStore, TokenStore protocol
│   └── Theme/                  # GitHubDarkTheme (Color extensions)
├── Features/
│   ├── Auth/                   # AuthViewModel, AuthViews (Login + SignUp)
│   ├── Compose/                # ComposeCommitViewModel, ComposeCommitView
│   ├── Feed/                   # FeedViewModel, FeedViews, CommentsViewModel, CommentsSheetView
│   └── Profile/                # ProfileViewModel, ProfileView
├── Models/                     # User, TokenPair, CommitPost, APIEnvelope, EmptyResponse, MockData
└── Shared/                     # AvatarView, CodeSnippetView, RebaseInputFields
```

**Pattern**: MVVM with `@MainActor` view-models and `async/await` throughout.

---

## Networking

- Generic `APIClient.send<T: Decodable>(_ request: APIRequest<T>)` with `URLSession`
- All responses wrapped in `{ "data": T }` envelope (`APIEnvelope<T>`)
- 401 responses trigger a transparent token refresh via `RefreshCoordinator` (Swift `actor`) before retrying the original request
- Tokens stored in the Keychain under `rebase.jwt.access` / `rebase.jwt.refresh`

### Auth Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/auth/register` | Create account |
| `POST` | `/api/v1/auth/login` | Login → `{ data: { accessToken, refreshToken } }` |
| `GET`  | `/api/v1/auth/me` | Fetch current user |
| `POST` | `/api/v1/auth/refresh` | Rotate tokens |
| `POST` | `/api/v1/auth/logout` | Invalidate session |

---

## Requirements

| Dependency | Version |
|-----------|---------|
| Xcode | 15+ (tested with Xcode in `~/Downloads/Xcode.app`) |
| iOS Deployment Target | 18.2 |
| Swift | 5.10 |
| Backend | Running on `http://localhost:8080` |

No third-party Swift packages — pure Apple SDK.

---

## Getting Started

### 1. Start the backend

Ensure your Rebase backend server is running and accessible at `http://localhost:8080`.  
The base URL is configured in [`Core/Config/AppConfig.swift`](rebase-ios/Core/Config/AppConfig.swift):

```swift
static let baseURL = URL(string: "http://localhost:8080")!
```

### 2. Open in Xcode

```bash
open rebase-ios.xcodeproj
```

### 3. Run on Simulator

Select the **rebase-ios** scheme and any iPhone simulator (iPhone 17 / iOS 26 tested), then press **Run** (`⌘R`).

#### CLI build + launch (optional)

```bash
export DEVELOPER_DIR=/path/to/Xcode.app/Contents/Developer

xcodebuild \
  -project rebase-ios.xcodeproj \
  -scheme rebase-ios \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath .DerivedData \
  build

APP_PATH=$(find .DerivedData -name "rebase-ios.app" -not -path "*__preview*" | head -1)
SIMULATOR_UUID="<your-simulator-uuid>"

xcrun simctl install "$SIMULATOR_UUID" "$APP_PATH"
xcrun simctl launch "$SIMULATOR_UUID" com.rebase.rebase-ios
```

---

## App Icon

Generated at build time from a Core Graphics Swift script (`/tmp/gen_icon.swift`).  
The 1024×1024 PNG assets live in:

```
rebase-ios/Assets.xcassets/AppIcon.appiconset/
├── AppIcon-Light.png   # Default + tinted appearance
├── AppIcon-Dark.png    # Dark appearance
└── Contents.json
```

Design: dark `#0D1117` background with a GitHub-blue (`#2F81F7`) git-branch motif representing the rebase operation.

---

## Running locally
App killed. To launch it again from the terminal:

```xcrun simctl launch 03753A87-06A8-4E7F-9103-855D8709CB40 com.rebase.rebase-ios```

And to kill it again:

```xcrun simctl terminate 03753A87-06A8-4E7F-9103-855D8709CB40 com.rebase.rebase-ios```

## Project Structure Notes

- The Xcode project uses `PBXFileSystemSynchronizedRootGroup` — any `.swift` file added to the correct folder on disk is automatically included in the build target without editing `project.pbxproj`.
- `Item.swift` (SwiftData template remnant) is intentionally unused and can be deleted.

---

## License

MIT
