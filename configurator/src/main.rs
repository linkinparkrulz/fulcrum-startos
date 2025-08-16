use std::fs::File;
use std::io::Write;

use serde::{Deserialize};

#[derive(Deserialize)]
#[serde(rename_all = "kebab-case")]
struct Config {
    bitcoind: BitcoinCoreConfig,
    advanced: AdvancedConfig,
}

#[derive(Deserialize)]
#[serde(rename_all = "kebab-case")]
struct AdvancedConfig {
    bitcoind_timeout: Option<u16>,
    bitcoind_clients: Option<u16>,
    worker_threads: Option<u16>,
    db_mem: Option<u16>,
    db_max_open_files: Option<u16>,
    utxo_cache: Option<u16>,
}

// Simplified config structure for StartOS 0.4.0
#[derive(serde::Deserialize)]
struct BitcoinCoreConfig {
    username: String,
    password: String,
}

fn main() -> Result<(), anyhow::Error> {
    let config: Config = serde_yaml::from_reader(File::open("/data/start9/config.yaml")?)?;

    {
        let mut outfile = File::create("/data/fulcrum.conf")?;

        let (bitcoin_rpc_user, bitcoin_rpc_pass, bitcoin_rpc_host, bitcoin_rpc_port) =
            match config.bitcoind {
                BitcoinCoreConfig { username, password } => {
                    // Default to bitcoind-testnet for StartOS 0.4.0
                    let hostname = format!("{}", "bitcoind-testnet.embassy");
                    (username, password, hostname.clone(), 48332)
                }
            };

        let mut bitcoind_timeout: String = "".to_string();
        if config.advanced.bitcoind_timeout.is_some() {
            bitcoind_timeout = format!(
                "bitcoind_timeout = {}",
                config.advanced.bitcoind_timeout.unwrap()
            );
        }

        let mut bitcoind_clients: String = "".to_string();
        if config.advanced.bitcoind_clients.is_some() {
            bitcoind_clients = format!(
                "bitcoind_clients = {}",
                config.advanced.bitcoind_clients.unwrap()
            );
        }

        let mut worker_threads: String = "".to_string();
        if config.advanced.worker_threads.is_some() {
            worker_threads = format!(
                "worker_threads = {}",
                config.advanced.worker_threads.unwrap()
            );
        }

        let mut db_mem: String = "".to_string();
        if config.advanced.db_mem.is_some() {
            db_mem = format!(
                "db_mem = {}",
                config.advanced.db_mem.unwrap()
            );
        }

        let mut db_max_open_files: String = "".to_string();
        if config.advanced.db_max_open_files.is_some() {
            db_max_open_files = format!(
                "db_max_open_files = {}",
                config.advanced.db_max_open_files.unwrap()
            );
        }

        let mut utxo_cache: String = "".to_string();
        if config.advanced.utxo_cache.is_some() {
            utxo_cache = format!(
                "utxo_cache = {}",
                config.advanced.utxo_cache.unwrap()
            );
        }

        write!(
            outfile,
            include_str!("fulcrum.conf.template"),
            bitcoin_rpc_user = bitcoin_rpc_user,
            bitcoin_rpc_pass = bitcoin_rpc_pass,
            bitcoin_rpc_host = bitcoin_rpc_host,
            bitcoin_rpc_port = bitcoin_rpc_port,
            bitcoind_timeout = bitcoind_timeout,
            bitcoind_clients = bitcoind_clients,
            worker_threads = worker_threads,
            db_mem = db_mem,
            db_max_open_files = db_max_open_files,
            utxo_cache = utxo_cache,
        )?;
    }

    Ok(())
}
