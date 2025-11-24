#!/bin/sh
set -e

# Safeguard: define a no-op function to catch stray 'REPLACE' tokens
REPLACE() { :; }

# Safeguard: define a no-op function to catch stray 'REPLACE' tokens
REPLACE() { :; }

# Ensure yq is executable to avoid permission denied
YQ_BIN=$(command -v yq 2>/dev/null || true)
if [ -n "$YQ_BIN" ] && [ ! -x "$YQ_BIN" ]; then
  echo "Attempting to fix yq execute permission: $YQ_BIN"
  chmod +x "$YQ_BIN" 2>/dev/null || true
fi



echo
# Enable verbose tracing if debugging is requested
if [ "${ASHIGARU_DEBUG}" = "1" ]; then
  set -x
fi


echo "=== ASHIGARU TERMINAL DEBUG INITIALIZATION ==="
echo "Initialising Ashigaru Terminal..."
echo


_term() { 
  echo "Caught SIGTERM signal!" 
  kill -TERM "$backend_process" 2>/dev/null
  kill -TERM "$db_process" 2>/dev/null
  kill -TERM "$frontend_process" 2>/dev/null
}

# DEBUG: Show environment and file structure
echo "=== DEBUG: Environment Check ==="
echo "Current working directory: $(pwd)"
echo "User: $(whoami)"
echo "Home directory: $HOME"

# Check if yq is available
echo "=== DEBUG: Tool Check ==="
if command -v yq >/dev/null 2>&1; then
  YQ_VERSION=$(yq --version 2>/dev/null || echo "version unknown")
  echo "✓ yq is available: $YQ_VERSION"
else
  echo "✗ yq is NOT available - configuration parsing will fail"
  echo "Available tools in PATH:"
  which yq || echo "yq not found"
  ls -la /usr/local/bin/yq || echo "yq binary not found in /usr/local/bin/"
  echo "PATH: $PATH"
fi

echo "=== DEBUG: File Structure Check ==="
echo "Checking for StartOS config file..."
if [ -f /root/start9/config.yaml ]; then
  echo "✓ StartOS config file found at /root/start9/config.yaml"
  echo "StartOS config contents:"
  cat /root/start9/config.yaml
else
  echo "✗ StartOS config file NOT found at /root/start9/config.yaml"
  echo "Looking for alternative config locations..."
  find /root -name "config.yaml" -type f 2>/dev/null || echo "No config.yaml files found"
fi

echo "=== DEBUG: Ashigaru Config Check ==="
if [ ! -f /root/.ashigaru/config ]; then
  echo "No Ashigaru config file found, creating default"
  mkdir -p /root/.ashigaru
  cp /root/defaults/.ashigaru/config /root/.ashigaru/config
  echo "✓ Created default config from /root/defaults/.ashigaru/config"
else
  echo "✓ Existing Ashigaru config found at /root/.ashigaru/config"
fi

echo "Current Ashigaru config before changes:"
cat /root/.ashigaru/config

echo "=== DEBUG: Testing yq functionality ==="
echo "test: value" | yq '.test'
echo "Reading managesettings directly:"
yq '.ashigaru.managesettings' /root/start9/config.yaml
echo "Raw output check complete"

