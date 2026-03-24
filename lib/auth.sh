# shellcheck shell=bash

# Token cache file
_P6DF_ZOOM_TOKEN_FILE="${HOME}/.config/p6df/zoom_tokens.json"

######################################################################
#<
#
# Function: p6df::modules::zoom::oauth::login()
#
#/ Synopsis
#/    Start OAuth authorization code flow: open browser, capture code
#/    via local redirect server, exchange for tokens, persist to disk.
#/
#  Environment: ZOOM_CLIENT_ID ZOOM_CLIENT_SECRET
#>
######################################################################
p6df::modules::zoom::oauth::login() {

  local redirect_uri="http://localhost:4000"
  local auth_url="https://zoom.us/oauth/authorize?response_type=code&client_id=${ZOOM_CLIENT_ID}&redirect_uri=${redirect_uri}"

  p6_msg "Opening browser for Zoom OAuth..."
  open "$auth_url"

  p6_msg "Waiting for redirect on ${redirect_uri} ..."
  local raw
  raw=$(echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<html><body>Auth complete. Return to terminal.</body></html>" \
    | nc -l 4000 2>/dev/null | head -1)

  local code
  code=$(printf '%s' "$raw" | sed 's/GET \/\?code=//;s/ .*//')

  if [[ -z "$code" ]]; then
    p6_error "Failed to capture OAuth code"
    p6_return_void
  fi

  p6df::modules::zoom::oauth::_exchange_code "$code" "$redirect_uri"

  p6_return_void
}

######################################################################
#<
#
# Function: p6df::modules::zoom::oauth::_exchange_code(code, redirect_uri)
#
#/ Synopsis
#/    Exchange authorization code for access + refresh tokens and persist.
#/
#  Args:
#	code         - authorization code from redirect
#	redirect_uri - must match app configuration
#
#  Environment: ZOOM_CLIENT_ID ZOOM_CLIENT_SECRET
#>
######################################################################
p6df::modules::zoom::oauth::_exchange_code() {
  local code="${1:?requires code}"
  local redirect_uri="${2:?requires redirect_uri}"

  local response
  response=$(curl -s -X POST \
    "https://zoom.us/oauth/token?grant_type=authorization_code&code=${code}&redirect_uri=${redirect_uri}" \
    -u "${ZOOM_CLIENT_ID}:${ZOOM_CLIENT_SECRET}")

  p6df::modules::zoom::oauth::_save_tokens "$response"

  p6_return_void
}

######################################################################
#<
#
# Function: p6df::modules::zoom::oauth::_save_tokens(response)
#
#/ Synopsis
#/    Persist access_token, refresh_token, and expiry to disk.
#/
#  Args:
#	response - JSON response from token endpoint
#>
######################################################################
p6df::modules::zoom::oauth::_save_tokens() {
  local response="${1:?requires response}"

  local expires_at
  expires_at=$(( $(date +%s) + $(printf '%s' "$response" | jq -r '.expires_in // 3600') ))

  mkdir -p "$(dirname "$_P6DF_ZOOM_TOKEN_FILE")"
  printf '%s' "$response" | jq --argjson exp "$expires_at" '. + {expires_at: $exp}' \
    > "$_P6DF_ZOOM_TOKEN_FILE"
  chmod 600 "$_P6DF_ZOOM_TOKEN_FILE"

  p6_return_void
}

######################################################################
#<
#
# Function: p6df::modules::zoom::oauth::_refresh()
#
#/ Synopsis
#/    Use stored refresh_token to obtain a new access token and persist.
#/
#  Environment: ZOOM_CLIENT_ID ZOOM_CLIENT_SECRET
#>
######################################################################
p6df::modules::zoom::oauth::_refresh() {

  local refresh_token
  refresh_token=$(jq -r '.refresh_token' "$_P6DF_ZOOM_TOKEN_FILE")

  local response
  response=$(curl -s -X POST \
    "https://zoom.us/oauth/token?grant_type=refresh_token&refresh_token=${refresh_token}" \
    -u "${ZOOM_CLIENT_ID}:${ZOOM_CLIENT_SECRET}")

  p6df::modules::zoom::oauth::_save_tokens "$response"

  p6_return_void
}

######################################################################
#<
#
# Function: str str = p6df::modules::zoom::oauth::token()
#
#/ Synopsis
#/    Return a valid access token, refreshing if expired.
#/    Run p6df::modules::zoom::oauth::login first if no tokens exist.
#/
#  Environment: ZOOM_CLIENT_ID ZOOM_CLIENT_SECRET
#>
######################################################################
p6df::modules::zoom::oauth::token() {

  if [[ ! -f "$_P6DF_ZOOM_TOKEN_FILE" ]]; then
    p6_error "No Zoom tokens found. Run: p6df::modules::zoom::oauth::login"
    p6_return_str ""
  fi

  local expires_at now
  expires_at=$(jq -r '.expires_at // 0' "$_P6DF_ZOOM_TOKEN_FILE")
  now=$(date +%s)

  # Refresh 60s before expiry
  if (( now >= expires_at - 60 )); then
    p6df::modules::zoom::oauth::_refresh
  fi

  local token
  token=$(jq -r '.access_token' "$_P6DF_ZOOM_TOKEN_FILE")

  p6_return_str "${token}"
}

######################################################################
#<
#
# Function: p6df::modules::zoom::api::call(method, path, [data=])
#
#/ Synopsis
#/    Make an authenticated Zoom REST API v2 call
#/
#  Args:
#	method - HTTP method (GET POST PATCH PUT DELETE)
#	path   - API path e.g. /users/me/meetings
#	OPTIONAL data - JSON body []
#
#  Environment: ZOOM_CLIENT_ID ZOOM_CLIENT_SECRET
#>
######################################################################
p6df::modules::zoom::api::call() {
  local method="${1:?requires method}"
  local path="${2:?requires path}"
  local data="${3:-}"

  local token
  token=$(p6df::modules::zoom::oauth::token)

  if [[ -z "$token" ]]; then
    p6_return_void
  fi

  if [[ -n "$data" ]]; then
    curl -s -X "${method}" \
      "https://api.zoom.us/v2${path}" \
      -H "Authorization: Bearer ${token}" \
      -H "Content-Type: application/json" \
      -d "${data}"
  else
    curl -s -X "${method}" \
      "https://api.zoom.us/v2${path}" \
      -H "Authorization: Bearer ${token}" \
      -H "Content-Type: application/json"
  fi

  p6_return_void
}
