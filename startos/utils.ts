/**
 * Utility constants and configuration defaults for Fulcrum StartOS package
 */

// Network configuration
export const port = 50001

// Default configuration values for advanced settings
export const configDefaults = {
  advanced: {
    'bitcoind-timeout': 600,        // Seconds to wait for Bitcoin RPC responses
    'bitcoind-clients': 1,          // Number of concurrent Bitcoin RPC connections
    'worker-threads': 1,            // Number of worker threads for processing
    'db-mem': 1024,                // Database memory allocation in MB
    'db-max-open-files': 200,      // Maximum number of open database files
    'utxo-cache': 1024,            // UTXO cache size in MB
  },
}
