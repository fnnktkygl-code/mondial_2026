## 2025-06-07 - [Restrict WebView Navigation]
**Vulnerability:** InAppWebView's `shouldOverrideUrlLoading` unconditionally returned `NavigationActionPolicy.ALLOW`, allowing the WebView to navigate to any URL or custom scheme (e.g., `javascript:`, `intent:`).
**Learning:** Unrestricted WebView navigation is a significant security risk. If a loaded page is compromised or has an open redirect, it can be hijacked to execute unauthorized JavaScript or launch unintended apps/intents.
**Prevention:** Always validate URLs in `shouldOverrideUrlLoading`. Explicitly allow only secure schemes (`http`/`https`) and whitelist intended domains (e.g., `fifa.com`). Return `NavigationActionPolicy.CANCEL` by default for any other requests.
