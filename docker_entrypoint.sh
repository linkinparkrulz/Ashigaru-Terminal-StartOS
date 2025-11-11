#!/bin/sh
set -e

echo
echo "Initialising Ashigaru Terminal..."
echo

_term() { 
  echo "Caught SIGTERM signal!" 
  kill -TERM "$backend_process" 2>/dev/null
  kill -TERM "$db_process" 2>/dev/null
  kill -TERM "$frontend_process" 2>/dev/null
}

# Copy default Ashigaru config if it doesn't exist
if [ ! -f /root/.ashigaru/config ]; then
  echo "No Ashigaru config file found, creating default"
  mkdir -p /root/.ashigaru
  cp /root/defaults/.ashigaru/config /root/.ashigaru/config
fi

# Manage Ashigaru settings?
if [ "$(yq e '.ashigaru.managesettings' /root/start9/config.yaml)" = "true" ]; then
  echo "Applying Ashigaru configuration settings..."
  
  # Configure electrum server
  case "$(yq e '.ashigaru.server.type' /root/start9/config.yaml)" in
  "fulcrum")
    echo "Configuring Ashigaru for Fulcrum"
    yq e -i '
      .serverType = "ELECTRUM_SERVER" |
      .electrumServer = "tcp://fulcrum.embassy:50001"' -o=json /root/.ashigaru/config
    ;;
  "public")
    echo "Configuring Ashigaru for Public electrum server"
    yq e -i '.serverType = "PUBLIC_ELECTRUM_SERVER"' -o=json /root/.ashigaru/config
    ;;
  *)
    echo "Unknown server selected, not configuring Ashigaru"
    ;;
  esac

  # Configure proxy
  "tor")
    echo "Configuring Ashigaru for Tor"
    yq e -i '
      .useProxy = true |
      .proxyServer = "embassy:9050"
    ' -o=json /root/.ashigaru/config
    ;;
  case "$(yq e '.ashigaru.proxy.type' /root/start9/config.yaml)" in
    ;;
  "none")
    echo "Configuring Ashigaru for 'no proxy'"
    yq e -i '.useProxy = false' -o=json /root/.ashigaru/config
    ;;
  *)
    echo "Unknown proxy selected, not configuring Ashigaru"
    ;;
  esac
fi

echo "Launching Ashigaru Terminal"

exec /usr/local/bin/docker-entrypoint.sh
