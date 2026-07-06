#!/bin/bash

# Verify GITHUB_PERSONAL_ACCESS_TOKEN is set and can access the GitHub API.
# Usage: ./verify-token.sh [owner] [repo] [pr_number]
#
# When owner/repo/pr_number are provided, performs a scoped test against the
# same pull request comments endpoint used by fetch-pr-comments.sh.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

OWNER="$1"
REPO="$2"
PR_NUMBER="$3"

TOKEN_DOC_URL="https://github.com/settings/personal-access-tokens"

print_token_setup() {
  echo ""
  echo "Create a fine-grained token: $TOKEN_DOC_URL"
  echo ""
  echo "Requirements:"
  echo "  - Repository access: include the target repository"
  echo "  - Permissions → Pull requests: Read-only"
  echo "  - Permissions → Metadata: Read-only (included automatically)"
  echo ""
  echo "Organization repositories may also require SSO authorization:"
  echo "  $TOKEN_DOC_URL → Configure SSO → Authorize"
}

print_scope_help() {
  echo ""
  echo "The token is valid but lacks access to fetch pull request review comments."
  echo ""
  echo "Grant these permissions for the target repository:"
  echo "  - Pull requests: Read-only"
  echo "  - Metadata: Read-only"
  echo "  Update at: $TOKEN_DOC_URL"
  echo ""
  echo "If the repository belongs to an organization, authorize SSO for the token."
}

if [ -z "$GITHUB_PERSONAL_ACCESS_TOKEN" ]; then
  echo -e "${RED}Error: GITHUB_PERSONAL_ACCESS_TOKEN environment variable is not set.${NC}"
  print_token_setup
  exit 1
fi

TMP_DIR="${TMPDIR:-/tmp}"
USER_RESPONSE_FILE="$TMP_DIR/gh-verify-user-$$.json"
USER_HEADERS_FILE="$TMP_DIR/gh-verify-user-headers-$$.txt"

cleanup() {
  rm -f "$USER_RESPONSE_FILE" "$USER_HEADERS_FILE" \
    "$REPO_RESPONSE_FILE" "$PR_RESPONSE_FILE" 2>/dev/null || true
}
trap cleanup EXIT

echo -e "${BLUE}Verifying GitHub token...${NC}"

USER_HTTP_STATUS=$(curl -sS -D "$USER_HEADERS_FILE" -o "$USER_RESPONSE_FILE" -w "%{http_code}" \
  -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/user")

if [ "$USER_HTTP_STATUS" -eq 401 ]; then
  echo -e "${RED}Error: GitHub token is invalid or expired (HTTP 401).${NC}"
  echo "Create a new token and update GITHUB_PERSONAL_ACCESS_TOKEN."
  print_token_setup
  exit 1
fi

if [ "$USER_HTTP_STATUS" -ne 200 ]; then
  echo -e "${RED}Error: GitHub API returned unexpected status $USER_HTTP_STATUS when validating the token.${NC}"
  if [ -s "$USER_RESPONSE_FILE" ]; then
    echo "Response:"
    cat "$USER_RESPONSE_FILE"
  fi
  exit 1
fi

LOGIN=$(grep -o '"login"[[:space:]]*:[[:space:]]*"[^"]*"' "$USER_RESPONSE_FILE" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
if [ -n "$LOGIN" ]; then
  echo -e "${GREEN}✓ Token is valid for GitHub user: $LOGIN${NC}"
else
  echo -e "${GREEN}✓ Token is valid${NC}"
fi

OAUTH_SCOPES=$(grep -i '^x-oauth-scopes:' "$USER_HEADERS_FILE" | cut -d: -f2- | sed 's/^ *//')
if [ -n "$OAUTH_SCOPES" ] && [ "$OAUTH_SCOPES" != " " ]; then
  echo -e "${BLUE}  Classic token scopes: $OAUTH_SCOPES${NC}"
fi

if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
  echo -e "${YELLOW}Note: Skipping repository scope test (no owner/repo provided).${NC}"
  exit 0
fi

REPO_RESPONSE_FILE="$TMP_DIR/gh-verify-repo-$$.json"
REPO_HTTP_STATUS=$(curl -sS -o "$REPO_RESPONSE_FILE" -w "%{http_code}" \
  -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$OWNER/$REPO")

if [ "$REPO_HTTP_STATUS" -eq 404 ]; then
  echo -e "${RED}Error: Cannot access repository $OWNER/$REPO (HTTP 404).${NC}"
  echo "The repository may not exist, or your token may not have access to it."
  print_scope_help
  exit 1
fi

if [ "$REPO_HTTP_STATUS" -eq 403 ]; then
  echo -e "${RED}Error: Access denied to repository $OWNER/$REPO (HTTP 403).${NC}"
  print_scope_help
  exit 1
fi

if [ "$REPO_HTTP_STATUS" -ne 200 ]; then
  echo -e "${RED}Error: GitHub API returned status $REPO_HTTP_STATUS for repository $OWNER/$REPO.${NC}"
  if [ -s "$REPO_RESPONSE_FILE" ]; then
    cat "$REPO_RESPONSE_FILE"
  fi
  exit 1
fi

echo -e "${GREEN}✓ Repository access confirmed: $OWNER/$REPO${NC}"

if [ -z "$PR_NUMBER" ]; then
  exit 0
fi

PR_RESPONSE_FILE="$TMP_DIR/gh-verify-pr-$$.json"
PR_HTTP_STATUS=$(curl -sS -o "$PR_RESPONSE_FILE" -w "%{http_code}" \
  -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER/comments?per_page=1")

if [ "$PR_HTTP_STATUS" -eq 404 ]; then
  echo -e "${RED}Error: Cannot access PR #$PR_NUMBER in $OWNER/$REPO (HTTP 404).${NC}"
  echo "The pull request may not exist, or your token may lack pull request read access."
  print_scope_help
  exit 1
fi

if [ "$PR_HTTP_STATUS" -eq 403 ]; then
  echo -e "${RED}Error: Insufficient permissions to read pull request comments (HTTP 403).${NC}"
  print_scope_help
  exit 1
fi

if [ "$PR_HTTP_STATUS" -ne 200 ]; then
  echo -e "${RED}Error: GitHub API returned status $PR_HTTP_STATUS for PR comments.${NC}"
  if [ -s "$PR_RESPONSE_FILE" ]; then
    cat "$PR_RESPONSE_FILE"
  fi
  exit 1
fi

echo -e "${GREEN}✓ Pull request comment access confirmed for PR #$PR_NUMBER${NC}"
