import { compat, types as T } from '../deps.ts'

export const getConfig: T.ExpectedExports.getConfig = compat.getConfig({
  'electrum-tor-address': {
    name: 'Electrum Tor Address',
    description: 'The Tor address for the electrum interface.',
    type: 'pointer',
    subtype: 'package',
    'package-id': 'fulcrum',
    target: 'tor-address',
    interface: 'electrum',
  },
  bitcoind: {
    type: 'union',
    name: 'Bitcoin Node',
    description: 'The Bitcoin node type you would like to use for Dojo',
    tag: {
      id: 'type',
      name: 'Select Bitcoin Node',
      'variant-names': {
        bitcoind: 'Bitcoin Core',
        'bitcoind-testnet': 'Bitcoin Core (testnet4)',
      },
      description: 'The Bitcoin node type you would like to use for Fulcrum',
    },
    default: 'bitcoind',
    variants: {
      bitcoind: {
        username: {
          type: 'pointer',
          name: 'RPC Username',
          description: "The username for Bitcoin Core's RPC interface",
          subtype: 'package',
          'package-id': 'bitcoind',
          target: 'config',
          multi: false,
          selector: '$.rpc.username',
        },
        password: {
          type: 'pointer',
          name: 'RPC Password',
          description: "The password for Bitcoin Core's RPC interface",
          subtype: 'package',
          'package-id': 'bitcoind',
          target: 'config',
          multi: false,
          selector: '$.rpc.password',
        },
      },
      'bitcoind-testnet': {
        username: {
          type: 'pointer',
          name: 'RPC Username',
          description: 'The username for Bitcoin Core Testnet RPC interface',
          subtype: 'package',
          'package-id': 'bitcoind-testnet',
          target: 'config',
          multi: false,
          selector: '$.rpc.username',
        },
        password: {
          type: 'pointer',
          name: 'RPC Password',
          description: 'The password for Bitcoin Core Testnet RPC interface',
          subtype: 'package',
          'package-id': 'bitcoind-testnet',
          target: 'config',
          multi: false,
          selector: '$.rpc.password',
        },
      },
    },
  },
  banner: {
    type: 'string',
    name: 'Server Banner',
    description:
      'Custom banner text displayed to connecting clients. Supports variable substitutions like $SERVER_VERSION and $DONATION_ADDRESS.',
    nullable: true,
    default: `


█▀▀ █▀█ █▀▀ █▀▀   █▀ ▄▀█ █▀▄▀█ █▀█ █░█ █▀█ ▄▀█ █
█▀░ █▀▄ ██▄ ██▄   ▄█ █▀█ █░▀░█ █▄█ █▄█ █▀▄ █▀█ █

Welcome to your Fulcrum Server!
Connected to $SERVER_VERSION
For information and updates: https://freesamourai.com`,
    textarea: true,
  },
  advanced: {
    type: 'object',
    name: 'Advanced',
    description: 'Advanced settings for Fulcrum',
    spec: {
      'bitcoind-timeout': {
        type: 'number',
        name: 'Bitcoin RPC Timeout',
        description:
          'https://github.com/cculianu/Fulcrum/blob/v2.0.0/doc/fulcrum-example-config.conf#L626',
        nullable: false,
        range: '[30,*)',
        integral: true,
        units: 'seconds',
        default: 30,
      },
      'bitcoind-clients': {
        type: 'number',
        name: 'Bitcoin RPC Clients',
        description:
          'https://github.com/cculianu/Fulcrum/blob/v2.0.0/doc/fulcrum-example-config.conf#L566',
        nullable: false,
        range: '[1,*)',
        integral: true,
        units: 'clients',
        default: 3,
      },
      'worker-threads': {
        type: 'number',
        name: 'Worker Threads (leave empty for automatic)',
        description:
          'https://github.com/cculianu/Fulcrum/blob/v2.0.0/doc/fulcrum-example-config.conf#L985',
        nullable: true,
        range: '[0,*)',
        integral: true,
        units: 'threads',
        default: 0,
      },
      'db-mem': {
        type: 'number',
        name: 'Database Memory Size',
        description:
          'https://github.com/cculianu/Fulcrum/blob/v2.0.0/doc/fulcrum-example-config.conf#L695',
        nullable: false,
        range: '[50,*)',
        integral: true,
        units: 'MB',
        default: 2048,
      },
      'db-max-open-files': {
        type: 'number',
        name: 'Database Maximum Open Files',
        description:
          'https://github.com/cculianu/Fulcrum/blob/v2.0.0/doc/fulcrum-example-config.conf#L676',
        nullable: false,
        range: '[20,*)',
        integral: true,
        units: 'files',
        default: 1000,
      },
    },
  },
})
