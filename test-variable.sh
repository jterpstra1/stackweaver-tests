#!/bin/bash

# Function to set test variable in StackWeaver workspace for integration testing
# Usage: test_variable <workspace-id> [value] [org-name]
# Example: test_variable abc123 "test-value-123" my-org
#
# Can be used in two ways:
# 1. As a function (source the file): source test-variable.sh && test_variable <workspace-id> [value]
# 2. As a script: ./test-variable.sh <workspace-id> [value]

# case: test_variable: 00325700-37e6-4751-af30-a093ce67c548 test_var "test-value-123"

test_variable() {
    # Colors for output
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local NC='\033[0m' # No Color

    # Check if required environment variables are set
    if [ -z "$TFE_TOKEN" ]; then
        echo -e "${RED}Error: TFE_TOKEN environment variable is not set${NC}"
        echo "Please set it with: export TFE_TOKEN='your-token'"
        return 1
    fi

    local STACKWEAVER_HOST="${STACKWEAVER_HOST:-localhost:8080}"
    if [ "$STACKWEAVER_HOST" = "localhost:8080" ] && [ -z "$STACKWEAVER_HOST_SET" ]; then
        echo -e "${YELLOW}STACKWEAVER_HOST not set, defaulting to localhost:8080${NC}"
    fi

    # Check arguments
    if [ $# -lt 1 ]; then
        echo -e "${RED}Usage: test_variable <workspace-id> [value] [org-name]${NC}"
        echo "Example: test_variable abc123 \"test-value-123\" my-org"
        echo ""
        echo "Environment variables:"
        echo "  TFE_TOKEN - Required: Your TFE token"
        echo "  STACKWEAVER_HOST - Optional: Defaults to localhost:8080"
        echo "  ORG_NAME - Optional: Will be fetched from workspace if not set"
        return 1
    fi

    local WORKSPACE_ID="$1"
    local TEST_VALUE="${2:-test-value-$(date +%s)}"  # Default to timestamped value if not provided
    local ORG_NAME="${ORG_NAME:-}"

    # Get organization name - either from env var or from workspace API
    if [ -z "$ORG_NAME" ]; then
        echo -e "${YELLOW}ORG_NAME not set. Attempting to fetch from workspace...${NC}"
        # Try to get org name from workspace
        local WORKSPACE_INFO=$(curl -s -H "Authorization: Bearer $TFE_TOKEN" \
            "http://${STACKWEAVER_HOST}/api/v2/workspaces/${WORKSPACE_ID}")
        
        # Try to extract org name from JSON response (using grep/sed as fallback)
        ORG_NAME=$(echo "$WORKSPACE_INFO" | grep -o '"organization"[^}]*"name":"[^"]*"' | grep -o '"name":"[^"]*"' | cut -d'"' -f4 || echo "")
        
        if [ -z "$ORG_NAME" ]; then
            echo -e "${RED}Error: Could not determine organization name.${NC}"
            echo "Please set it: export ORG_NAME='your-org'"
            echo "Or provide it as third argument: test_variable <workspace-id> [value] [org-name]"
            return 1
        fi
        echo -e "${GREEN}Found organization: ${ORG_NAME}${NC}"
    fi

    # Allow org name as third argument (overrides env var)
    if [ -n "$3" ]; then
        ORG_NAME="$3"
    fi

     local API_URL="http://${STACKWEAVER_HOST}/api/v2/workspaces/${WORKSPACE_ID}/variables"

    echo -e "${YELLOW}Setting test variable in workspace ${WORKSPACE_ID}...${NC}"
    echo "Variable: test_var"
    echo "Value: ${TEST_VALUE}"

    # Create variable - API expects simple JSON format, not JSON:API
    local RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Authorization: Bearer $TFE_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"key\": \"test_var\",
            \"value\": \"${TEST_VALUE}\",
            \"encrypted\": false,
            \"sensitive\": false
        }" \
        "$API_URL")

    local HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    local BODY=$(echo "$RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" -eq 201 ] || [ "$HTTP_CODE" -eq 200 ]; then
        echo -e "${GREEN}✓ Variable set successfully!${NC}"
        echo "You can now trigger a plan/apply run to verify the variable is passed to Terraform."
        echo "Check the output 'test_var_output' in the run results."
        return 0
    else
        echo -e "${RED}✗ Failed to set variable${NC}"
        echo "HTTP Code: $HTTP_CODE"
        echo "Response: $BODY"
        
        # Check if variable already exists
        if echo "$BODY" | grep -q "already exists\|duplicate"; then
            echo -e "${YELLOW}Variable already exists. Attempting to update...${NC}"
            
            # Get existing variable ID - find the variable with key "test_var"
            local VARS_LIST=$(curl -s -H "Authorization: Bearer $TFE_TOKEN" "$API_URL")
            # Extract ID for variable with key "test_var"
            # API returns: {"data": [{"id": "uuid", "key": "test_var", ...}, ...]}
            # Find the object containing "test_var" and extract its "id"
            local VAR_ID=$(echo "$VARS_LIST" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for var in data.get('data', []):
        if var.get('key') == 'test_var':
            print(var.get('id', ''))
            break
except:
    pass
" 2>/dev/null)
            
            # Fallback if python not available - use grep/sed
            if [ -z "$VAR_ID" ]; then
                # Find the JSON object containing "test_var" and extract its id
                VAR_ID=$(echo "$VARS_LIST" | grep -o '{[^}]*"key"[^}]*"test_var"[^}]*}' | grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4)
            fi
            
            if [ -n "$VAR_ID" ]; then
                local UPDATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH \
                    -H "Authorization: Bearer $TFE_TOKEN" \
                    -H "Content-Type: application/json" \
                    -d "{
                        \"value\": \"${TEST_VALUE}\"
                    }" \
                    "${API_URL}/${VAR_ID}")
                
                local UPDATE_HTTP_CODE=$(echo "$UPDATE_RESPONSE" | tail -n1)
                if [ "$UPDATE_HTTP_CODE" -eq 200 ]; then
                    echo -e "${GREEN}✓ Variable updated successfully!${NC}"
                    return 0
                else
                    echo -e "${RED}✗ Failed to update variable${NC}"
                    echo "$UPDATE_RESPONSE"
                    return 1
                fi
            fi
        fi
        
        return 1
    fi
}

# If script is executed directly (not sourced), call the function
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    set -e
    test_variable "$@"
fi

