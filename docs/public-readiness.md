# Public Readiness Checklist

This document tracks the work required before changing `inkscroller_flutter` to public visibility.

Related issue: [#132 — prepare frontend repository for public visibility](https://github.com/mfranchescagonzalezcejas/inkscroller_flutter/issues/132)

## Goal

Make the repository public **without** leaking secrets, private operational context, internal-only assets, or non-shareable history.

## What should be public

The following categories are expected to remain public once sanitized:

- Flutter application source under `lib/`
- tests under `test/`
- technical documentation under `docs/`
- GitHub workflows and templates under `.github/`
- reproducible setup and release guidance
- architecture and implementation decisions that help others understand the project

## What must stay private or out of the repository

- real secrets, tokens, and credentials
- service-account files and raw secret JSON payloads
- real `.env` or `.dart-defines` values
- local vault artifacts, personal planning notes, and internal-only operational material
- screenshots, logs, or evidence files containing sensitive or private information
- assets whose license or publication rights are not yet verified

## Checklist

### 1. Secrets and credentials

- [ ] Confirm there are no real secrets in `.env*`, `.dart-defines/*`, Firebase config files, service accounts, docs, scripts, or tests.
- [ ] Audit git history for previously committed secrets.
- [ ] Rotate any secret that may have existed in repository history.

### 2. Public vs private configuration

- [ ] Keep only sanitized examples such as `.env.example` and `.dart-defines/firebase.example.json`.
- [ ] Document required environment variables and how they are injected.
- [ ] Ensure the project can be understood and bootstrapped without private values.

> Firebase real configuration files (`android/app/src/*/google-services.json`, `ios/config/*/GoogleService-Info.plist`) must be injected locally or via CI secrets and must never be committed. `ios/Runner/GoogleService-Info.plist` is treated as build artifact in bundle/copy flow, not as a committable source-of-truth path. Android builds use Dart `--dart-define-from-file` Firebase options as the public-safe path; the Google Services Gradle plugin is applied only when a local `google-services.json` file exists.

### 3. Documentation cleanup

- [ ] Rewrite or update the README for a public audience.
- [ ] Remove private local paths, internal-only notes, and non-shareable operational context from docs.
- [ ] Review docs for copied values, screenshots, and environment-specific references.

### 4. Assets and licensing

- [ ] Review logos, fonts, images, mocks, and bundled media assets.
- [ ] Confirm which assets can legally be published.
- [ ] Replace or remove assets with unclear licensing.
- [ ] Define the repository license explicitly.

### 5. Git history and metadata

- [ ] Review commit history for leaked secrets or internal-only material.
- [ ] Review workflows, templates, editor files, and hidden files for private references.
- [ ] Validate `.gitignore` against local-only artifacts.

### 6. CI/CD and release workflows

- [ ] Ensure public workflows do not leak secrets through logs.
- [ ] Confirm release automation remains safe when the repository is public.
- [ ] Document which workflows require secrets and which are safe for public contributors.

### 7. Functional security review

- [ ] Verify the frontend does not hardcode secrets or sensitive endpoints.
- [ ] Re-check flavors, Firebase options, network config, and launch configs.
- [ ] Confirm secret-sensitive tests are deterministic and cross-platform.

### 8. Private material separation

- [ ] Keep Obsidian vault artifacts, personal planning notes, and internal operational material out of the repository.
- [ ] Remove or relocate private screenshots, logs, and evidence files.
- [ ] Leave only reproducible, shareable engineering artifacts in the repository.

## Definition of done

- [ ] Repo tree is sanitized for public visibility.
- [ ] Git history review is complete.
- [ ] Secret scan is complete.
- [ ] Docs are public-safe.
- [ ] Asset and license review is complete.
- [ ] Visibility can be changed without leaking private material.

## Notes

- Public visibility should happen only after this checklist is complete.
- Normal branch/tag history has been purged as part of INK-73; hidden platform PR/MR refs remain a documented residual risk unless the hosting provider removes them or the repository is recreated.
- Firebase key rotation is recommended before public visibility; if deferred, keep API keys restricted and document the residual risk.
