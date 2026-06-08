# Release Process

This repository currently releases from GitHub Releases, not from git tag pushes.

## Trigger

The release workflow is defined in [.github/workflows/release-macos.yml](/Users/tim.haselaars/Sites/mac-apps/TypePaste/TypePaste/.github/workflows/release-macos.yml).

It runs when a GitHub Release is published:

```yaml
on:
  release:
    types: [published]
```

That means the workflow starts after creating or publishing a release in GitHub, and it uses the release tag name as the app version source.

## What The Workflow Does

1. Checks out the repository.
2. Reads `github.event.release.tag_name`.
3. Derives `VERSION` from the tag by stripping a leading `v`.
4. Builds the macOS app from `TypePaste/TypePaste.xcodeproj` using the `TypePaste` scheme in `Release` configuration.
5. Disables code signing for the CI build.
6. Overrides:
   - `MARKETING_VERSION` with the release version
   - `CURRENT_PROJECT_VERSION` with `GITHUB_RUN_NUMBER`
7. Packages the built app as:
   - `TypePaste-<version>.zip`
   - `TypePaste-<version>.dmg`
8. Uploads both artifacts to the GitHub Release.
9. Downloads the generated DMG in a second job.
10. Computes its SHA256 checksum.
11. Checks out the shared Homebrew tap repository: `trinixlabs/homebrew-tap`.
12. Updates `Casks/typepaste.rb` with:
   - the new version
   - the new DMG SHA256
   - the GitHub Release download URL
13. Commits and pushes the cask update to the tap repository.

## Expected Release Tag Format

The workflow supports both of these formats:

- `v1.2.3`
- `1.2.3`

The uploaded files are named with the normalized version value:

- `TypePaste-1.2.3.zip`
- `TypePaste-1.2.3.dmg`

## How To Publish A Release

1. Push the code you want to release.
2. Create a tag for the release, for example `v1.2.3`.
3. Push the tag.
4. In GitHub, create or publish a Release for that tag.
5. Once published, the workflow will build artifacts and attach them to the release.

If the release already exists as a draft, publishing that draft is enough to trigger the workflow.

## Required GitHub Secrets

The Homebrew tap update job depends on:

- `HOMEBREW_TAP_TOKEN`

That token must be able to:

- download the just-created GitHub Release asset
- clone `trinixlabs/homebrew-tap`
- push changes to the tap repository

Without that secret, the release asset build can still succeed, but the cask update job will fail.

## Produced Artifacts

Each successful release uploads:

- a ZIP archive of `TypePaste.app`
- a DMG containing `TypePaste.app` and an `Applications` symlink

## How The DMG Is Built

The DMG is assembled directly in the release workflow, not by a separate packaging tool.

### Staging layout

The workflow creates a temporary folder:

- `build/dmg-stage`

It then copies:

- `TypePaste.app` into that staging folder
- a symlink named `Applications` pointing to `/Applications`

That means the final DMG is the standard drag-to-install layout:

- `TypePaste.app`
- `Applications` shortcut

### DMG creation command

The workflow runs:

```bash
hdiutil create \
  -volname "TypePaste ${VERSION}" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  "dist/$DMG_NAME"
```

Important details:

- `UDZO` means a compressed read-only DMG
- the mounted volume name is versioned, for example `TypePaste 1.2.3`
- there is no custom background image, icon layout, or Finder styling

### Signing implications

The CI build disables code signing:

- `CODE_SIGNING_ALLOWED=NO`
- `CODE_SIGNING_REQUIRED=NO`
- `CODE_SIGN_IDENTITY=""`

So the app inside both the ZIP and DMG is an unsigned build artifact. This is consistent with the current README instructions that tell users to open the app manually or remove quarantine attributes if Gatekeeper blocks it.

## How Homebrew Works In This Setup

This repository does not contain the cask itself. Instead, the workflow updates a cask in the shared tap repository:

- `trinixlabs/homebrew-tap`
- expected cask path: `Casks/typepaste.rb`

### What this repo is responsible for

After the release job uploads `TypePaste-<version>.dmg`, the `update-cask` job:

1. Downloads that exact DMG from the GitHub Release.
2. Computes its SHA256 checksum.
3. Builds the public release URL:

```text
https://github.com/trinixlabs/typepaste/releases/download/<tag>/TypePaste-<version>.dmg
```

4. Updates the tap cask fields:
   - `version`
   - `sha256`
   - `url`

5. Commits and pushes the cask update to the tap’s `main` branch.

### What the cask must do

For this flow to work, the cask in the tap needs to install from the DMG URL that the workflow writes. At minimum, it should be compatible with:

- a DMG asset named `TypePaste-<version>.dmg`
- an app bundle named `TypePaste.app`

The workflow assumes those names are stable. If `pulse` uses different names, the workflow and cask update logic must be changed together.

## Porting This To Another App

If you want to reuse this release model for `pulse`, these are the parts to copy and rename:

### In the build-and-release job

- Xcode project path
- scheme name
- output app name
- ZIP filename
- DMG filename
- DMG volume name

### In the update-cask job

- tap repository name
- cask file path
- release download URL path
- commit message

### In the external tap cask

- cask token
- URL pattern
- SHA field
- installed app name

## Current Constraints And Risks

### Unsigned release artifacts

The current flow intentionally publishes unsigned app builds. That is workable, but it means:

- users can hit Gatekeeper friction
- Homebrew install is not equivalent to a signed/notarized Mac distribution
- the README needs to keep the current manual-open and quarantine-removal guidance

### Release trigger timing

The workflow runs only after a GitHub Release is published. If a tag exists without a published release, nothing happens.

### External tap dependency

The Brew path depends on an external repository and token:

- if `HOMEBREW_TAP_TOKEN` is missing or under-scoped, the cask update fails
- if the cask file layout changes in the tap, this workflow breaks
- this repo alone is not the whole release system; the tap repo is part of the deployment contract

## PR Test Workflow

This repository now also has a pull request workflow in [.github/workflows/tests.yml](/Users/tim.haselaars/Sites/mac-apps/TypePaste/TypePaste/.github/workflows/tests.yml).

It runs the `TypePasteTests` unit test target on every PR using `xcodebuild test`.
