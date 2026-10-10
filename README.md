# Comeet iOS

SwiftUI client for Comeet. Shared product/architecture context lives in [Comeet-API/docs](../Comeet-API/docs/README.md). Active data access uses the Comeet API through the local `Packages/ComeetData` Swift package. Supabase and obsolete Firebase clients/resources are removed.

## Development and tests

Use Xcode 27 / Swift 6.4. The app retains its iOS 17 deployment minimum. Open `Comeet.xcworkspace`, select `Comeet-Debug`, and an installed iOS 27 simulator.

Run the local API at `http://localhost:5158`; see [API setup](../Comeet-API/README.md). Debug uses this address. Set the `COMEET_API_BASE_URL` build setting to the actual HTTPS service URL for Release; the checked-in Release value is a placeholder. The app only permits HTTPS or loopback HTTP base URLs, with ATS local-networking support. Physical-device development needs a trusted HTTPS API address.

```sh
DEVELOPER_DIR=/Applications/Xcode-27.0.0.app/Contents/Developer \
  xcodebuild -workspace Comeet.xcworkspace -scheme Comeet-Debug \
  -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -derivedDataPath /tmp/comeet-ios-tests CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- test
```

Ad hoc simulator signing enables the native Keychain test without a device provisioning profile. An unsigned build is sufficient for compilation, but an unsigned test host cannot use Keychain.

The shared schemes include the `ComeetTests` target. It runs native Swift Testing for the HTTP repository and app adapters. The data package can also be tested independently:

```sh
DEVELOPER_DIR=/Applications/Xcode-27.0.0.app/Contents/Developer \
  swift test --package-path Packages/ComeetData --scratch-path /tmp/comeet-data-tests
```

No account/backend configuration is required for isolated tests. An opt-in real HTTP test and synthetic demo setup are documented in the shared [migration map](../Comeet-API/docs/features/api-data-migration.md). Production SMTP, public API hosting, and the weekly matching rules still need configuration/specification.

## Code map

- `Packages/ComeetData`: Sendable repository protocol, immutable wire models, actor client, URLSession transport, Keychain sessions, Swift Testing.
- `Comeet/Controllers/SessionStore.swift`: main-actor authentication/profile UI state and API address.
- `UserService` / `MessageService`: existing UI-facing service interfaces adapted to the repository.
- `Comeet/Models`: domain/UI adapters for users, matches, conversations, and messages.
- `Comeet/Views`: existing screens, now calling API-backed operations. Profile edits and attribute answers persist before showing success.

Chat loads paginated history then polls while active; leaving chat or backgrounding the app cancels its structured task. Tokens are stored only in Keychain. Existing UI packages remain to keep the migration scoped to data access.
