# shellcheck shell=bash

######################################################################
#<
#
# Function: str path = p6df::modules::zoom::oauth::token_file()
#
#  Returns:
#	str - path
#>
######################################################################
p6df::modules::zoom::oauth::token_file() {

  local path="${HOME}/.config/p6df/zoom_tokens.json"

  p6_return_str "$path"
}

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
  local state="${RANDOM}${RANDOM}"
  local auth_url="https://zoom.us/oauth/authorize?response_type=code&client_id=${ZOOM_CLIENT_ID}&redirect_uri=${redirect_uri}&state=${state}"

  p6_msg "Opening browser for Zoom OAuth..."
  if command -v open >/dev/null 2>&1; then
    open "$auth_url"
  else
    xdg-open "$auth_url"
  fi

  p6_msg "Waiting for redirect on ${redirect_uri} ..."
  local raw
  raw=$(echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<html><body>Auth complete. Return to terminal.</body></html>" \
    | nc -l 4000 2>/dev/null | head -1)

  local code returned_state
  code=$(printf '%s' "$raw" \
    | sed -n 's@GET /?code=\([^& ]*\).*@\1@p')
  returned_state=$(printf '%s' "$raw" \
    | sed -n 's@.*state=\([^& ]*\).*@\1@p')

  if [[ "$returned_state" != "$state" ]]; then
    p6_error "OAuth state mismatch"
    p6_return_void
  fi

  if [[ -z "$code" ]]; then
    p6_error "Failed to capture OAuth code"
    p6_return_void
  fi

  p6df::modules::zoom::oauth::exchange_code "$code" "$redirect_uri"

  p6_return_void
}

######################################################################
#<
#
# Function: p6df::modules::zoom::oauth::exchange_code(code, redirect_uri)
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
p6df::modules::zoom::oauth::exchange_code() {
  local code="${1:?requires code}"
  local redirect_uri="${2:?requires redirect_uri}"

  local response
  response=$(curl -s -X POST \
    "https://zoom.us/oauth/token?grant_type=authorization_code&code=${code}&redirect_uri=${redirect_uri}" \
    -u "${ZOOM_CLIENT_ID}:${ZOOM_CLIENT_SECRET}")

  p6df::modules::zoom::oauth::save_tokens "$response"

  p6_return_void
}

######################################################################
#<
#
# Function: p6df::modules::zoom::oauth::save_tokens(response)
#
#/ Synopsis
#/    Persist access_token, refresh_token, and expiry to disk.
#/
#  Args:
#	response - JSON response from token endpoint
#>
######################################################################
p6df::modules::zoom::oauth::save_tokens() {
  local response="${1:?requires response}"

  local token_file
  token_file=$(p6df::modules::zoom::oauth::token_file)

  if ! printf '%s' "$response" | jq -e '.access_token? // empty' >/dev/null; then
    p6_error "Zoom token response missing access_token"
    p6_return_void
  fi

  local expires_at
  expires_at=$(( $(date +%s) + $(printf '%s' "$response" | jq -r '.expires_in // 3600') ))

  mkdir -p "$(dirname "$token_file")"
  printf '%s' "$response" | jq --argjson exp "$expires_at" '. + {expires_at: $exp}' \
    > "$token_file"
  chmod 600 "$token_file"

  p6_return_void
}

######################################################################
#<
#
# Function: p6df::modules::zoom::oauth::refresh()
#
#/ Synopsis
#/    Use stored refresh_token to obtain a new access token and persist.
#/
#  Environment: ZOOM_CLIENT_ID ZOOM_CLIENT_SECRET
#>
######################################################################
p6df::modules::zoom::oauth::refresh() {

  local token_file
  token_file=$(p6df::modules::zoom::oauth::token_file)

  local refresh_token
  refresh_token=$(jq -r '.refresh_token' "$token_file")

  local response
  response=$(curl -s -X POST \
    "https://zoom.us/oauth/token?grant_type=refresh_token&refresh_token=${refresh_token}" \
    -u "${ZOOM_CLIENT_ID}:${ZOOM_CLIENT_SECRET}")

  p6df::modules::zoom::oauth::save_tokens "$response"

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

  local token_file
  token_file=$(p6df::modules::zoom::oauth::token_file)

  if [[ ! -f "$token_file" ]]; then
    p6_error "No Zoom tokens found. Run: p6df::modules::zoom::oauth::login"
    p6_return_str ""
  fi

  local expires_at now
  expires_at=$(jq -r '.expires_at // 0' "$token_file")
  now=$(date +%s)

  # Refresh 60s before expiry
  if (( now >= expires_at - 60 )); then
    p6df::modules::zoom::oauth::refresh
    expires_at=$(jq -r '.expires_at // 0' "$token_file")
    if (( now >= expires_at )); then
      p6_error "Zoom token refresh failed; rerun login"
      p6_return_str ""
    fi
  fi

  local token
  token=$(jq -r '.access_token' "$token_file")

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
