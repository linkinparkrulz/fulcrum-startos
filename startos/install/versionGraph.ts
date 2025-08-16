import { VersionGraph } from '@start9labs/start-sdk'
import { current, other } from './versions'
import { configFile } from '../fileModels/config'
import { configDefaults } from '../utils'

export const versionGraph = VersionGraph.of({
  current,
  other,
  preInstall: async (effects) => {
    await configFile.write(effects, { advanced: configDefaults.advanced })
  },
})
