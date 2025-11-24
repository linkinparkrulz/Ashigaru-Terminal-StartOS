# Ashigaru Terminal Configuration Debugging Guide

This guide explains how configuration flows from the StartOS interface to the Ashigaru docker container and how to debug issues with electrum server settings.

## Configuration Flow Overview

```
StartOS UI → getConfig.ts → setConfig.ts → /root/start9/config.yaml → docker_entrypoint.sh → /root/.ashigaru/config
```

### Step 1: StartOS Interface Configuration

**File**: `scripts/procedures/getConfig.ts`
- Defines the UI structure for configuration options
- Shows these options in the StartOS "Config" section:
  - `ashigaru.managesettings`: Boolean to enable/disable automatic config
  - `ashigaru.server.type`: "fulcrum" or "public"
  - `ashigaru.proxy.type`: "tor" or "none"

### Step 2: Configuration Validation and Storage

**File**: `scripts/procedures/setConfig.ts`
- Called when user saves configuration in StartOS UI
- Validates the configuration
- Sets up dependencies (e.g., requires fulcrum service if selected)
- Stores configuration in `/root/start9/config.yaml`

**Debug Output**: When you change settings in StartOS, check the service logs for:
```
=== ASHIGARU SETCONFIG DEBUG ===
setConfig called with newConfig: {...}
Extracted server type: fulcrum
Fulcrum dependencies: {"fulcrum": ["synced"]}
Final dependencies to apply: {"fulcrum": ["synced"]}
Calling compat.setConfig...
compat.setConfig completed
=== END SETCONFIG DEBUG ===
```

### Step 3: Docker Container Initialization

**File**: `docker_entrypoint.sh`
- Runs every time the Ashigaru container starts
- Reads configuration from `/root/start9/config.yaml`
- Applies settings to `/root/.ashigaru/config` if `managesettings=true`
- Sets up socat proxy for fulcrum connections

## Debugging the Configuration Process

### 1. Check StartOS Configuration Application

When you change settings in the StartOS UI:

1. **Check service logs** for the setConfig debug output
2. **Verify the config file** was created:
   ```bash
   # In the StartOS container
   cat /root/start9/config.yaml
   ```

Expected content:
```yaml
ashigaru:
  managesettings: true
  server:
    type: fulcrum
  proxy:
    type: tor
```

### 2. Check Docker Container Initialization

When the Ashigaru container starts, it will output extensive debugging information:

```bash
# Check container logs
docker logs <ashigaru-container-id>
```

Look for these sections:

#### Environment Check
```
=== DEBUG: Environment Check ===
Current working directory: /root
User: root
Home directory: /root
```

#### File Structure Check
```
=== DEBUG: File Structure Check ===
Checking for StartOS config file...
✓ StartOS config file found at /root/start9/config.yaml
StartOS config contents:
ashigaru:
  managesettings: true
  server:
    type: fulcrum
  proxy:
    type: tor
```

#### Configuration Management Check
```
=== DEBUG: Configuration Management Check ===
StartOS managesettings value: 'true'
✓ Applying Ashigaru configuration settings...

=== DEBUG: Raw StartOS Configuration Values ===
Server type from StartOS: 'fulcrum'
Proxy type from StartOS: 'tor'
```

#### Electrum Server Configuration
```
=== DEBUG: Electrum Server Configuration ===
→ Configuring Ashigaru for Fulcrum
Setting serverType to ELECTRUM_SERVER
Setting electrumServer to tcp://127.0.0.1:50001
✓ Fulcrum configuration applied
```

#### Final Configuration
```
=== DEBUG: Final Ashigaru Configuration ===
Ashigaru config after all changes:
{
  "mode": "ONLINE",
  "serverType": "ELECTRUM_SERVER",
  "electrumServer": "tcp://127.0.0.1:50001",
  ...
}
```

