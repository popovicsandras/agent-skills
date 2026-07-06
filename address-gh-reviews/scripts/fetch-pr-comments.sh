#!/bin/bash

# Fetch and process PR comments with reactions
# Usage: ./fetch-pr-comments.sh <pr_number> [owner] [repo]
#
# Environment variables:
#   GITHUB_PERSONAL_ACCESS_TOKEN - Required for GitHub API authentication

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEFAULT_OWNER="HylandSoftware"
DEFAULT_REPO="satori"

# Parse arguments
PR_NUMBER="$1"
OWNER="${2:-$DEFAULT_OWNER}"
REPO="${3:-$DEFAULT_REPO}"

# Validate inputs
if [ -z "$PR_NUMBER" ]; then
  echo -e "${RED}Error: PR number is required${NC}"
  echo "Usage: $0 <pr_number> [owner] [repo]"
  echo "Example: $0 1086"
  echo "Example: $0 1086 HylandSoftware satori"
  exit 1
fi

# Get script directory and workspace root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/verify-token.sh" "$OWNER" "$REPO" "$PR_NUMBER"
echo ""
# Scripts are now in .agents/skills/address-github-reviews/scripts/
# Need to go up 4 levels to reach workspace root
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

# Create output directory
OUTPUT_DIR="$WORKSPACE_ROOT/.tmp/ai/pr-comments"
mkdir -p "$OUTPUT_DIR"

RAW_OUTPUT_FILE="$OUTPUT_DIR/${PR_NUMBER}-raw.json"
PROCESSED_OUTPUT_FILE="$OUTPUT_DIR/${PR_NUMBER}-processed.json"
FORMATTED_OUTPUT_FILE="$OUTPUT_DIR/${PR_NUMBER}.txt"

echo -e "${BLUE}Fetching PR comments from GitHub...${NC}"
echo "Owner: $OWNER"
echo "Repo: $REPO"
echo "PR: #$PR_NUMBER"
echo ""

# Fetch comments from GitHub API
HTTP_STATUS=$(curl -s -w "%{http_code}" -o "$RAW_OUTPUT_FILE" \
  -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER/comments")

# Check HTTP status
if [ "$HTTP_STATUS" -ne 200 ]; then
  echo -e "${RED}Error: GitHub API returned status $HTTP_STATUS${NC}"
  echo "Response:"
  cat "$RAW_OUTPUT_FILE"
  rm -f "$RAW_OUTPUT_FILE"
  exit 1
fi

echo -e "${GREEN}✓ Raw comments saved to: $RAW_OUTPUT_FILE${NC}"
echo ""

# Process comments using TypeScript
echo -e "${BLUE}Processing comments (filtering by 👍 reactions and fetching threads)...${NC}"

# Run TypeScript processor
cd "$SCRIPT_DIR"
npx tsx process-comments.ts "$RAW_OUTPUT_FILE" "$PROCESSED_OUTPUT_FILE" "$FORMATTED_OUTPUT_FILE"

if [ $? -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ Processed comments saved to: $PROCESSED_OUTPUT_FILE${NC}"
  echo -e "${GREEN}✓ Formatted output saved to: $FORMATTED_OUTPUT_FILE${NC}"
else
  echo -e "${RED}Error: Failed to process comments${NC}"
  exit 1
fi

