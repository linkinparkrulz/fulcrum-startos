import { matches, FileHelper } from '@start9labs/start-sdk'
import { configDefaults } from '../utils'
const { object, string, natural, literal } = matches

const bitcoindConfig = object({
  username: string,
  password: string,
})

const advancedConfig = object({
  'bitcoind-timeout': natural.nullable(),
  'bitcoind-clients': natural.nullable(),
  'worker-threads': natural.nullable(),
  'db-mem': natural.nullable(),
  'db-max-open-files': natural.nullable(),
  'utxo-cache': natural.nullable(),
})

const shape = object({
  bitcoind: bitcoindConfig.optional(),
  advanced: advancedConfig.onMismatch(configDefaults.advanced),
})

export const configFile = FileHelper.yaml(
  {
    volumeId: 'main',
    subpath: 'start9/config.yaml',
  },
  shape.onMismatch({ advanced: configDefaults.advanced }),
)
