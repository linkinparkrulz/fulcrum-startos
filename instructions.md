# Fulcrum

Is a fast and efficient Electrum server that connects to your node, allowing you to use your favorite wallets without relying on public servers.

## Configuration

1. Choose your preferred Bitcoin node to serve as the backend. Fulcrum is compatible with both Bitcoin Core and Bitcoin Knots for the mainchain. Additionally, a Bitcoin Core (testnet4) option is available for testing purposes.

2. You can customize the text banner that is displayed to clients when they connect to your Fulcrum server. This banner supports variable substitutions, such as `$SERVER_VERSION` and `$DONATION_ADDRESS`, allowing for dynamic information to be presented.

3. There is an "Advanced" section for configuration. The default settings are recommended for most users and have been optimized for typical use cases. Adjust these only if you have specific performance tuning requirements.

## Usage

After configuring, simply "Start" the service. This will begin syncing your indexer. This may take quite some time, up to 1-2 days, depending on your hardware.

> **_NOTE:_** If you are migrating from Fulcrum 1.11.1 to Fulcrum 2.0.0 be sure to STOP Fulcrum before you update. The database needs an update and that check is executed after installation during configuration and pressing START. If you do not STOP Fulcrum 1.11.1, after installation the new 2.0.0 instance will attempt to start up prematurely, which creates an update failure.
