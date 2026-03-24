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
    p6m7g8-dotfiles/p6df-darwin
    p6m7g8-dotfiles/p6df-python
  )
}

######################################################################
#<
#
# Function: p6df::modules::zoom::init(module, dir)
#
#  Args:
#	module -
#	dir -
#>
######################################################################
p6df::modules::zoom::init() {
  local _module="$1"
  local dir="$2"

  p6_bootstrap "$dir"

  p6_return_void
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
#/ Synopsis
#/    Installs echelon-ai-labs/zoom-mcp (Python) MCP server
#/
#>
######################################################################
p6df::modules::zoom::mcp() {

  p6_python_uv_tool_install "zoom-mcp @ https://github.com/echelon-ai-labs/zoom-mcp"

  p6_return_void
}

######################################################################
#<
#
# Function: p6df::modules::zoom::profile::on(profile, env_or_client_id, [client_secret=])
#
#  Args:
#	profile -
#	env_or_client_id -
#	OPTIONAL client_secret - []
#
#  Environment:	 P6_DFZ_PROFILE_ZOOM ZOOM_CLIENT_ID ZOOM_CLIENT_SECRET
#>
######################################################################
p6df::modules::zoom::profile::on() {
  local profile="$1"
  local env_or_client_id="$2"
  local client_secret="${3:-}"

  local client_id="$env_or_client_id"

  if p6_string_match_regex "$env_or_client_id" '(^|[[:space:]])export[[:space:]]+ZOOM'; then
    p6_run_code "$env_or_client_id"
    client_id="${ZOOM_CLIENT_ID:-}"
    client_secret="${ZOOM_CLIENT_SECRET:-$client_secret}"
  fi

  p6_env_export "P6_DFZ_PROFILE_ZOOM"  "$profile"
  p6_env_export "ZOOM_CLIENT_ID"       "$client_id"
  p6_env_export "ZOOM_CLIENT_SECRET"   "$client_secret"

  p6_return_void
}

######################################################################
#<
#
# Function: p6df::modules::zoom::profile::off()
#
#  Environment:	 P6_DFZ_PROFILE_ZOOM ZOOM_CLIENT_ID ZOOM_CLIENT_SECRET
#>
######################################################################
p6df::modules::zoom::profile::off() {

  p6_env_export_un P6_DFZ_PROFILE_ZOOM
  p6_env_export_un ZOOM_CLIENT_ID
  p6_env_export_un ZOOM_CLIENT_SECRET

  p6_return_void
}

######################################################################
#<
#
# Function: str str = p6df::modules::zoom::prompt::mod()
#
#  Returns:
#	str - str
#
#  Environment:	 P6_DFZ_PROFILE_ZOOM
#>
######################################################################
p6df::modules::zoom::prompt::mod() {
  local str

  if p6_string_blank_NOT "$P6_DFZ_PROFILE_ZOOM"; then
    str="zoom:\t\t  $P6_DFZ_PROFILE_ZOOM:"

    local token_file
    token_file=$(p6df::modules::zoom::oauth::token::file)
    if [[ ! -f "$token_file" ]]; then
      str=$(p6_string_append "$str" "not authed" " ")
    else
      local expires_at now
      expires_at=$(jq -r '.expires_at // 0' "$token_file")
      now=$(date +%s)
      if (( now >= expires_at )); then
        str=$(p6_string_append "$str" "expired" " ")
      else
        local remaining=$(( expires_at - now ))
        str=$(p6_string_append "$str" "ok" " ")
        str=$(p6_string_append "$str" "exp:$(( remaining / 60 ))m" " ")
      fi
    fi
  fi

  p6_return_str "$str"
}
