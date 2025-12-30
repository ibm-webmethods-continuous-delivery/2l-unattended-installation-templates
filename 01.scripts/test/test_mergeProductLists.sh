#!/bin/sh
#
# Copyright IBM Corp. 2025 - 2025
# SPDX-License-Identifier: Apache-2.0
#
# Unit tests for mergeProductLists function from setupFunctions.sh

# shellcheck disable=SC3043

# Setup test environment
oneTimeSetUp() {
  # Set up WMUI_HOME if not already set
  if [ -z "${WMUI_HOME}" ]; then
    # Assume we're in 01.scripts/test, so WMUI_HOME is two levels up
    WMUI_HOME="$(cd "$(dirname "$0")/../.." && pwd)"
    export WMUI_HOME
  fi

  # Set up WMUI_CACHE_HOME (same as WMUI_HOME for tests)
  export WMUI_CACHE_HOME="${WMUI_HOME}"

  # Create test directory
  TEST_DIR="${WMUI_TEST_DIR:-/tmp/WMUI_TESTS}/mergeProductLists_$$"
  mkdir -p "${TEST_DIR}"
  export TEST_DIR

  # Source the required functions
  if [ ! -f "${WMUI_HOME}/01.scripts/commonFunctions.sh" ]; then
    echo "ERROR: commonFunctions.sh not found at ${WMUI_HOME}/01.scripts/commonFunctions.sh"
    exit 1
  fi
  # shellcheck source=SCRIPTDIR/../commonFunctions.sh
  . "${WMUI_HOME}/01.scripts/commonFunctions.sh"

  if [ ! -f "${WMUI_HOME}/01.scripts/installation/setupFunctions.sh" ]; then
    echo "ERROR: setupFunctions.sh not found at ${WMUI_HOME}/01.scripts/installation/setupFunctions.sh"
    exit 1
  fi
  # shellcheck source=SCRIPTDIR/../installation/setupFunctions.sh
  . "${WMUI_HOME}/01.scripts/installation/setupFunctions.sh"

  # Create mock template structure for testing
  MOCK_TEMPLATES_DIR="${TEST_DIR}/02.templates/01.setup"
  mkdir -p "${MOCK_TEMPLATES_DIR}"

  # Create test template 1: Template1/v1/config1
  mkdir -p "${MOCK_TEMPLATES_DIR}/Template1/v1/config1"
  cat > "${MOCK_TEMPLATES_DIR}/Template1/v1/config1/ProductsLatestList.txt" <<'EOF'
e2ei/11/DCC_11.1.0.0.LATEST/CDC/DatabaseComponentConfiguratorCore
e2ei/11/IS_11.1.0.0.LATEST/integrationServer/PIECore
e2ei/11/TPL_11.1.0.0.LATEST/License/license
e2ei/11/TPS_11.1.0.0.LATEST/SCG/tppCommons
EOF

  # Create test template 2: Template2/v1/config1
  mkdir -p "${MOCK_TEMPLATES_DIR}/Template2/v1/config1"
  cat > "${MOCK_TEMPLATES_DIR}/Template2/v1/config1/ProductsLatestList.txt" <<'EOF'
e2ei/11/IS_11.1.0.0.LATEST/integrationServer/PIECore
e2ei/11/MWS_11.1.0.0.LATEST/MWS/MWSCommonDirectoryService
e2ei/11/TPL_11.1.0.0.LATEST/License/license
e2ei/11/YAI_11.1.0.0.LATEST/YAI/YAI
EOF

  # Create test template 3: Template3/v1/config1 (for single template test)
  mkdir -p "${MOCK_TEMPLATES_DIR}/Template3/v1/config1"
  cat > "${MOCK_TEMPLATES_DIR}/Template3/v1/config1/ProductsLatestList.txt" <<'EOF'
e2ei/11/SJP_17.0.12.0.LATEST/Infrastructure/sjp
e2ei/11/TES_4.4.1.0.LATEST/TES/TESCommon
EOF

  # Override WMUI_CACHE_HOME to point to our test directory
  export WMUI_CACHE_HOME="${TEST_DIR}"
}

# Cleanup after all tests
oneTimeTearDown() {
  if [ -d "${TEST_DIR}" ]; then
    # rm -rf "${TEST_DIR}"
    echo "Would rm ${TEST_DIR}"
  fi
}

# Setup before each test
setUp() {
  # Create a unique output directory for each test
  TEST_OUTPUT_DIR="${TEST_DIR}/output_$$_${RANDOM}"
  mkdir -p "${TEST_OUTPUT_DIR}"
}

