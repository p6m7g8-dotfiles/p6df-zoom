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

TODO: Add a short summary of this module.

## Contributing

- [How to Contribute](<https://github.com/p6m7g8-dotfiles/.github/blob/main/CONTRIBUTING.md>)

## Code of Conduct

- [Code of Conduct](<https://github.com/p6m7g8-dotfiles/.github/blob/main/CODE_OF_CONDUCT.md>)

## Usage

### Functions

#### p6df-zoom

##### p6df-zoom/init.zsh

- `p6df::modules::zoom::deps()`
- `p6df::modules::zoom::external::brews()`
- `p6df::modules::zoom::mcp()`
  - Synopsis: Installs echelon-ai-labs/zoom-mcp (Python) MCP server
- `words zoom = p6df::modules::zoom::profile::mod()`

#### p6df-zoom/lib

##### p6df-zoom/lib/auth.sh

- `p6df::modules::zoom::api::call(method, path, [data=])`
  - Synopsis: Make an authenticated Zoom REST API v2 call
  - Args:
    - method - HTTP method (GET POST PATCH PUT DELETE)
    - path - API path e.g. /users/me/meetings
    - OPTIONAL data - []
- `p6df::modules::zoom::oauth::code::exchange(code, redirect_uri)`
  - Synopsis: Exchange authorization code for access + refresh tokens and persist.
  - Args:
    - code - authorization code from redirect
    - redirect_uri - must match app configuration
- `p6df::modules::zoom::oauth::login()`
  - Synopsis: Start OAuth authorization code flow: open browser, capture code via local redirect server, exchange for to
- `p6df::modules::zoom::oauth::token::refresh()`
  - Synopsis: Use stored refresh_token to obtain a new access token and persist.
- `p6df::modules::zoom::oauth::tokens::save(response)`
  - Synopsis: Persist access_token, refresh_token, and expiry to disk.
  - Args:
    - response - JSON response from token endpoint
- `str path = p6df::modules::zoom::oauth::token::file()`
- `str token = p6df::modules::zoom::oauth::token()`
  - Synopsis: Return a valid access token, refreshing if expired. Run p6df::modules::zoom::oauth::login first if no toke

## Hierarchy

```text
.
├── init.zsh
├── lib
│   └── auth.sh
└── README.md

2 directories, 3 files
```

## Author

Philip M. Gollucci <pgollucci@p6m7g8.com>
