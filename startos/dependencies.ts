import { sdk } from './sdk'

export const setDependencies = sdk.setupDependencies(async ({ effects }) => {
  // Note: Removed archival node requirement to allow working with pruned nodes

  return {
    'bitcoind-testnet': {
      id: 'bitcoind-testnet',
      kind: 'running',
      versionRange: '>=28.1.0:0',
      healthChecks: [],
    },
  }
})
