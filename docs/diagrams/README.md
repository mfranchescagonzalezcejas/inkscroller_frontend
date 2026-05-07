# InkScroller Diagrams

This folder contains editable product and architecture diagrams for InkScroller.

## Diagram index

| Diagram | Editable source | SVG | PNG | Purpose |
|---|---|---|---|---|
| UX/UI Flow | [`ux-ui-flow.drawio`](ux-ui-flow.drawio) | [`svg`](ux-ui-flow.svg) | [`png`](ux-ui-flow.png) | Connected user journey across navigation, reading, profile, and runtime states. |
| App Architecture | [`app-architecture.drawio`](app-architecture.drawio) | [`svg`](app-architecture.svg) | [`png`](app-architecture.png) | Clean Architecture, Riverpod, get_it, backend, and external dependencies. |
| Data Flow | [`data-flow.drawio`](data-flow.drawio) | [`svg`](data-flow.svg) | [`png`](data-flow.png) | UI → state → use case → repository → API/cache → UI state. |
| Auth + Profile Flow | [`auth-profile-flow.drawio`](auth-profile-flow.drawio) | [`svg`](auth-profile-flow.svg) | [`png`](auth-profile-flow.png) | Guest vs logged-in profile behavior, Firebase Auth, backend user endpoints, and preferences. |
| Reader + Offline Flow | [`reader-offline-flow.drawio`](reader-offline-flow.drawio) | [`svg`](reader-offline-flow.svg) | [`png`](reader-offline-flow.png) | Chapter source decisions, reader settings, cached pages, and reconnect guidance. |
| Deployment + Environment Flow | [`deployment-environment-flow.drawio`](deployment-environment-flow.drawio) | [`svg`](deployment-environment-flow.svg) | [`png`](deployment-environment-flow.png) | Flutter flavors, Firebase projects, API base URL resolution, and Railway/local backend targets. |
| Release Flow | [`release-flow.drawio`](release-flow.drawio) | [`svg`](release-flow.svg) | [`png`](release-flow.png) | Version bump, release script, semver tag, GitHub Actions, APK builds, GitHub Release, and Firebase App Distribution. |

## Export recommendation

- Keep `.drawio` as the editable source of truth.
- Export `.svg` for Markdown/docs.
- Export `.png` only as a fallback for Jira or previews.

Recommended naming:

```text
docs/diagrams/<name>.drawio
docs/diagrams/<name>.svg
docs/diagrams/<name>.png
```