# Cleanup after each test
tearDown() {
  if [ -d "${TEST_OUTPUT_DIR}" ]; then
    # rm -rf "${TEST_OUTPUT_DIR}"
    echo "Would rm the dir ${TEST_OUTPUT_DIR}"
  fi
}

# Test 1: Merge two templates successfully
testMergeTwoTemplates() {
  local templates="Template1/v1/config1 Template2/v1/config1"
  local label="test_merge_two"
  
  mergeProductLists "${templates}" "${label}" "${TEST_OUTPUT_DIR}"
  local result=$?
  
  assertEquals "Function should return 0 on success" 0 ${result}
  assertTrue "Output file should exist" "[ -f '${TEST_OUTPUT_DIR}/${label}.productlist.txt' ]"
  
  # Check that we have the expected number of unique lines (6 unique products)
  local lineCount
  lineCount=$(wc -l < "${TEST_OUTPUT_DIR}/${label}.productlist.txt")
  assertEquals "Should have 6 unique products" 6 ${lineCount}
  
  # Verify deduplication worked (PIECore and license appear in both)
  local pieCount
  pieCount=$(grep -c "PIECore" "${TEST_OUTPUT_DIR}/${label}.productlist.txt")
  assertEquals "PIECore should appear only once" 1 ${pieCount}
}

# Test 2: Merge single template
testMergeSingleTemplate() {
  local templates="Template3/v1/config1"
  local label="test_single"
  
  mergeProductLists "${templates}" "${label}" "${TEST_OUTPUT_DIR}"
  local result=$?
  
  assertEquals "Function should return 0 on success" 0 ${result}
  assertTrue "Output file should exist" "[ -f '${TEST_OUTPUT_DIR}/${label}.productlist.txt' ]"
  
  local lineCount
  lineCount=$(wc -l < "${TEST_OUTPUT_DIR}/${label}.productlist.txt")
  assertEquals "Should have 2 products" 2 ${lineCount}
}

# Test 3: Merge three templates
testMergeThreeTemplates() {
  local templates="Template1/v1/config1 Template2/v1/config1 Template3/v1/config1"
  local label="test_three"
  
  mergeProductLists "${templates}" "${label}" "${TEST_OUTPUT_DIR}"
  local result=$?
  
  assertEquals "Function should return 0 on success" 0 ${result}
  assertTrue "Output file should exist" "[ -f '${TEST_OUTPUT_DIR}/${label}.productlist.txt' ]"
  
  local lineCount
  lineCount=$(wc -l < "${TEST_OUTPUT_DIR}/${label}.productlist.txt")
  assertEquals "Should have 8 unique products" 8 ${lineCount}
}

# Test 4: Output is sorted
testOutputIsSorted() {
  local templates="Template1/v1/config1 Template2/v1/config1"
  local label="test_sorted"
  
  mergeProductLists "${templates}" "${label}" "${TEST_OUTPUT_DIR}"
  
  # Check if file is sorted
  local sortedFile="${TEST_OUTPUT_DIR}/${label}.productlist.txt.sorted"
  sort "${TEST_OUTPUT_DIR}/${label}.productlist.txt" > "${sortedFile}"
  
  diff "${TEST_OUTPUT_DIR}/${label}.productlist.txt" "${sortedFile}" >/dev/null
  local diffResult=$?
  
  assertEquals "Output should be sorted" 0 ${diffResult}
  rm -f "${sortedFile}"
}

# Test 5: Missing template ID parameter
testMissingTemplateParameter() {
  local label="test_missing_template"
  
  mergeProductLists "" "${label}" "${TEST_OUTPUT_DIR}" 2>/dev/null
  local result=$?
  
  assertEquals "Should return error code 1 for missing template list" 1 ${result}
}

# Test 6: Missing label parameter
testMissingLabelParameter() {
  local templates="Template1/v1/config1"
  
  mergeProductLists "${templates}" "" "${TEST_OUTPUT_DIR}" 2>/dev/null
  local result=$?
  
  assertEquals "Should return error code 2 for missing label" 2 ${result}
}

# Test 7: Non-existent template
testNonExistentTemplate() {
  local templates="NonExistent/Template/Path"
  local label="test_nonexistent"
  
  mergeProductLists "${templates}" "${label}" "${TEST_OUTPUT_DIR}" 2>/dev/null
  local result=$?
  
  assertEquals "Should return error code 5 when no valid templates found" 5 ${result}
}

