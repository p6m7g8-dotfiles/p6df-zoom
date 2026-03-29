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
# Function: p6df::modules::zoom::external::brews()
#
#>
######################################################################
p6df::modules::zoom::external::brews() {

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

  p6df::modules::anthropic::mcp::server::add "zoom" "uvx" "zoom-mcp"
  p6df::modules::openai::mcp::server::add "zoom" "uvx" "zoom-mcp"

  p6_return_void
}

######################################################################
#<
#
# Function: p6df::modules::zoom::profile::on(profile, code)
#
#  Args:
#	profile -
#	code - shell code block (export ZOOM_CLIENT_ID=... ZOOM_CLIENT_SECRET=...)
#
#  Environment:	 P6_DFZ_PROFILE_ZOOM ZOOM_CLIENT_ID ZOOM_CLIENT_SECRET
#>
######################################################################
p6df::modules::zoom::profile::on() {
  local profile="$1"
  local code="$2"

  p6_run_code "$code"

  p6_env_export "P6_DFZ_PROFILE_ZOOM"  "$profile"
  p6_env_export "ZOOM_CLIENT_ID"       "${ZOOM_CLIENT_ID:-}"
  p6_env_export "ZOOM_CLIENT_SECRET"   "${ZOOM_CLIENT_SECRET:-}"

  p6_return_void
}

######################################################################
#<
#
# Function: p6df::modules::zoom::profile::off(code)
#
#  Args:
#	code - shell code block previously passed to profile::on
#
#  Environment:	 P6_DFZ_PROFILE_ZOOM ZOOM_CLIENT_ID ZOOM_CLIENT_SECRET
#>
######################################################################
p6df::modules::zoom::profile::off() {
  local code="$1"

  p6_env_unset_from_code "$code"
  p6_env_export_un P6_DFZ_PROFILE_ZOOM

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
    local token_file
    token_file=$(p6df::modules::zoom::oauth::token::file)
    if [[ ! -f "$token_file" ]]; then
      str="zoom:\t\t  $P6_DFZ_PROFILE_ZOOM:"
      str=$(p6_string_append "$str" "not authed" " ")
    else
      local expires_at now
      expires_at=$(p6_json_from_file "$token_file" | p6_json_eval -r '.expires_at // 0')
      now=$EPOCHSECONDS
      if (( now >= expires_at )); then
        if (( now - expires_at < 3600 )); then
          str="zoom:\t\t  $P6_DFZ_PROFILE_ZOOM:"
          str=$(p6_string_append "$str" "expired" " ")
        fi
      else
        local remaining=$(( expires_at - now ))
        str="zoom:\t\t  $P6_DFZ_PROFILE_ZOOM:"
        str=$(p6_string_append "$str" "ok" " ")
        str=$(p6_string_append "$str" "exp:$(( remaining / 60 ))m" " ")
      fi
    fi
  fi

  p6_return_str "$str"
}
