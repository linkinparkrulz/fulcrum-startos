import { setupManifest } from '@start9labs/start-sdk'

export const manifest = setupManifest({
  id: 'fulcrum',
  title: 'Fulcrum',
  license: 'mit',
  wrapperRepo: 'https://github.com/linkinparkrulz/fulcrum-startos',
  upstreamRepo: 'https://github.com/cculianu/Fulcrum',
  supportSite: 'https://github.com/cculianu/Fulcrum/issues',
  marketingSite: 'https://github.com/cculianu/Fulcrum',
  docsUrl: 'https://github.com/cculianu/Fulcrum',
  donationUrl: null,
  description: {
    short: 'A fast & nimble SPV Server for BTC, BCH and LTC',
    long: 'A fast & nimble SPV server for Bitcoin, Bitcoin Cash and Litecoin. Provides a fast, efficient Electrum protocol interface that allows lightweight wallets to query blockchain data and broadcast transactions without downloading the full blockchain.',
  },
  volumes: ['main'],
  images: {
    fulcrum: {
      source: {
        dockerBuild: {
          dockerfile: 'Dockerfile',
          workdir: '.',
        },
      },
    },
  },
  hardwareRequirements: {},
  alerts: {
    install:
      'WARNING: Fulcrum requires significant system resources: 1GB+ RAM during sync and 160GB+ for indexes. When combined with a Bitcoin node (~800GB), total storage requirements exceed 1TB. A 2TB drive is strongly recommended. Insufficient resources may cause system instability or failure.',
    update: null,
    uninstall: null,
    restore: null,
    start:
      'WARNING: Fulcrum requires significant system resources: 1GB+ RAM during sync and 160GB+ for indexes. When combined with a Bitcoin node (~800GB), total storage requirements exceed 1TB. A 2TB drive is strongly recommended. Insufficient resources may cause system instability or failure.',
    stop: null,
  },
  dependencies: {},
})
