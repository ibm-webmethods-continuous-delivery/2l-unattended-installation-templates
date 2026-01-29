#!/bin/sh

# Install required packages for JSON validation
apk add --no-cache jq curl

# Source Posix Utilities
# shellcheck source=../../../../../../2l-posix-shell-utils/code/1.init.sh
. "${PU_HOME}/code/1.init.sh"
# shellcheck source=../../../../../../2l-posix-shell-utils/code/3.ingester.sh
. "${PU_HOME}/code/3.ingester.sh"

# shellcheck source=../../../../../01.scripts/wmui-functions.sh
. "${WMUI_HOME}/01.scripts/wmui-functions.sh"

pu_log_i "=== Testing wmui_generate_inventory_from_products_list function ==="

errNo=0

# Test 1: New format (ProductsLatestList.txt style)
pu_log_i "Test 1: Testing products list format"
if wmui_generate_inventory_from_products_list \
    /mnt/test/test-products.txt \
    /tmp/output-new.json \
    "11.1.0" "LNXAMD64" "11.0.0.0000-0117" '"UNX-ANY","LNX-ANY"'; then
    pu_log_i "✓ Format processing completed"

    # Validate JSON syntax
    if jq empty /tmp/output-new.json 2>/dev/null; then
        pu_log_i "✓ Generated JSON is valid"

        # Check if products were extracted correctly
        productCount=$(jq '.installedProducts | length' /tmp/output-new.json)
        if [ "${productCount}" = "5" ]; then
            pu_log_i "✓ Correct number of products extracted: ${productCount}"
        else
            pu_log_e "✗ Expected 5 products, got ${productCount}"
            errNo=$((errNo+1))
        fi

        # Check specific product
        yaiVersion=$(jq -r '.installedProducts[] | select(.productId=="YAI") | .version' /tmp/output-new.json)
        if [ "${yaiVersion}" = "11.1.0" ]; then
            pu_log_i "✓ YAI version correctly extracted: ${yaiVersion}"
        else
            pu_log_e "✗ Expected YAI version 11.1.0, got ${yaiVersion}"
            errNo=$((errNo+1))
        fi
    else
        pu_log_e "✗ Generated JSON is invalid"
        ls -lrt /tmp
        errNo=$((errNo+1))
    fi
else
    pu_log_e "✗ Format processing failed"
    errNo=$((errNo+1))
fi

# Test 2: Error handling - non-existent file
pu_log_i "Test 2: Testing error handling"
if wmui_generate_inventory_from_products_list \
    /mnt/test/nonexistent.txt \
    /tmp/output-error_2.json 2>/dev/null; then
    pu_log_e "✗ Should have failed with non-existent file"
    errNo=$((errNo+1))
else
    pu_log_i "✓ Correctly handled non-existent input file"
fi

# Test 3: Compare JSON structure with expected format
pu_log_i "Test 3: Validating JSON structure"
if [ -f /tmp/output-new.json ]; then
    # Check required fields exist
    if jq -e '.installedFixes' /tmp/output-new.json >/dev/null && \
       jq -e '.installedSupportPatches' /tmp/output-new.json >/dev/null && \
       jq -e '.envVariables' /tmp/output-new.json >/dev/null && \
       jq -e '.installedProducts' /tmp/output-new.json >/dev/null; then
        pu_log_i "✓ All required JSON fields present"
    else
        pu_log_e "✗ Missing required JSON fields"
        errNo=$((errNo+1))
    fi

    # Check environment variables
    platform=$(jq -r '.envVariables.platform' /tmp/output-new.json)
    if [ "${platform}" = "LNXAMD64" ]; then
        pu_log_i "✓ Platform correctly set: ${platform}"
    else
        pu_log_e "✗ Expected platform LNXAMD64, got ${platform}"
        errNo=$((errNo+1))
    fi
fi

# Display generated files for manual inspection
pu_log_i "Generated test files:"
ls -la /tmp/*.json 2>/dev/null || pu_log_w "No JSON files generated"

# Show sample output
if [ -f /tmp/output-new.json ]; then
    pu_log_i "Sample output (first few lines):"
    head -10 /tmp/output-new.json
fi

pu_log_i "Returning exit code $errNo"

if [ $errNo -ne 0 ]; then
  pu_log_e "TEST FAILED!"
else
  pu_log_i "SUCCESS"
fi

exit $errNo

# Made with Bob
