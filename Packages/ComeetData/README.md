# ComeetData

Native Swift repository for the Comeet API: `ComeetRepository` is the Sendable app-facing contract; `APIClient` is its actor implementation. Inject `HTTPTransport` and `SessionPersistence` to isolate tests. Production defaults use URLSession and Keychain. UI observation stays outside this package.

Identity JSON uses camelCase; domain endpoints preserve snake_case. Birthdays are calendar-date strings. `WireDates.decoder()` accepts UTC timestamps with or without fractions. The client refreshes expired tokens, coalesces concurrent refreshes, retries a protected request once after 401, and rejects responses from a prior account generation. Writes propagate errors; message UUIDs make explicit retries safe.

Run `swift test --package-path Packages/ComeetData` from the repository root. The same tests are compiled into the app's `ComeetTests` target for iOS simulator verification. The real HTTP test is opt-in through `COMEET_INTEGRATION_URL` and `COMEET_INTEGRATION_PASSWORD`; it requires disposable seeded demo accounts and deletes them.

Shared contracts, ownership, hosted behavior gaps, and verification instructions: [API migration](../../../Comeet-API/docs/features/api-data-migration.md).
