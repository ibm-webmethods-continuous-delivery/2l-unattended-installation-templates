#!/bin/sh

# Install required packages for JSON validation
apk add --no-cache jq

echo "=== Testing generateInventoryFileFromProductsList function ==="
echo "Testing POSIX shell function for inventory generation"

# Source framework functions for logging
. /mnt/WMUI/01.scripts/commonFunctions.sh
. /mnt/WMUI/01.scripts/installation/setupFunctions.sh

logI "Starting inventory generation tests"

errNo=0

# Test 1: New format (ProductsLatestList.txt style)
logI "Test 1: Testing products list format"
if generateInventoryFileFromProductsList \
    /mnt/test/test-products.txt \
    /tmp/output-new.json \
    "11.1.0" "LNXAMD64" "1101" "11.0.0.0000-0117" '"UNX-ANY","LNX-ANY"'; then
    logI "✓ Format processing completed"
    
    # Validate JSON syntax
    if jq empty /tmp/output-new.json 2>/dev/null; then
        logI "✓ Generated JSON is valid"
        
        # Check if products were extracted correctly
        productCount=$(jq '.installedProducts | length' /tmp/output-new.json)
        if [ "${productCount}" = "5" ]; then
            logI "✓ Correct number of products extracted: ${productCount}"
        else
            logE "✗ Expected 5 products, got ${productCount}"
            errNo=$((errNo+1))
        fi
        
        # Check specific product
        yaiVersion=$(jq -r '.installedProducts[] | select(.productId=="YAI") | .version' /tmp/output-new.json)
        if [ "${yaiVersion}" = "11.1.0" ]; then
            logI "✓ YAI version correctly extracted: ${yaiVersion}"
        else
            logE "✗ Expected YAI version 11.1.0, got ${yaiVersion}"
            errNo=$((errNo+1))
        fi
    else
        logE "✗ Generated JSON is invalid"

        ls -lrt /tmp
        errNo=$((errNo+1))
    fi
else
    logE "✗ Format processing failed"
    errNo=$((errNo+1))
fi

# Test 2: Error handling - non-existent file
logI "Test 2: Testing error handling"
if generateInventoryFileFromProductsList \
    /mnt/test/nonexistent.txt \
    /tmp/output-error_2.json 2>/dev/null; then
    logE "✗ Should have failed with non-existent file"
    errNo=$((errNo+1))
else
    logI "✓ Correctly handled non-existent input file"
fi

# Test 3: Compare JSON structure with expected format
logI "Test 3: Validating JSON structure"
if [ -f /tmp/output-new.json ]; then
    # Check required fields exist
    if jq -e '.installedFixes' /tmp/output-new.json >/dev/null && \
       jq -e '.installedSupportPatches' /tmp/output-new.json >/dev/null && \
       jq -e '.envVariables' /tmp/output-new.json >/dev/null && \
       jq -e '.installedProducts' /tmp/output-new.json >/dev/null; then
        logI "✓ All required JSON fields present"
    else
        logE "✗ Missing required JSON fields"
        errNo=$((errNo+1))
    fi
    
    # Check environment variables
    platform=$(jq -r '.envVariables.platform' /tmp/output-new.json)
    if [ "${platform}" = "LNXAMD64" ]; then
        logI "✓ Platform correctly set: ${platform}"
    else
        logE "✗ Expected platform LNXAMD64, got ${platform}"
        errNo=$((errNo+1))
    fi
fi

# Display generated files for manual inspection
logI "Generated test files:"
ls -la /tmp/*.json 2>/dev/null || logW "No JSON files generated"

# Show sample output
if [ -f /tmp/output-new.json ]; then
    logI "Sample output (first few lines):"
    head -10 /tmp/output-new.json
fi

logI "Test completed with exit code: ${errNo}"

if [ ${errNo} -ne 0 ]; then
    logE "TEST FAILED!"
else
    logI "SUCCESS - All tests passed!"
fi

exit ${errNo}