# Manage Ashigaru settings?
echo "=== DEBUG: Configuration Management Check ==="
if [ -f /root/start9/config.yaml ]; then
  # Check if yq is working, otherwise use defaults
  if command -v yq >/dev/null 2>&1 && yq --version >/dev/null 2>&1; then
    # Get managesettings value with better error handling
    MANAGE_SETTINGS=$(yq '.ashigaru.managesettings' /root/start9/config.yaml 2>/dev/null || echo "null")
    echo "StartOS managesettings value: '$MANAGE_SETTINGS'"
    
    # Handle case where managesettings is missing or null - default to true for backward compatibility
    if [ "$MANAGE_SETTINGS" = "null" ] || [ -z "$MANAGE_SETTINGS" ]; then
      echo "→ managesettings field is missing or null, defaulting to 'true' for backward compatibility"
      MANAGE_SETTINGS="true"
    fi
    
    if [ "$MANAGE_SETTINGS" = "true" ]; then
      echo "✓ Applying Ashigaru configuration settings..."
      
    # DEBUG: Show raw values from StartOS config
    echo "=== DEBUG: Raw StartOS Configuration Values ==="
    NETWORK_TYPE=$(yq '.ashigaru.network.type' /root/start9/config.yaml 2>/dev/null || echo "null")
    SERVER_TYPE=$(yq '.ashigaru.server.type' /root/start9/config.yaml 2>/dev/null || echo "null")
    PROXY_TYPE=$(yq '.ashigaru.proxy.type' /root/start9/config.yaml 2>/dev/null || echo "null")
    echo "Network type from StartOS: '$NETWORK_TYPE'"
    echo "Server type from StartOS: '$SERVER_TYPE'"
    echo "Proxy type from StartOS: '$PROXY_TYPE'"
    
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
      
      # Configure Bitcoin network
      echo "=== DEBUG: Bitcoin Network Configuration ==="
      case "$NETWORK_TYPE" in
      "testnet")
        echo "→ Configuring Ashigaru for Testnet"
        echo "Setting network to TESTNET"
        # Update electrum server for testnet if using fulcrum
        if [ "$SERVER_TYPE" = "fulcrum" ]; then
          echo "Setting testnet fulcrum server to tcp://fulcrum.embassy:50001"
          yq e -i '
            .networkType = "TESTNET" |
            .electrumServer = "tcp://fulcrum.embassy:50001"' -o=json /root/.ashigaru/config
        fi
        echo "✓ Testnet configuration applied"
        ;;
      "mainnet")
        echo "→ Configuring Ashigaru for Mainnet"
        echo "Setting network to MAINNET"
        # Update electrum server for mainnet if using fulcrum
        if [ "$SERVER_TYPE" = "fulcrum" ]; then
          echo "Setting mainnet fulcrum server to tcp://fulcrum.embassy:50001"
          yq e -i '
            .networkType = "MAINNET" |
            .electrumServer = "tcp://fulcrum.embassy:50001"' -o=json /root/.ashigaru/config
        fi
        echo "✓ Mainnet configuration applied"
        ;;
      *)
        echo "✗ Unknown network type '$NETWORK_TYPE', defaulting to mainnet"
        yq e -i '.networkType = "MAINNET"' -o=json /root/.ashigaru/config
        ;;
      esac
      
      # Configure electrum server
    echo "=== DEBUG: Electrum Server Configuration ==="
    case "$SERVER_TYPE" in
    "fulcrum")
      echo "→ Configuring Ashigaru for Fulcrum"
      echo "Setting serverType to ELECTRUM_SERVER"
      echo "Setting electrumServer to tcp://fulcrum.embassy:50001"
      yq e -i '
        .serverType = "ELECTRUM_SERVER" |
        .electrumServer = "tcp://fulcrum.embassy:50001"' -o=json /root/.ashigaru/config
      echo "✓ Fulcrum configuration applied"
      ;;
    "public")
      echo "→ Configuring Ashigaru for Public electrum server"
      echo "Setting serverType to PUBLIC_ELECTRUM_SERVER"
      yq e -i '.serverType = "PUBLIC_ELECTRUM_SERVER"' -o=json /root/.ashigaru/config
      echo "✓ Public server configuration applied"
      ;;
    *)
      echo "✗ Unknown server type '$SERVER_TYPE', not configuring Ashigaru"
      ;;
    esac

    # Configure proxy
    echo "=== DEBUG: Proxy Configuration ==="
    case "$PROXY_TYPE" in
    "tor")
      echo "→ Configuring Ashigaru for Tor"
      export EMBASSY_IP=$(ip -4 route list match 0/0 | awk '{print $3}')
      echo "Embassy IP detected: $EMBASSY_IP"
      echo "Setting useProxy to true"
      echo "Setting proxyServer to $EMBASSY_IP:9050"
      yq e -i '
        .useProxy = true |
        .proxyServer = strenv(EMBASSY_IP) + ":9050"' -o=json /root/.ashigaru/config
      echo "✓ Tor proxy configuration applied"
      ;;
    "none")
      echo "→ Configuring Ashigaru for 'no proxy'"
      echo "Setting useProxy to false"
      yq e -i '.useProxy = false' -o=json /root/.ashigaru/config
      echo "✓ No proxy configuration applied"
      ;;
    *)
      echo "✗ Unknown proxy type '$PROXY_TYPE', not configuring Ashigaru"
      ;;
    esac
    else
      echo "✗ managesettings is not 'true' (value: '$MANAGE_SETTINGS'), skipping configuration"
    fi
  else
    echo "✗ yq is not working properly, using existing Ashigaru configuration"
    echo "→ Current configuration will be used as-is"
    echo "→ electrumServer: $(grep -o '"electrumServer":"[^"]*"' /root/.ashigaru/config || echo 'not found')"
    echo "→ serverType: $(grep -o '"serverType":"[^"]*"' /root/.ashigaru/config || echo 'not found')"
  fi
else
  echo "✗ No StartOS config file found, cannot apply configuration"
fi

echo "=== DEBUG: Final Ashigaru Configuration ==="
echo "Ashigaru config after all changes:"
cat /root/.ashigaru/config

# Note: Socat proxy is not needed since we're using fulcrum.embassy hostname directly
# Ashigaru will connect through Tor to the fulcrum.embassy onion service
echo "=== DEBUG: Socat Proxy Setup ==="
echo "→ Not setting up socat proxy (using fulcrum.embassy hostname directly)"
echo "→ Ashigaru will connect through Tor to fulcrum.embassy:50001"

echo "=== DEBUG: Network Connectivity Check ==="
echo "Checking if fulcrum.embassy is reachable..."
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

# Note: Port check is not relevant since we're using fulcrum.embassy hostname through Tor
# The connection will be made through the Tor proxy, not direct local ports
echo "=== DEBUG: Port Check ==="
echo "→ Not checking local ports (using fulcrum.embassy through Tor proxy)"
echo "→ Connection will be: Ashigaru → Tor Proxy → fulcrum.embassy:50001"

echo "=== DEBUG: Pre-launch Summary ==="
if command -v yq >/dev/null 2>&1 && yq --version >/dev/null 2>&1; then
  echo "Configuration management: $([ -f /root/start9/config.yaml ] && yq '.ashigaru.managesettings' /root/start9/config.yaml || echo 'N/A')"
  echo "Network type: $([ -f /root/start9/config.yaml ] && yq '.ashigaru.network.type' /root/start9/config.yaml || echo 'N/A')"
  echo "Server type: $([ -f /root/start9/config.yaml ] && yq '.ashigaru.server.type' /root/start9/config.yaml || echo 'N/A')"
  echo "Proxy type: $([ -f /root/start9/config.yaml ] && yq '.ashigaru.proxy.type' /root/start9/config.yaml || echo 'N/A')"
  echo "Final electrumServer setting: $(yq '.electrumServer' /root/.ashigaru/config)"
  echo "Final serverType setting: $(yq '.serverType' /root/.ashigaru/config)"
  echo "Final networkType setting: $(yq '.networkType' /root/.ashigaru/config)"
else
  echo "Configuration management: N/A (yq not working)"
  echo "Network type: N/A (yq not working)"
  echo "Server type: N/A (yq not working)"
  echo "Proxy type: N/A (yq not working)"
  echo "Final electrumServer setting: $(grep -o '"electrumServer":"[^"]*"' /root/.ashigaru/config || echo 'not found')"
  echo "Final serverType setting: $(grep -o '"serverType":"[^"]*"' /root/.ashigaru/config || echo 'not found')"
  echo "Final networkType setting: $(grep -o '"networkType":"[^"]*"' /root/.ashigaru/config || echo 'not found')"
fi

echo
echo "=== END DEBUG INITIALIZATION ==="
echo "Launching Ashigaru Terminal"
echo

exec /usr/local/bin/docker-entrypoint.sh
