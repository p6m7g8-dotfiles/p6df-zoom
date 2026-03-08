# P6's POSIX.2: p6df-zoom

## Table of Contents

- [Badges](#badges)
- [Summary](#summary)
- [Contributing](#contributing)
- [Code of Conduct](#code-of-conduct)
- [Usage](#usage)
  - [Functions](#functions)
- [Hierarchy](#hierarchy)
- [Author](#author)

## Badges

[![License](https://img.shields.io/badge/License-Apache%202.0-yellowgreen.svg)](https://opensource.org/licenses/Apache-2.0)

## Summary

Integrates Zoom into the p6df shell framework. Provides `profile::on` / `profile::off`
for managing `ZOOM_CLIENT_ID`, client secret, and account ID, plus MCP server installation.

## Contributing

- [How to Contribute](<https://github.com/p6m7g8-dotfiles/.github/blob/main/CONTRIBUTING.md>)

## Code of Conduct

- [Code of Conduct](<https://github.com/p6m7g8-dotfiles/.github/blob/main/CODE_OF_CONDUCT.md>)

## Usage

### Functions

#### p6df-zoom

##### p6df-zoom/init.zsh

- `p6df::modules::zoom::deps()`
- `p6df::modules::zoom::external::brew()`
- `p6df::modules::zoom::mcp()`
  - Synopsis: Installs Zoom MCP server
- `p6df::modules::zoom::profile::off()`
- `p6df::modules::zoom::profile::on(profile, env_or_client_id, [client_secret=], [account_id=])`
  - Args:
    - profile
    - env_or_client_id
    - OPTIONAL client_secret - []
    - OPTIONAL account_id - []

## Hierarchy

```text
.
├── init.zsh
└── README.md

1 directory, 2 files
```

## Author

Philip M. Gollucci <pgollucci@p6m7g8.com>
