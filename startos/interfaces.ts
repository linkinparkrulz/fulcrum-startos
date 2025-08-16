import { sdk } from './sdk'
import { port } from './utils'

export const setInterfaces = sdk.setupInterfaces(async ({ effects }) => {
  const multihost = sdk.MultiHost.of(effects, 'multihost')

  // Configure the main Electrum interface with SSL support
  const mainMultiOrigin = await multihost.bindPort(port, {
    protocol: null,
    addSsl: {
      preferredExternalPort: 50002,
      alpn: null
    },
    preferredExternalPort: port,
    secure: null,
  })

  // Create the Electrum interface definition
  const main = sdk.createInterface(effects, {
    name: 'Electrum Interface',
    id: 'electrum',
    description: 'Provides a fast, efficient Electrum protocol interface that allows lightweight wallets to query blockchain data and broadcast transactions without downloading the full blockchain.',
    type: 'api',
    masked: false,
    schemeOverride: null,
    username: null,
    path: '',
    query: {},
  })

  const mainReceipt = await mainMultiOrigin.export([main])

  return [mainReceipt]
})
