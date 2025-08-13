# Welcome to the Wultra Mobile Token SDK Flutter repository!

In this file, you'll find several topics that will help you with the contribution process, how to run tests, how to create pull requests and how to prepare a new release.

## Table of Contents
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Running Tests](#running-tests)
- [Creating a Pull Request](#creating-a-pull-request)
- [Preparing a New Release](#preparing-a-new-release)

## Getting Started

> [!WARNING]
> If you're not a Wultra employee or contractor, please fill out the [Wultra Contributor License Agreement](https://forms.gle/r715RoVDoji4GD7K7) before you start contributing.

> [!NOTE]
> We recommend development on the macOS platform, as the iOS simulator is only available on macOS. However, you can also develop on Windows or Linux, but you will need a Mac to build and test the iOS version of the SDK.

> [!NOTE]
> Our recommended IDE for development is [Visual Studio Code](https://code.visualstudio.com/) with [Flutter Extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter) installed.
>
> You can use other IDEs that are capable of Flutter development, but we recommend using Visual Studio Code for its simplicity and ease of use.

Before you start development, make sure you have the following prerequisites:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
- [Android Studio](https://developer.android.com/studio) installed for Android development.
- [Xcode](https://developer.apple.com/xcode/) (for iOS development) installed on your Mac.
- [CocoaPods](https://guides.cocoapods.org/using/getting-started.html) installed for iOS development.
- Flutter-capable IDE installed (Visual Studio Code with Flutter Extension is recommended).

## Project Structure

The project structure is organized as follows (the most important files and directories):

```
mtoken-sdk-flutter/
├── .github/                 # GitHub-related files (workflows, contributing guidelines)
├── docs/                    # Documentation files that will be published on developers.wultra.com
├── example/                 # Host application for the integration tests
│   ├── .env                 # Environment variables for the integration tests
│   ├── .env-example         # Example environment variables for the integration tests
│   ├── integration_test/    # Integration tests for the SDK
├── lib/                     # Main library code
│   ├── src/                 # Source code of the SDK
│   ├── mtoken_sdk_flutter.dart  # Public API of the SDK
|── scripts/                 # Scripts for building, testing, releasing
├── test/                    # Unit tests for the SDK
|── CHANGELOG.md             # Changelog of the SDK that is visible on pub.dev
├── pubspec.yaml             # Project metadata and dependencies
└── README.md                # Project overview and documentation
```

## Running Tests

Before you run the tests, make sure:
- the `example/.env` file is set up correctly. You can use the `.env-example` file as a reference.
  - variables needed can be provided by the Wultra team or your own development team in case of self-hosted environments
- dependencies in the `example` directory are installed by running `flutter pub get`.
- CocoaPods dependencies are installed for iOS by running `pod install` in the `example/ios` directory.

### Unit Tests

To run the unit tests, use the following command:

```bash
flutter test
```

### Integration Tests

Integration test are located in the `example/integration_test` directory.

> [!NOTE]
> To run the test on desired device, we recommend using the UI of the flutter extension in Visual Studio Code.
>
> When integration tests are run from the command line, the first available device is used. If you want to run the tests on a specific device, you can use the `-d` option with the device ID.

To run the integration tests, use the following command:

```bash
cd example # make sure you are in the example directory
flutter test -r expanded integration_test/integration_test.dart # test with expanded report
```

## Creating a Pull Request

> [!WARNING]
> Before you create a pull request make sure that: 
> 
> - an issue is created for the change you want to make. If there is no issue, create one first.
> - all unit tests and integration tests are passing.
> - `flutter analyze` does not report any issues.

0. If you're not a Wultra employee or contractor, fork the repository and make changes in your fork. If you're a Wultra employee or contractor, you can make changes directly in the repository.
1. Create a new branch for your changes. The branch name should follow the format `issues/issue-number-short-description`, e.g. `issues/123-fix-bug-in-inbox`.
2. Make your changes and commit them with a clear commit message that describes the changes you made.
3. Push your changes to the remote repository.
4. Create a pull request from your branch to the `develop` branch of the repository.
    - Pick a descriptive title for your pull request that summarizes the changes you made.
    -  In the pull request description, reference the issue you are addressing by using `#issue-number`, e.g. `#123`. This will automatically link the pull request to the issue.
    - If you're not a Wultra employee or contractor, wait for a Wultra team member to review your pull request and approve workflows to run.
    - If you're a Wultra employee or contractor, wait for all workflows to pass and then request review from a Wultra maintainer.

## Preparing a New Release

> [!WARNING]
> This section is intended for Wultra employees and contractors only. If you are not a Wultra employee or contractor, please do not attempt to prepare a new release.

### Some important notes regarding the release streams (branches)

- the `develop` branch is used for development and should not be used for releases
- each release stream should be created from the `develop` branch (can be specific commit in the history)
- naming of the release stream should follow the format `release/a.b.x`, e.g. `release/1.0.x`
- git history of the release stream should be always linear, i.e. no merge commits should be present in the history
- every change into the release stream should be done via a pull request that will be squashed and merged into the release stream

### Release Versioning

The version number is composed of three parts: `major.minor.patch`, e.g. `1.0.0`.

- The `major` version is incremented when a milestone is reached, e.g. a platform version is updated or major principle is changed.
- The `minor` version is incremented when a new feature is added or a significant change is made. Minor changes can be API incompatible, but they should not break existing functionality.
- The `patch` version is incremented when a bug fix is introduced. No API changes are allowed in patch releases, and they should not break existing functionality or introduce new features.

### Each release should contain following changes

- updated `pubspec.yaml` file with the new version number
- updated `lib/src/core/version.dart` file with the new version number
- updated `CHANGELOG.md` file with the new version number and a summary of the changes for pub.dev
- updated `docs/changelog.md` file with the new version number and a summary of the changes for Wultra developers documentation
- _(if needed)_ updated `docs/Readme.md` file with the new version and compatibility information
- _(if needed)_ updated `docs/SDK-Integration.md` file with the new version and compatibility information

> [!TIP]
> You can use the `scripts/prepare-release.sh` script to prepare all the necessary files for a new release.
> 
> If you pass a `--verify` flag to the script, it will check if all the files are updated correctly and will not allow you to proceed with the release if any of the files are not updated.

### Creating a Release (example scenario)

> [!NOTE]
> This scenario describes how to create a new `1.2.0` release of the SDK from the HEAD of the `develop` branch.

1. Create an issue for the new release, e.g. `Prepare release 1.2.0`. Add info what is the reason for the release.
2. Prepare new branch from `develop` branch without any changes (if a release branch does not exist yet) and push it to the remote repository without any changes. Release branches are protected and can be created only by Wultra employees or contractors.:
    - `git checkout develop`
    - `git pull origin develop`
    - `git checkout -b release/1.2.x`
- `git push -u origin release/1.2.x`
3. Create a new branch for the exact release (for example `issues/65-prepare-release-1_2_0`).
4. Make sure that all the files mentioned in the [each release should contain following changes](#each-release-should-contain-following-changes) section are updated correctly.
5. Commit the changes with a clear commit message, e.g. `Prepare release 1.2.0`.
6. Push the changes to the remote repository.
7. Create a pull request from the `issues/65-prepare-release-1_2_0` branch to the `release/1.2.x` branch.
    - The pull request title should be `Prepare release 1.2.0`.
    - The pull request description should reference the issue you created in the first step, e.g. `#65`.
8. Wait for the pull request to be reviewed and approved by a Wultra team member.
9. Once the pull request is approved, merge it into the `release/1.2.x` branch using the "Squash and merge" option. This will ensure that the git history is linear, and the commit message is clear.
10. Run the `Release` GitHub action to create a new tag and publish the release:
    - Go to the "Actions" tab in the GitHub repository.
    - Select the "Release" workflow.
    - Click on "Run workflow" and select the `release/1.2.x` branch.
    - Enter the version number `1.2.0` in the `version` input field.
    - Enter the pub.dev token in the `pubDevToken` input field. This ensures that the released will link the release to the user who created it.
    - Click on "Run workflow" button to start the workflow.
    - Wait for the workflow to finish. It will create a new tag in the format `1.2.0` and push it to the remote repository.
    - If the tag or release already exists, the workflow will fail, and you need to fix the issue before proceeding.
    - If the release gets stuck (for example only tag is created, but no release is created), you need to contact a repository maintainer to fix the issue manually.
11. Create a new release on GitHub:
    - Go to the "Releases" section of the repository.
    - Click on "Draft a new release".
    - Select the `1.2.0` tag you just created.
    - Fill in the release title and description. The description should contain a summary of the changes made in the release, which can be copied from the `CHANGELOG.md` file.
12. Verify that the release is published on pub.dev
