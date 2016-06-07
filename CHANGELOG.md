# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Added
- `--porcelain` flag that outputs script friendly output
- `show-dir` command that show the settings directory
### Fixed
- Documentation formatting consistency
- `link` command invalid error message about project directory
- `link` command not checking for missing project-name
- `sync` would always fail on conflict

## [0.1.2] - 2016-05-30
### Added
- Documentation on the list command
- Usage shown on no command
- Delete project command
- Self update command
### Fixed
- Argument order of find in list command

## [0.1.1] - 2016-05-16
### Added
- List projects command

## 0.1.0 - 2016-05-15
### Added
- Initial tool with init, track, link, commit and sync commands
- Initial README.md with instructions on how to install and use

[Unreleased]: https://github.com/MitMaro/ide-sync/compare/v0.1.2...HEAD
[0.1.2]: https://github.com/MitMaro/ide-sync/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/MitMaro/ide-sync/compare/v0.1.0...v0.1.1