#### Socat Proxy Setup
```
=== DEBUG: Socat Proxy Setup ===
Server type for socat check: 'fulcrum'
→ Setting up socat proxy for Fulcrum...
Command: /usr/bin/socat tcp-l:50001,fork,reuseaddr,su=nobody,bind=127.0.0.1 tcp:fulcrum.embassy:50001
✓ Socat proxy started with PID: 123
✓ Socat proxy is running successfully
```

#### Network Connectivity Check
```
=== DEBUG: Network Connectivity Check ===
Checking if fulcrum.embassy is reachable...
✓ fulcrum.embassy hostname resolves
Checking local port 50001...
✓ Port 50001 is listening
tcp   LISTEN  0      128            127.0.0.1:50001       0.0.0.0:*    users:(("socat",pid=123,fd=3))
```

## Common Issues and Solutions

### Issue 1: "managesettings is not 'true'"

**Symptoms**: Configuration changes in UI don't affect Ashigaru
**Debug Output**: `✗ managesettings is not 'true' (value: 'false'), skipping configuration`
**Solution**: Ensure "Apply settings on startup" is enabled in the StartOS UI

### Issue 2: StartOS config file not found

**Symptoms**: No configuration applied
**Debug Output**: `✗ StartOS config file NOT found at /root/start9/config.yaml`
**Solution**: 
1. Check if setConfig completed successfully
2. Verify StartOS service is properly installed
3. Restart the service to trigger config creation

### Issue 3: Unknown server type

**Symptoms**: Electrum server not configured
**Debug Output**: `✗ Unknown server type 'unknown', not configuring Ashigaru`
**Solution**: Check the getConfig.ts definition and ensure UI options match expected values

### Issue 4: Socat proxy fails to start

**Symptoms**: Can't connect to fulcrum
**Debug Output**: `✗ Socat proxy failed to start`
**Solution**:
1. Check if fulcrum service is running: `systemctl status fulcrum`
2. Verify hostname resolution: `nslookup fulcrum.embassy`
3. Check if port 50001 is already in use

### Issue 5: Port 50001 not listening

**Symptoms**: Connection refused errors
**Debug Output**: `✗ Port 50001 is not listening`
**Solution**:
1. Ensure socat proxy started successfully
2. Check if fulcrum is running on the expected port
3. Verify firewall settings

## Manual Configuration Verification

If automatic configuration fails, you can manually verify and fix:

### 1. Check StartOS Config
```bash
# In StartOS container
cat /root/start9/config.yaml
```

### 2. Check Ashigaru Config
```bash
# In Ashigaru container
cat /root/.ashigaru/config | jq '.electrumServer, .serverType'
```

### 3. Test Fulcrum Connection
```bash
# In Ashigaru container
nc -zv 127.0.0.1 50001
# Should return: Connection to 127.0.0.1 50001 port [tcp/*] succeeded!
```

### 4. Test Fulcrum Service
```bash
# In StartOS container
nc -zv fulcrum.embassy 50001
```

## Rebuilding with Debugging

To apply the debugging changes:

1. **Build the package**:
   ```bash
   make
   ```

2. **Install the updated package**:
   ```bash
   start-cli packages install ashigaru.s9pk
   ```

3. **Configure the service** in StartOS UI:
   - Enable "Apply settings on startup"
   - Set "Electrum Server" to "Fulcrum (recommended)"
   - Set "Use a proxy" to "Tor (recommended)"

4. **Check the logs** after starting:
   ```bash
   start-cli logs ashigaru
   ```

## Expected Successful Flow

When everything works correctly, you should see:

1. **setConfig debug** when changing settings in UI
2. **Complete docker_entrypoint debug** on container start
3. **All checks pass** (✓ symbols)
4. **Final configuration** shows correct electrumServer
5. **Socat proxy running** and port 50001 listening
6. **Ashigaru connects** to your local fulcrum successfully

This comprehensive debugging will help you identify exactly where the configuration process breaks down and fix the issue.