# Test 8: Mix of valid and invalid templates
testMixedValidInvalidTemplates() {
  local templates="Template1/v1/config1 NonExistent/Template Template2/v1/config1"
  local label="test_mixed"
  
  mergeProductLists "${templates}" "${label}" "${TEST_OUTPUT_DIR}"
  local result=$?
  
  assertEquals "Should return 0 when at least one template is valid" 0 ${result}
  assertTrue "Output file should exist" "[ -f '${TEST_OUTPUT_DIR}/${label}.productlist.txt' ]"
  
  # Should have products from the two valid templates
  local lineCount
  lineCount=$(wc -l < "${TEST_OUTPUT_DIR}/${label}.productlist.txt")
  assertEquals "Should have 6 unique products from valid templates" 6 ${lineCount}
}

# Test 9: Default destination folder (/tmp)
testDefaultDestinationFolder() {
  local templates="Template1/v1/config1"
  local label="test_default_dest_$$"
  
  mergeProductLists "${templates}" "${label}"
  local result=$?
  
  assertEquals "Function should return 0 on success" 0 ${result}
  assertTrue "Output file should exist in /tmp" "[ -f '/tmp/${label}.productlist.txt' ]"
  
  # Cleanup
  rm -f "/tmp/${label}.productlist.txt"
}

# Test 10: Create destination folder if it doesn't exist
testCreateDestinationFolder() {
  local templates="Template1/v1/config1"
  local label="test_create_dest"
  local newDestDir="${TEST_OUTPUT_DIR}/new/nested/folder"
  
  mergeProductLists "${templates}" "${label}" "${newDestDir}"
  local result=$?
  
  assertEquals "Function should return 0 on success" 0 ${result}
  assertTrue "Destination folder should be created" "[ -d '${newDestDir}' ]"
  assertTrue "Output file should exist" "[ -f '${newDestDir}/${label}.productlist.txt' ]"
}

# Load and run shunit2
localTestDir=${WMUI_TEST_DIR:-/tmp/WMUI_TESTS}
if [ ! -f "${localTestDir}/shunit2" ]; then
  mkdir -p "${localTestDir}"
  curl -s https://raw.githubusercontent.com/kward/shunit2/master/shunit2 -o "${localTestDir}"/shunit2
fi

# Made with Bob

# Test 11: Real templates from the repository
testRealTemplates() {
  # Test with actual templates from the repository
  # DBC/1101/full (34 products)
  # APIGateway/1101/cds-e2e-postgres (44 products)
  # MSR/1101/selection-20250924 (52 products)
  
  local templates="DBC/1101/full APIGateway/1101/cds-e2e-postgres MSR/1101/selection-20250924"
  local label="test_real_templates"
  
  # Override WMUI_CACHE_HOME to point to the actual repository location
  local originalCacheHome="${WMUI_CACHE_HOME}"
  export WMUI_CACHE_HOME="${WMUI_HOME}"
  
  mergeProductLists "${templates}" "${label}" "${TEST_OUTPUT_DIR}"
  local result=$?
  
  # Restore original WMUI_CACHE_HOME
  export WMUI_CACHE_HOME="${originalCacheHome}"
  
  assertEquals "Function should return 0 on success with real templates" 0 ${result}
  assertTrue "Output file should exist" "[ -f '${TEST_OUTPUT_DIR}/${label}.productlist.txt' ]"
  
  # Verify the file has content
  local lineCount
  lineCount=$(wc -l < "${TEST_OUTPUT_DIR}/${label}.productlist.txt")
  assertTrue "Should have at least 50 unique products" "[ ${lineCount} -ge 50 ]"
  
  # Verify some expected products are present
  grep -q "e2ei/11/DCC_11.1.0.0.LATEST/CDC/DatabaseComponentConfiguratorCore" "${TEST_OUTPUT_DIR}/${label}.productlist.txt"
  assertEquals "Should contain DatabaseComponentConfiguratorCore" 0 $?
  
  grep -q "e2ei/11/YAI_11.1.0.0.LATEST/YAI/YAI" "${TEST_OUTPUT_DIR}/${label}.productlist.txt"
  assertEquals "Should contain YAI" 0 $?
  
  grep -q "e2ei/11/WST_11.1.0.0.LATEST/cloudstreams/wst" "${TEST_OUTPUT_DIR}/${label}.productlist.txt"
  assertEquals "Should contain cloudstreams/wst" 0 $?
  
  # Verify deduplication - count occurrences of a product that appears in all three
  local sjpCount
  sjpCount=$(grep -c "e2ei/11/SJP_17.0.12.0.LATEST/Infrastructure/sjp" "${TEST_OUTPUT_DIR}/${label}.productlist.txt")
  assertEquals "sjp should appear only once despite being in all templates" 1 ${sjpCount}
  
  logI "Real templates test: merged ${lineCount} unique products from 3 templates"
}

# shellcheck source=/dev/null
. "${localTestDir}"/shunit2
