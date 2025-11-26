**Ashigaru Terminal User Guide**
=====================================

**Introduction**
---------------

Ashigaru Terminal is a terminal-based application that enables users to participate in Whirlpool CoinJoin cycles with the goal of strengthening privacy in Bitcoin transactions.

**Key Features**
----------------

*   **Self-Custody**: Users retain complete control over their wallets and keys throughout the entire process.
*   **Privacy-Preserving**: Sensitive information such as master public keys or wallet structures remain private.
*   **Anonymity**: Connections are routed through Tor by default, preventing observers from linking activity to a particular IP address.

**Using Ashigaru Terminal**
---------------------------

### Configuration via StartOS

Ashigaru Terminal is automatically configured through the StartOS interface. No manual configuration is needed inside Ashigaru Terminal itself.

#### Network Selection
Choose your Bitcoin network in StartOS settings:
*   **Mainnet**: Use the real Bitcoin network for actual transactions
*   **Testnet4**: Use the test network for testing with fake bitcoins

#### Server Type
Choose how Ashigaru connects to the Bitcoin network:
*   **Private Fulcrum**: Uses your Embassy's local Fulcrum service (recommended)
    *   More private - connections stay within your Embassy
    *   Requires the Fulcrum package to be installed
    *   Automatically configured as `fulcrum.embassy:50001`
*   **Public Electrum**: Uses external public servers
    *   Less private - connections go to external servers
    *   No additional packages required
    *   Uses Foundation's mainnet Fulcrum server

#### Proxy Settings
Choose how your connections are routed:
*   **Tor**: Routes all connections through Tor (recommended for privacy)
    *   Hides your IP address from Electrum servers
    *   Automatically configured to use Embassy's Tor service
    *   Slightly slower but much more private
*   **None**: Direct connections without proxy
    *   Faster but exposes your IP address
    *   Not recommended for privacy-conscious users

#### How It Works
1.  Configure your settings in the StartOS Ashigaru Terminal interface
2.  Restart the service to apply changes
3.  Ashigaru automatically launches with the correct configuration
4.  No manual setup needed inside the Ashigaru application

### Accessing the Web Terminal

Click the "Launch UI" button in StartOS to access Ashigaru Terminal through your web browser. The web terminal provides full access to Ashigaru's features.

### Pasting Content

To paste content into the web terminal:

*   On Windows or Linux, use `Ctrl+Shift+V`.
*   On macOS, use `Cmd+Shift+V`.

Note: In LibreWolf or Tor Browser, it may be necessary to disable 'resistFingerprinting' for the web terminal to function properly. Alternatively, you can use a Chromium-based browser such as Brave (even over tor).

### Important Notes

*   **Updates**: Updates may not retain existing wallets. **Always back up your seed phrase securely**, especially before upgrading or migrating.
*   **Combination with Ashigaru Mobile App**: Ashigaru Terminal is designed to be used in combination with the Ashigaru Mobile App.
*   You will not be able to copy a deposit address from Ashigaru Terminal into your clipboard unfortunately. It is reccomended to display a QR instead or copy over the address manually (Triple check you have the right address before depositing)
*   The proper way to Stop or restart the Application is using the Start9 User Interface

**Emergency Manual Recovery**
---------------------------

*If the web interface is not working, you can use these manual commands as a last resort.*

### Manual Restart Commands

If you hit Quit by mistake, you will be shown a terminal screen. To return to the wallet simply paste this command and press enter:
```
/opt/ashigaru-terminal/bin/Ashigaru-terminal
```

### Manual Network Switching

If you need to switch networks manually (when StartOS configuration is not working):

*   **For Testnet4**: If you restart in testnet4 and see a terminal interface, use this command:
```
/opt/ashigaru-terminal/bin/Ashigaru-terminal -n testnet4
```
*   **For Mainnet**: To return to mainnet, use this command:
```
/opt/ashigaru-terminal/bin/Ashigaru-terminal
```

### Manual Server Configuration

If automatic configuration is not working, you can configure servers manually within Ashigaru Terminal:

#### Connecting to a Electrum Server over Tor
*   Enter the server's `.onion` address
*   Enter the correct port
*   Enable the proxy with the address `embassy` and port `9050`
*   Connect

#### Connecting to a local Electrum Server
*   Enter the server's local address (e.g., "fulcrum.embassy" for Fulcrum)
*   Enter the correct port
*   Connect

*Note: These manual methods should only be used when the StartOS configuration is not working properly.*

**Learning Resources**
----------------------

### Learning Materials

For learning resources on the Ashigaru stack, you may find the following helpful:

*   [Ashigaru Terminal Overview](https://ashigaru.rs/docs/ashigaru-terminal-overview)
*   [Whirlpool and Ashigaru](https://k3tan.com/ashigaru-whirlpool)
*   [Ashigaru Terminal Tutorial (Video)](https://www.youtube.com/watch?v=aykJ4eP-Veo)
*   [Using Ashigaru with Electrum (Video)](https://www.youtube.com/watch?v=ULZoPMCYPfk)

**Disclaimer**
--------------

The developers do not assume any responsibility for your actions. Do your own research and make informed decisions.

### Official Website

The only official website is `ashigaru.rs`. Any other sites are fraudulent, as are individuals claiming to represent Ashigaru on social media – Ashigaru has no social media presence. Always act responsibly and in compliance with the law.

## Good Luck!

Enjoy your Ashigaru Terminal experience and happy experimenting with enhanced privacy features!
