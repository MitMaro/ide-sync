# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [0.3.0] - 2018-04-01
#### Fixed
- `sync`, `track`, `commit` and `delete` commands would trigger git hooks

## [0.2.0] - 2016-06-06
### Added
- `--porcelain` flag that outputs script friendly output
- `show-dir` command that show the settings directory
### Changed
- `sync` now commits before trying sync
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

[Unreleased]: https://github.com/MitMaro/ide-sync/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/MitMaro/ide-sync/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/MitMaro/ide-sync/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/MitMaro/ide-sync/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/MitMaro/ide-sync/compare/v0.1.0...v0.1.1
