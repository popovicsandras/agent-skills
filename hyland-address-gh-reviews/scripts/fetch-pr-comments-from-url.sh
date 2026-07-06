#!/bin/bash

# Convenience wrapper for fetch-pr-comments.sh that accepts a full PR URL
# Usage: ./fetch-pr-comments-from-url.sh <pr_url>
#
# Example: ./fetch-pr-comments-from-url.sh https://github.com/HylandSoftware/satori/pull/1086

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PR_URL="$1"

if [ -z "$PR_URL" ]; then
  echo -e "${RED}Error: PR URL is required${NC}"
  echo "Usage: $0 <pr_url>"
  echo "Example: $0 https://github.com/HylandSoftware/satori/pull/1086"
  exit 1
fi

# Extract owner, repo, and PR number from URL
# Supports formats:
# - https://github.com/owner/repo/pull/123
# - https://github.com/owner/repo/pulls/123
# - github.com/owner/repo/pull/123

if [[ $PR_URL =~ github\.com/([^/]+)/([^/]+)/pulls?/([0-9]+) ]]; then
  OWNER="${BASH_REMATCH[1]}"
  REPO="${BASH_REMATCH[2]}"
  PR_NUMBER="${BASH_REMATCH[3]}"
else
  echo -e "${RED}Error: Invalid GitHub PR URL format${NC}"
  echo "Expected format: https://github.com/owner/repo/pull/number"
  echo "Got: $PR_URL"
  exit 1
fi

echo -e "${BLUE}Extracted from URL:${NC}"
echo "  Owner: $OWNER"
echo "  Repo: $REPO"
echo "  PR Number: $PR_NUMBER"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call the main script
"$SCRIPT_DIR/fetch-pr-comments.sh" "$PR_NUMBER" "$OWNER" "$REPO"

