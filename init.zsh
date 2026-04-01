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
#>
#/ Synopsis
#/    Installs echelon-ai-labs/zoom-mcp (Python) MCP server
#/
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
# Function: words zoom $ZOOM_CLIENT_ID = p6df::modules::zoom::profile::mod()
#
#  Returns:
#	words - zoom $ZOOM_CLIENT_ID
#
#  Environment:	 ZOOM_CLIENT_ID
#>
######################################################################
p6df::modules::zoom::profile::mod() {

  p6_return_words 'zoom' "$"
}
