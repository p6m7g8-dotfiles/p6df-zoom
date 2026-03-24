# shellcheck shell=bash

######################################################################
#<
#
# Function: str path = p6df::modules::zoom::oauth::token::file()
#
#  Returns:
#	str - path
#>
######################################################################
p6df::modules::zoom::oauth::token::file() {

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
  p6df::modules::darwin::url::open "$auth_url"

  p6_msg "Waiting for redirect on ${redirect_uri} ..."
  local raw
  raw=$(echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<html><body>Auth complete. Return to terminal.</body></html>" \
    | nc -l 4000 2>/dev/null | head -1)

  local code returned_state
  code=$(printf '%s' "$raw" \
    | p6_filter_extract_query_param "code")
  returned_state=$(printf '%s' "$raw" \
    | p6_filter_extract_query_param "state")

  if [[ "$returned_state" != "$state" ]]; then
    p6_error "OAuth state mismatch"
  elif [[ -z "$code" ]]; then
    p6_error "Failed to capture OAuth code"
  else
    p6df::modules::zoom::oauth::code::exchange "$code" "$redirect_uri"
  fi

  p6_return_void
}

######################################################################
#<
#
# Function: p6df::modules::zoom::oauth::code::exchange(code, redirect_uri)
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
p6df::modules::zoom::oauth::code::exchange() {
  local code="$1"         # authorization code from redirect
  local redirect_uri="$2" # must match app configuration

  local url="https://zoom.us/oauth/token?grant_type=authorization_code&code=${code}&redirect_uri=${redirect_uri}"
  local creds="${ZOOM_CLIENT_ID}:${ZOOM_CLIENT_SECRET}"

  local response
  response=$(p6_network_http_post_basic_auth "$url" "$creds")

  p6df::modules::zoom::oauth::tokens::save "$response"

  p6_return_void
}

######################################################################
#<
#
# Function: p6df::modules::zoom::oauth::tokens::save(response)
#
#/ Synopsis
#/    Persist access_token, refresh_token, and expiry to disk.
#/
#  Args:
#	response - JSON response from token endpoint
#>
######################################################################
p6df::modules::zoom::oauth::tokens::save() {
  local response="$1" # JSON response from token endpoint

  local token_file
  token_file=$(p6df::modules::zoom::oauth::token::file)

  if ! p6_echo "$response" | p6_json_eval -e '.access_token? // empty' >/dev/null; then
    p6_error "Zoom token response missing access_token"
  else
    local expires_at
    expires_at=$(( EPOCHSECONDS + $(p6_echo "$response" | p6_json_eval -r '.expires_in // 3600') ))

    mkdir -p "$(dirname "$token_file")"
    p6_echo "$response" | p6_json_eval --argjson exp "$expires_at" '. + {expires_at: $exp}' \
      > "$token_file"
    p6_file_chmod "600" "$token_file"
  fi

  p6_return_void
}

######################################################################
#<
#
# Function: p6df::modules::zoom::oauth::token::refresh()
#
#/ Synopsis
#/    Use stored refresh_token to obtain a new access token and persist.
#/
#  Environment: ZOOM_CLIENT_ID ZOOM_CLIENT_SECRET
#>
######################################################################
p6df::modules::zoom::oauth::token::refresh() {

  local token_file
  token_file=$(p6df::modules::zoom::oauth::token::file)

  local refresh_token
  refresh_token=$(p6_json_from_file "$token_file" | p6_json_eval -r '.refresh_token')

  local url="https://zoom.us/oauth/token?grant_type=refresh_token&refresh_token=${refresh_token}"
  local creds="${ZOOM_CLIENT_ID}:${ZOOM_CLIENT_SECRET}"

  local response
  response=$(p6_network_http_post_basic_auth "$url" "$creds")

  p6df::modules::zoom::oauth::tokens::save "$response"

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
  token_file=$(p6df::modules::zoom::oauth::token::file)

  local token=""

  if [[ ! -f "$token_file" ]]; then
    p6_error "No Zoom tokens found. Run: p6df::modules::zoom::oauth::login"
  else
    local expires_at now
    expires_at=$(p6_json_from_file "$token_file" | p6_json_eval -r '.expires_at // 0')
    now=$EPOCHSECONDS

    if (( now >= expires_at - 60 )); then
      p6df::modules::zoom::oauth::token::refresh
      expires_at=$(p6_json_from_file "$token_file" | p6_json_eval -r '.expires_at // 0')
    fi

    if (( now < expires_at )); then
      token=$(p6_json_from_file "$token_file" | p6_json_eval -r '.access_token')
    else
      p6_error "Zoom token refresh failed; rerun login"
    fi
  fi

  p6_return_str "$token"
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
  local method="$1" # HTTP method (GET POST PATCH PUT DELETE)
  local path="$2"   # API path e.g. /users/me/meetings
  local data="${3:-}"

  local token
  token=$(p6df::modules::zoom::oauth::token)

  local url="https://api.zoom.us/v2${path}"
  local bearer="Authorization: Bearer ${token}"
  local ctype="Content-Type: application/json"

  p6_network_http_call "${method}" "$url" "$data" -H "$bearer" -H "$ctype"

  p6_return_void
}
