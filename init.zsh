# shellcheck shell=bash
######################################################################
#<
#
# Function: p6df::modules::zoom::deps()
#
#>
######################################################################
p6df::modules::zoom::deps() {

  # shellcheck disable=2034
  ModuleDeps=(
    p6m7g8-dotfiles/p6common
  )
}

######################################################################
#<
#
# Function: p6df::modules::zoom::external::brew()
#
#>
######################################################################
p6df::modules::zoom::external::brew() {

  p6df::core::homebrew::cli::brew::install --cask zoom

  p6_return_void
}

######################################################################
#<
#
# Function: p6df::modules::zoom::mcp()
#
#>
#/ Synopsis
#/    Installs Zoom MCP server
#/
######################################################################
p6df::modules::zoom::mcp() {

  p6_js_npm_global_install "@prathamesh0901/zoom-mcp-server"

  p6_return_void
}

#  Environment:	 ZOOM_ACCOUNT_ID ZOOM_CLIENT_ID ZOOM_CLIENT_SECRET
######################################################################
#<
#
# Function: p6df::modules::zoom::mcp::env()
#
#  Environment:	 ZOOM_ACCOUNT_ID ZOOM_CLIENT_ID ZOOM_CLIENT_SECRET
#>
#/ Synopsis
#/    Maps Zoom profile env vars to MCP-specific vars
#/
######################################################################
p6df::modules::zoom::mcp::env() {

  if p6_string_blank_NOT "$ZOOM_CLIENT_ID"; then
    p6_env_export "ZOOM_CLIENT_ID"     "$ZOOM_CLIENT_ID"
    p6_env_export "ZOOM_CLIENT_SECRET" "$ZOOM_CLIENT_SECRET"
    p6_env_export "ZOOM_ACCOUNT_ID"    "$ZOOM_ACCOUNT_ID"
  else
    p6_env_export_un ZOOM_CLIENT_ID
    p6_env_export_un ZOOM_CLIENT_SECRET
    p6_env_export_un ZOOM_ACCOUNT_ID
  fi

  p6_return_void
}
