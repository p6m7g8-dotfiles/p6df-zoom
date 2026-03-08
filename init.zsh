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

######################################################################
#<
#
# Function: p6df::modules::zoom::profile::on(profile, env_or_client_id, [client_secret=], [account_id=])
#
#  Args:
#	profile -
#	env_or_client_id -
#	OPTIONAL client_secret - []
#	OPTIONAL account_id - []
#
#  Environment:	 P6_DFZ_PROFILE_ZOOM ZOOM_ACCOUNT_ID ZOOM_CLIENT_ID ZOOM_CLIENT_SECRET
#>
######################################################################
p6df::modules::zoom::profile::on() {
  local profile="$1"
  local env_or_client_id="$2"
  local client_secret="${3:-}"
  local account_id="${4:-}"

  local client_id="$env_or_client_id"

  if p6_string_match_regex "$env_or_client_id" '(^|[[:space:]])export[[:space:]]+ZOOM'; then
    p6_run_code "$env_or_client_id"
    client_id="${ZOOM_CLIENT_ID:-}"
    client_secret="${ZOOM_CLIENT_SECRET:-$client_secret}"
    account_id="${ZOOM_ACCOUNT_ID:-$account_id}"
  fi

  p6_env_export "P6_DFZ_PROFILE_ZOOM"  "$profile"
  p6_env_export "ZOOM_CLIENT_ID"       "$client_id"
  p6_env_export "ZOOM_CLIENT_SECRET"   "$client_secret"
  p6_env_export "ZOOM_ACCOUNT_ID"      "$account_id"

  p6_return_void
}

######################################################################
#<
#
# Function: p6df::modules::zoom::profile::off()
#
#  Environment:	 P6_DFZ_PROFILE_ZOOM ZOOM_ACCOUNT_ID ZOOM_CLIENT_ID ZOOM_CLIENT_SECRET
#>
######################################################################
p6df::modules::zoom::profile::off() {

  p6_env_export_un P6_DFZ_PROFILE_ZOOM
  p6_env_export_un ZOOM_CLIENT_ID
  p6_env_export_un ZOOM_CLIENT_SECRET
  p6_env_export_un ZOOM_ACCOUNT_ID

  p6_return_void
}
