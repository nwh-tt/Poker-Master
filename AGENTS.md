# Agent Guidelines for Poker Master (iOS)

## Scope
- This repository is an iOS app using Swift, SwiftUI, and SwiftData.
- Primary app sources live in `Poker Master/`.
- Unit tests live in `Poker MasterTests/`.
- UI tests live in `Poker MasterUITests/`.

## Tooling Notes
- This repo uses an Xcode project (`Poker Master.xcodeproj`).
- Commands below assume Xcode is installed and `xcodebuild` is available.
- The active scheme is expected to be `Poker Master` (see target name in the project).
- No SwiftPM `Package.swift` is present.
- No lint/format config files were found (no SwiftLint/SwiftFormat).

## Project Configuration
- The app target name is `Poker Master`; tests are `Poker MasterTests` and `Poker MasterUITests`.
- The app uses `Poker-Master-Info.plist` and a storyboard for launch screen.
- Keep `Ranges.json` bundled with the app; treat it as read-only content.
- Third-party SDKs include Firebase and RevenueCat; avoid modifying API keys casually.
- If you add new resources, ensure they are included in the app target.

## Build Commands
- Open the project in Xcode:
  - `open "Poker Master.xcodeproj"`
- Build via CLI:
  - `xcodebuild -project "Poker Master.xcodeproj" -scheme "Poker Master" -destination "platform=iOS Simulator,name=iPhone 15" build`
- Clean build (if needed):
  - `xcodebuild -project "Poker Master.xcodeproj" -scheme "Poker Master" -destination "platform=iOS Simulator,name=iPhone 15" clean build`

## Test Commands
- Run all unit tests:
  - `xcodebuild -project "Poker Master.xcodeproj" -scheme "Poker Master" -destination "platform=iOS Simulator,name=iPhone 15" test`
- Run just unit tests target:
  - `xcodebuild -project "Poker Master.xcodeproj" -scheme "Poker Master" -destination "platform=iOS Simulator,name=iPhone 15" -only-testing:"Poker MasterTests" test`
- Run a single test class:
  - `xcodebuild -project "Poker Master.xcodeproj" -scheme "Poker Master" -destination "platform=iOS Simulator,name=iPhone 15" -only-testing:"Poker MasterTests/AIPlayerTests" test`
- Run a single test method:
  - `xcodebuild -project "Poker Master.xcodeproj" -scheme "Poker Master" -destination "platform=iOS Simulator,name=iPhone 15" -only-testing:"Poker MasterTests/AIPlayerTests/testInitialValues" test`
- Run UI tests target:
  - `xcodebuild -project "Poker Master.xcodeproj" -scheme "Poker Master" -destination "platform=iOS Simulator,name=iPhone 15" -only-testing:"Poker MasterUITests" test`

## Lint / Format
- No linting or formatting tools are configured in this repo.
- If you add SwiftLint/SwiftFormat, document the commands here and add config files.

## Code Style Guidelines

### File Headers & Organization
- Keep the standard Xcode file header comment block.
- One primary type per file when practical.
- Use `// MARK:` sparingly to separate major sections.

### Imports
- Use one `import` per line.
- Prefer standard ordering (SwiftUI/SwiftData first, then Foundation/UIKit/etc.), but follow local file conventions.
- Avoid unused imports.

### Formatting
- Follow standard Swift formatting with braces on the same line.
- Keep indentation consistent with the file (most files use 4 spaces).
- Use a blank line between major sections (imports, types, extensions).
- Keep lines readable; wrap long argument lists or string interpolations.

### Naming
- Types: `UpperCamelCase` (e.g., `APIClient`, `AIPlayerTests`).
- Variables/functions: `lowerCamelCase` (e.g., `currentBetAmount`, `makeRequest`).
- Enums: `UpperCamelCase` with lowerCamelCase cases (e.g., `APIEnvironment.production`).
- Boolean names should read clearly (`isOutOfMoney`, `isReRaise`).
- Keep test names descriptive, start with `test`.

### Types & Access
- Prefer `struct` for SwiftUI views and value types; use `class` for reference types.
- Mark classes `final` when not intended to be subclassed.
- Keep properties `private` unless used externally.
- Avoid implicit unwrapping unless necessary (tests use `!` in `setUp`).

### SwiftUI Patterns
- Use `View` structs with a `var body: some View`.
- Use `@StateObject` / `@EnvironmentObject` for shared state (see `Poker_MasterApp`).
- Keep view bodies focused; extract subviews for complex layouts.
- Use `.task` for async startup work; avoid heavy work in initializers.

### SwiftUI Previews
- Use `#Preview` blocks at file bottom when helpful.
- Keep preview data lightweight and deterministic.

### SwiftData & Persistence
- Use `ModelContainer` and `ModelContext` for data access.
- Perform model writes on appropriate contexts; avoid blocking the main thread.
- Keep schema definitions centralized in app startup.
- Favor simple models with stored properties over heavy logic.

### Error Handling
- Use `throws` for async networking and data operations.
- Prefer `guard` with early return for invalid input.
- Use `Log` for diagnostics (see `Log.network` and `Log.preflopGame`).
- Reserve `fatalError` for unrecoverable initialization failures (see model container setup).

### Concurrency
- Prefer `async/await` for network calls and data operations.
- Avoid blocking main thread for long operations.
- If refreshing tokens or retrying requests, keep retries bounded.

### Networking
- Use `APIClient` for authenticated API calls.
- Always set `Content-Type` and `Authorization` headers consistently.
- Use typed request/response models; decode with `JSONDecoder`.

### Data & Models
- Models in `Models/` and `Models/DataModels/` use simple stored properties.
- Keep model logic minimal and deterministic where possible.
- Avoid hardcoding API keys; if you must touch keys, treat them as sensitive.

### Assets & Resources
- Add images/colors to the asset catalog and update usages accordingly.
- Keep `Launch Screen.storyboard` changes minimal and consistent with branding.

### Security & Secrets
- Do not commit credentials or downloaded user data.
- Treat Firebase/RevenueCat keys and tokens as sensitive.

### Logging
- Use `Log.<category>.<level>(...)` rather than `print`.
- Include enough context in log messages (path, status code, etc.).

### Tests
- Use `XCTestCase` classes in `Poker MasterTests/`.
- Keep `setUp`/`tearDown` symmetric and call `super`.
- Prefer explicit assertions (`XCTAssertEqual`, `XCTAssertTrue`, etc.).
- Keep tests isolated; avoid shared state across tests.

## Repo Layout
- `Poker Master/` — app sources (SwiftUI views, services, models, utils).
- `Poker MasterTests/` — unit tests.
- `Poker MasterUITests/` — UI tests.
- `Ranges.json` — bundled data file; treat as app content.

## Cursor/Copilot Rules
- No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md` files were found.
- If these are added later, include their instructions here verbatim.

## Agent Tips
- If you add new files, keep them under existing folders (`Views`, `Services`, `Models`).
- Avoid reformatting unrelated code; keep diffs minimal.
- Update this document if you introduce new tooling or conventions.
