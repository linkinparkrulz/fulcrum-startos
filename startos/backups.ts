/**
 * Backup configuration for Fulcrum StartOS package
 * 
 * Currently using no-op backup strategy as Fulcrum data can be regenerated
 * from the Bitcoin node and configuration is handled separately.
 */
import { sdk } from './sdk'

export const { createBackup, restoreInit } = sdk.setupBackups(
  async ({ effects }) =>
    sdk.Backups.ofVolumes('main').setOptions({
      exclude: ['/data/db'], // Exclude database as it can be regenerated
    }),
)
