# Mondial 2026 - Project Instructions

## Environment & Deployment Workflow

This project uses a strict separation between Staging and Production environments.

### Staging (Development/Testing)
- **App Launch:** Run the app with the staging flag to enable the in-app Staging Panel (bug icon in the AppBar):
  `flutter run --dart-define=STAGING=true`
- **Firestore Rules:** Staging requires permissive rules to allow the client-side mock generator to work. Deploy the specific staging rules:
  `firebase deploy --only firestore:rules --rules firestore.staging.rules`

### Production (Release)
- **App Launch:** The app should be built without the staging flag. The Staging Panel will be completely hidden.
  `flutter build web` (or simply `flutter run -d chrome` without the dart-define flag)
- **Firestore Rules:** Production uses strict security rules. Always ensure the default rules are deployed:
  `firebase deploy --only firestore:rules`

**Reminder before any Production Release:** Always double-check that you are building without the `STAGING=true` flag and that the strict `firestore.rules` are deployed to the production database.

## Troubleshooting & Lessons Learned

*(This section is updated continuously whenever we solve a complex issue to save time in the future.)*

### MacBook Build Environment
*   **Issue:** Building the app on macOS/iOS can cause significant delays due to environment mismatches (e.g., specific versions of Ruby, CocoaPods, or Flutter dependencies).
*   **Solution:** *(Placeholder: À compléter avec la version exacte de Flutter, Ruby ou CocoaPods que nous avons stabilisée pour ce projet afin d'éviter de perdre du temps à l'avenir).*

### Firestore LevelDB Lock Error on macOS
*   **Issue:** The app crashes on startup with `FIRESTORE INTERNAL ASSERTION FAILED: Failed to open DB... LevelDB error: IO error: lock... Resource temporarily unavailable`. This occurs on macOS when a previous debug session crashes and leaves the local Firestore database locked.
*   **Solution:** Clear the local Firestore cache by running: `rm -rf "$HOME/Library/Application Support/firestore/__FIRAPP_DEFAULT"` and ensure no stray `Prono Challenge` processes are running in Activity Monitor.

### Timezone API on macOS
*   **Issue:** `FlutterTimezone.getLocalTimezone()` might return a string like `TimezoneInfo(Europe/Paris, ...)` instead of just `Europe/Paris`, causing `timezone` package to fail.
*   **Solution:** Manually parse the IANA ID from the returned string if it contains extra information.

### WCTooltip Assertion Error
*   **Issue:** Flutter's `Tooltip` widget throws `Assertion failed: (message == null) != (richMessage == null)` if both are null or both are provided.
*   **Solution:** Secure `WCTooltip` to return only the `child` if both are null, and prefer `richMessage` if both are provided.

### AppBar Overflow with ShaderMask
*   **Issue:** Using `ShaderMask` + `Flexible` + `Row` in the `AppBar` title can lead to massive layout overflows (98k+ pixels).
*   **Solution:** Ensure the `Row` has `mainAxisSize: MainAxisSize.min` and the `Text` child has `softWrap: false` and `maxLines: 1` to force the `Flexible` constraint to apply correctly without trying to expand to infinity.

### Data Ingestion & Integrity Standard (Anti-Pansement)
*   **Issue:** Performing isolated micro-patches on a single node (e.g. setting only the final match `m104` to Spain vs Argentina while parent matches `m93` to `m102` have contradictory teams/scores) creates absurd topological disconnects (e.g. a team crowned Champion without being in the final).
*   **Solution:** Never apply micro-patches when ground-truth datasets or screenshots are provided. Ingest and rebuild the entire data graph end-to-end (Source unique de vérité / SSOT).

### Topological Invariance Testing
*   **Issue:** Unit tests that only check superficial properties (e.g. `status == FINISHED`, `scores != null`) give a false sense of security while the relational tree is broken.
*   **Solution:** Enforce automated Topological Invariance Tests in `test/` asserting that every child match (`m89..m104`) strictly contains the verified winners/losers of its parent matches.

### Flutter Web Service Worker & CacheStorage Invalidation
*   **Issue:** Flutter Web's `flutter_service_worker.js` caches JSON assets in the browser's `CacheStorage`. Standard browser history clearing does not delete PWA CacheStorage, serving obsolete data to the user.
*   **Solution:** Include an automatic Service Worker unregister and `caches.delete()` script in `web/app.html` on boot and bump the local cache keys in `app_constants.dart`.


