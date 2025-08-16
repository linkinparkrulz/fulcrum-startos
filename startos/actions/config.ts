import { configFile } from '../fileModels/config'
import { sdk } from '../sdk'
import { configDefaults } from '../utils'

const { InputSpec, Value } = sdk

export const inputSpec = InputSpec.of({
  advanced: Value.object(
    {
      name: 'Advanced Settings',
      description: 'Advanced configuration options for Fulcrum',
    },
    InputSpec.of({
      'bitcoind-timeout': Value.number({
        name: 'Bitcoin RPC Timeout',
        description: 'Timeout for Bitcoin RPC requests in seconds',
        required: false,
        default: 600,
        min: 1,
        integer: true,
      }),
      'bitcoind-clients': Value.number({
        name: 'Bitcoin RPC Clients',
        description: 'Number of Bitcoin RPC client connections',
        required: false,
        default: 1,
        min: 1,
        integer: true,
      }),
      'worker-threads': Value.number({
        name: 'Worker Threads',
        description: 'Number of worker threads for processing',
        required: false,
        default: 1,
        min: 1,
        integer: true,
      }),
      'db-mem': Value.number({
        name: 'Database Memory (MB)',
        description: 'Amount of memory allocated to the database in MB',
        required: false,
        default: 1024,
        min: 1,
        integer: true,
      }),
      'db-max-open-files': Value.number({
        name: 'Database Max Open Files',
        description: 'Maximum number of open database files',
        required: false,
        default: 200,
        min: 1,
        integer: true,
      }),
      'utxo-cache': Value.number({
        name: 'UTXO Cache Size (MB)',
        description: 'Size of UTXO cache in MB',
        required: false,
        default: 1024,
        min: 1,
        integer: true,
      }),
    }),
  ),
})

export const config = sdk.Action.withInput(
  // id
  'config',

  // metadata
  async ({ effects }) => ({
    name: 'Configure Advanced Settings',
    description: 'Configure advanced settings for your Fulcrum Electrum server',
    warning:
      'Bitcoin node credentials are automatically configured via service dependencies.',
    allowedStatuses: 'any',
    group: null,
    visibility: 'enabled',
  }),

  // form input specification
  inputSpec,

  // optionally pre-fill the input form
  async ({ effects }) => {
    const values = await configFile.read().const(effects)
    const defaults = configDefaults.advanced

    return {
      advanced: {
        'bitcoind-timeout': (values?.advanced?.['bitcoind-timeout'] ??
          defaults['bitcoind-timeout']) as number,
        'bitcoind-clients': (values?.advanced?.['bitcoind-clients'] ??
          defaults['bitcoind-clients']) as number,
        'worker-threads': (values?.advanced?.['worker-threads'] ??
          defaults['worker-threads']) as number,
        'db-mem': (values?.advanced?.['db-mem'] ??
          defaults['db-mem']) as number,
        'db-max-open-files': (values?.advanced?.['db-max-open-files'] ??
          defaults['db-max-open-files']) as number,
        'utxo-cache': (values?.advanced?.['utxo-cache'] ??
          defaults['utxo-cache']) as number,
      },
    }
  },

  // the execution function
  async ({ effects, input }) => {
    await configFile.merge(effects, input)
  },
)
