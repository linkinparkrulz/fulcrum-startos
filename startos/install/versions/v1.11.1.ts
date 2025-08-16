import { VersionInfo, IMPOSSIBLE } from '@start9labs/start-sdk'
import { configFile } from '../../fileModels/config'
import { configDefaults } from '../../utils'

export const v1_11_1 = VersionInfo.of({
  version: '1.11.1:1-alpha.1',
  releaseNotes: 'Updated for StartOS v0.4.0',
  migrations: {
    up: async ({ effects }) => {
      // Migration to ensure advanced config section exists
      // Don't override bitcoind credentials - let pointers work
      await configFile.merge(effects, {
        advanced: configDefaults.advanced,
      })
    },
    down: IMPOSSIBLE,
  },
})
