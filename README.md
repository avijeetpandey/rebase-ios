# Rebase — Developer Social Network (iOS)

A native iOS application for **Rebase**, a social network built for developers. The app mirrors the GitHub iOS dark-mode aesthetic and connects to a REST backend for authentication, feeds, and social interactions.

---

## Features

| Area | Details |
|------|---------|
| **Auth** | Register + login, auto-refresh JWT, secure Keychain storage, restore session on launch |
| **Feed** | Commit posts with code snippets, image attachments, LGTM reactions, and comments |
| **Compose** | Rich post composer — freeform message, code snippet, optional image with client-side size safeguards |
| **Profile** | Profile fetch via `/profiles/{userId}`, avatar/bio, recent commits list |
| **Dark theme** | GitHub-faithful dark palette (`#000000` canvas, `#161B22` cards, `#2F81F7` accent) |

---

## Architecture

```
rebase-ios/
├── App/                        # Entry point, AppState, RootView, MainTabView
├── Core/
│   ├── Config/                 # AppConfig (base URL)
│   ├── Extensions/             # Date+Relative
│   ├── Networking/             # APIClient, APIRequest, APIEndpoints, APIError, HTTPMethod, MultipartFormDataBuilder
│   ├── Security/               # KeychainService, SessionStore, TokenStore protocol
│   └── Theme/                  # GitHubDarkTheme (Color extensions)
├── Features/
│   ├── Auth/                   # AuthViewModel, AuthViews (Login + SignUp)
│   ├── Compose/                # ComposeCommitViewModel, ComposeCommitView
│   ├── Feed/                   # FeedViewModel, FeedViews, CommentsViewModel, CommentsSheetView
│   └── Profile/                # ProfileViewModel, ProfileView
├── Models/                     # User, TokenPair, CommitPost, API envelope models, EmptyResponse, MockData
├── Services/                   # AuthService, PostService
└── Shared/                     # AvatarView, CodeSnippetView, RebaseInputFields
```

**Pattern**: MVVM with `@MainActor` view-models and `async/await` throughout.

---

## Networking

- Generic `APIClient.send<T: Decodable>(_ request: APIRequest<T>)` with `URLSession`
- Supports both envelope-wrapped responses (`{ isError, message, data }`) and flat JSON responses
- 401 responses trigger a transparent token refresh via `RefreshCoordinator` (Swift `actor`) before retrying the original request
- Tokens stored in the Keychain under `rebase.jwt.access` / `rebase.jwt.refresh`
- Multipart post uploads are built with `MultipartFormDataBuilder`

### API Contract Notes

- Base URL: `http://localhost:9000`
- Most endpoints return envelope-wrapped payloads
- `POST /api/v1/auth/login` and `POST /api/v1/auth/refresh` return flat `AuthResponse`
- `GET /api/v1/posts` returns Spring page payload in `data`
- `GET /api/v1/posts/{postId}/comments` is paginated (`page`, `size`) and comment body field is `content`
- `POST /api/v1/posts/{postId}/lgtm` returns `{ lgtmCount, lgtmed }`
- Backend image upload limit is 1 MB for `image` part

### Auth Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/auth/register` | Create account |
| `POST` | `/api/v1/auth/login` | Login → `{ accessToken, refreshToken, ... }` |
| `GET`  | `/api/v1/auth/me` | Fetch current user |
| `POST` | `/api/v1/auth/refresh` | Rotate tokens |
| `POST` | `/api/v1/auth/logout` | Invalidate session |

### Feed / Profile Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET`  | `/api/v1/posts?page=0&size=20` | Fetch feed page |
| `POST` | `/api/v1/posts` | Create post (`multipart/form-data`: `request` + optional `image`) |
| `POST` | `/api/v1/posts/{postId}/lgtm` | Toggle LGTM and receive updated count/state |
| `GET`  | `/api/v1/posts/{postId}/comments?page=0&size=20` | Fetch comments page |
| `POST` | `/api/v1/posts/{postId}/comments` | Add comment (`{ content: "..." }`) |
| `GET`  | `/api/v1/profiles/{userId}` | Fetch user profile |

---

## Requirements

| Dependency | Version |
|-----------|---------|
| Xcode | 15+ (tested with Xcode in `~/Downloads/Xcode.app`) |
| iOS Deployment Target | 18.2 |
| Swift | 5.10 |
| Backend | Running on `http://localhost:9000` |

No third-party Swift packages — pure Apple SDK.

---

## Getting Started

### 1. Start the backend

Ensure your Rebase backend server is running and accessible at `http://localhost:9000`.  
The base URL is configured in [`Core/Config/AppConfig.swift`](rebase-ios/Core/Config/AppConfig.swift):

```swift
static let baseURL = URL(string: "http://localhost:9000")!
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

```bash
xcrun simctl launch 03753A87-06A8-4E7F-9103-855D8709CB40 com.rebase.rebase-ios
```

And to kill it again:

```bash
xcrun simctl terminate 03753A87-06A8-4E7F-9103-855D8709CB40 com.rebase.rebase-ios
```

## Project Structure Notes

- The Xcode project uses `PBXFileSystemSynchronizedRootGroup` — any `.swift` file added to the correct folder on disk is automatically included in the build target without editing `project.pbxproj`.
- `Item.swift` (SwiftData template remnant) is intentionally unused and can be deleted.

---

## License

MIT
