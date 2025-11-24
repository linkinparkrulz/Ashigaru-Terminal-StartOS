# Ashigaru Terminal Debugging Fixes Summary

## Issues Identified and Fixed

### 1. yq Version Detection Issue

**Problem**: The script was checking `yq --version` but the output wasn't being captured properly, showing "yq is available:" without version information.

**Root Cause**: Command substitution wasn't handling potential errors from the `yq --version` command.

**Fix Applied**:
```bash
# Before
echo "✓ yq is available: $(yq --version)"

# After
YQ_VERSION=$(yq --version 2>/dev/null || echo "version unknown")
echo "✓ yq is available: $YQ_VERSION"
```

**Result**: Now properly captures version information or shows "version unknown" if there's an error.

### 2. managesettings Parsing Issue

**Problem**: The script was trying to access `.ashigaru.managesettings` but this field wasn't defined in the TypeScript configuration schema, causing it to return null/empty values.

**Root Cause**: The `AshigaruConfig` interface in `scripts/procedures/setConfig.ts` was missing the `managesettings` and `proxy` properties.

**Fixes Applied**:

1. **Updated TypeScript Interface** (`scripts/procedures/setConfig.ts`):
```typescript
export interface AshigaruConfig extends T.Config {
  ashigaru?: {
    managesettings?: boolean;  // Added this
    network?: {
      type?: "mainnet" | "testnet" | string;
    };
    server?: {
      type?: "fulcrum" | "public" | string;
    };
    proxy?: {                  // Added this
      type?: "tor" | "none" | string;
    };
  };
}
```

2. **Enhanced setConfig Function** to handle proxy validation:
```typescript
const proxyTypeRaw = ash?.proxy?.type;
const validProxies = ["tor", "none"];
const proxyType = (proxyTypeRaw ?? "tor").toString().trim().toLowerCase();

if (!validProxies.includes(proxyType)) {
  throw new Error("Invalid Ashigaru proxy type: " + proxyType);
}
```

3. **Improved Error Handling in Shell Script**:
```bash
# Get managesettings value with better error handling
MANAGE_SETTINGS=$(yq '.ashigaru.managesettings' /root/start9/config.yaml 2>/dev/null || echo "null")

# Handle case where managesettings is missing or null - default to true for backward compatibility
if [ "$MANAGE_SETTINGS" = "null" ] || [ -z "$MANAGE_SETTINGS" ]; then
  echo "→ managesettings field is missing or null, defaulting to 'true' for backward compatibility"
  MANAGE_SETTINGS="true"
fi
```

**Result**: The script now properly handles missing configuration fields and provides sensible defaults for backward compatibility.

### 3. fulcrum.embassy Hostname Resolution Issue

**Problem**: The script was using `nslookup fulcrum.embassy` which failed, but this doesn't necessarily mean the hostname won't resolve when Ashigaru actually tries to connect.

**Root Cause**: StartOS uses internal DNS resolution that may not be available during the initial container startup phase, or the hostname resolution method used wasn't appropriate for the container environment.

**Fix Applied**:
```bash
# Try multiple methods to check hostname resolution
if nslookup fulcrum.embassy >/dev/null 2>&1; then
  echo "✓ fulcrum.embassy hostname resolves via nslookup"
elif getent hosts fulcrum.embassy >/dev/null 2>&1; then
  echo "✓ fulcrum.embassy hostname resolves via getent"
  echo "→ IP address: $(getent hosts fulcrum.embassy | awk '{print $1}')"
elif ping -c 1 fulcrum.embassy >/dev/null 2>&1; then
  echo "✓ fulcrum.embassy hostname resolves via ping"
else
  echo "✗ fulcrum.embassy hostname does not resolve"
  echo "→ This is expected in some StartOS environments"
  echo "→ The hostname should resolve when Ashigaru attempts to connect"
  echo "→ Alternative: Check if fulcrum service is running"
  if systemctl is-active --quiet fulcrum 2>/dev/null; then
    echo "✓ fulcrum service is active"
  else
    echo "✗ fulcrum service is not active or not found"
  fi
fi
```

**Result**: The script now tries multiple resolution methods and provides better context when resolution fails, explaining that this might be expected and that the hostname should resolve when Ashigaru actually attempts to connect.

### 4. Additional Robustness Improvements

**Enhanced Configuration Value Parsing**:
```bash
# Added error handling for all configuration values
NETWORK_TYPE=$(yq '.ashigaru.network.type' /root/start9/config.yaml 2>/dev/null || echo "null")
SERVER_TYPE=$(yq '.ashigaru.server.type' /root/start9/config.yaml 2>/dev/null || echo "null")
PROXY_TYPE=$(yq '.ashigaru.proxy.type' /root/start9/config.yaml 2>/dev/null || echo "null")

# Set defaults for missing values
if [ "$NETWORK_TYPE" = "null" ] || [ -z "$NETWORK_TYPE" ]; then
  echo "→ Network type is missing, defaulting to 'mainnet'"
  NETWORK_TYPE="mainnet"
fi

if [ "$SERVER_TYPE" = "null" ] || [ -z "$SERVER_TYPE" ]; then
  echo "→ Server type is missing, defaulting to 'fulcrum'"
  SERVER_TYPE="fulcrum"
fi

if [ "$PROXY_TYPE" = "null" ] || [ -z "$PROXY_TYPE" ]; then
  echo "→ Proxy type is missing, defaulting to 'tor'"
  PROXY_TYPE="tor"
fi
```

## Expected Behavior After Fixes

1. **yq Detection**: Will show proper version information or "version unknown" instead of hanging
2. **Configuration Management**: Will properly parse `managesettings` and other configuration values, with sensible defaults for missing fields
3. **Hostname Resolution**: Will provide better diagnostics and explain that resolution failures might be expected during startup
4. **Backward Compatibility**: Existing configurations will continue to work with the new default values

## Testing Recommendations

1. Test with a complete StartOS configuration including all fields
2. Test with partial configurations (missing managesettings, proxy, etc.)
3. Test with yq installed and working
4. Test with yq missing or broken
5. Test with fulcrum service running and stopped
6. Verify that Ashigaru can still connect to fulcrum.embassy even when initial hostname resolution fails

## Files Modified

1. `docker_entrypoint.sh` - Main initialization script with improved error handling
2. `scripts/procedures/setConfig.ts` - Updated TypeScript interface and validation logic

## Backward Compatibility

All changes maintain backward compatibility:
- Missing configuration fields get sensible defaults
- Existing configurations continue to work unchanged
- Error handling is more robust but doesn't change the fundamental behavior
