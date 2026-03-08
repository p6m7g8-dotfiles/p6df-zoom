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

p6df module for Zoom: video conferencing tooling, cask install, and MCP server
(`@prathamesh0901/zoom-mcp-server` via npm) with profile switching
(`ZOOM_CLIENT_ID`, `ZOOM_CLIENT_SECRET`, `ZOOM_ACCOUNT_ID`).

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
- `p6df::modules::zoom::mcp::env()`
  - Synopsis: Maps Zoom profile env vars to MCP-specific vars

## Hierarchy

```text
.
├── init.zsh
└── README.md

1 directory, 2 files
```

## Author

Philip M. Gollucci <pgollucci@p6m7g8.com>
