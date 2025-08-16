import { sdk } from './sdk'
import { port } from './utils'

export const main = sdk.setupMain(async ({ effects, started }) => {
  /**
   * ======================== Setup ========================
   */
  console.info('Starting Fulcrum!')

  const depResult = await sdk.checkDependencies(effects)
  depResult.throwIfNotSatisfied()

  const fulcrumContainer = await sdk.SubContainer.of(
    effects,
    { imageId: 'fulcrum' },
    sdk.Mounts.of()
      .mountVolume({
        volumeId: 'main',
        subpath: null,
        mountpoint: '/data',
        readonly: false,
      })
      .mountAssets({
        subpath: null,
        mountpoint: '/assets',
      }),
    'fulcrum',
  )

  /**
   * =================== Container Daemons =====================
   */
  return sdk.Daemons.of(effects, started)
    .addDaemon('fulcrum', {
      subcontainer: fulcrumContainer,
      exec: { command: ['docker_entrypoint.sh', 'Fulcrum'] },
      ready: {
        display: 'Fulcrum Electrum Server',
        fn: () =>
          sdk.healthCheck.checkPortListening(effects, port, {
            successMessage:
              'Fulcrum electrum server is ready and accepting connections',
            errorMessage: 'Fulcrum electrum server is unreachable',
          }),
      },
      requires: [],
    })
    .addHealthCheck('sync', {
      ready: {
        display: 'Sync Progress',
        fn: async () => {
          const res = await fulcrumContainer.exec(
            ['sh', '/usr/local/bin/check-synced.sh'],
            {
              env: {
                RUST_LOG: 'debug',
              },
            },
          )

          if (res.exitCode === 61) {
            return { message: res.stdout.toString(), result: 'loading' }
          }
          if (res.exitCode === 0) {
            return { message: res.stdout.toString(), result: 'success' }
          }
          return { message: res.stderr.toString(), result: 'failure' }
        },
      },
      requires: ['fulcrum'],
    })
})
