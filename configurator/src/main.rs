use std::fs::File;
use std::io::Write;

use http::Uri;
use serde::{
    de::{Deserializer, Error as DeserializeError, Unexpected},
    Deserialize,
};

fn deserialize_parse<'de, D: Deserializer<'de>, T: std::str::FromStr>(
    deserializer: D,
) -> Result<T, D::Error> {
    let s: String = Deserialize::deserialize(deserializer)?;
    s.parse()
        .map_err(|_| DeserializeError::invalid_value(Unexpected::Str(&s), &"a valid URI"))
}

fn parse_quick_connect_url(url: Uri) -> Result<(String, String, String, u16), anyhow::Error> {
    let auth = url
        .authority()
        .ok_or_else(|| anyhow::anyhow!("invalid Quick Connect URL"))?;
    let mut auth_split = auth.as_str().split(|c| c == ':' || c == '@');
    let user = auth_split
        .next()
        .ok_or_else(|| anyhow::anyhow!("missing user"))?;
    let pass = auth_split
        .next()
        .ok_or_else(|| anyhow::anyhow!("missing pass"))?;
    let host = url.host().unwrap();
    let port = url.port_u16().unwrap_or(8332);
    Ok((user.to_owned(), pass.to_owned(), host.to_owned(), port))
}

#[derive(Deserialize)]
#[serde(rename_all = "kebab-case")]
struct Config {
    bitcoind: BitcoinCoreConfig,
    banner: Option<String>,
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

#[derive(serde::Deserialize)]
#[serde(tag = "type")]
enum BitcoinCoreConfig {
    #[serde(rename = "bitcoind")]
    Bitcoind {
        username: String,
        password: String,
    },
    #[serde(rename = "bitcoind-testnet")]
    BitcoindTestnet {
        username: String,
        password: String,
    },
    External {
        #[serde(deserialize_with = "deserialize_parse")]
        host: Uri,
        rpc_user: String,
        rpc_password: String,
        rpc_port: u16,
    },
    #[serde(rename = "quick-connect")]
    QuickConnect {
        #[serde(deserialize_with = "deserialize_parse")]
        quick_connect_url: Uri,
    },
}

#[derive(serde::Serialize)]
pub struct Properties {
    version: u8,
    data: Data,
}

#[derive(serde::Serialize)]
pub struct Data {
    #[serde(rename = "LND Connect URL")]
    lnd_connect: Property<String>,
}

#[derive(serde::Serialize)]
pub struct Property<T> {
    #[serde(rename = "type")]
    value_type: &'static str,
    value: T,
    description: Option<String>,
    copyable: bool,
    qr: bool,
    masked: bool,
}

fn main() -> Result<(), anyhow::Error> {
    let config: Config = serde_yaml::from_reader(File::open("/data/start9/config.yaml")?)?;

    {
        let mut outfile = File::create("/data/fulcrum.conf")?;

        let (bitcoin_rpc_user, bitcoin_rpc_pass, bitcoin_rpc_host, bitcoin_rpc_port) =
            match config.bitcoind {
                BitcoinCoreConfig::Bitcoind { username, password } => {
                    let hostname = format!("{}", "bitcoind.embassy");
                    (username, password, hostname.clone(), 8332)
                }
                BitcoinCoreConfig::BitcoindTestnet { username, password } => {
                    let hostname = format!("{}", "bitcoind-testnet.embassy");
                    (username, password, hostname.clone(), 48332)
                }
                BitcoinCoreConfig::External {
                    host,
                    rpc_user,
                    rpc_password,
                    rpc_port,
                } => (
                    rpc_user,
                    rpc_password,
                    format!("{}", host.host().unwrap()),
                    rpc_port,
                ),
                BitcoinCoreConfig::QuickConnect { quick_connect_url } => {
                    let (bitcoin_rpc_user, bitcoin_rpc_pass, bitcoin_rpc_host, bitcoin_rpc_port) =
                        parse_quick_connect_url(quick_connect_url)?;
                    (
                        bitcoin_rpc_user,
                        bitcoin_rpc_pass,
                        bitcoin_rpc_host.clone(),
                        bitcoin_rpc_port,
                    )
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

    // Create banner file
    {
        let mut banner_file = File::create("/data/banner.txt")?;
        let banner_text = config.banner.unwrap_or_else(|| {
            r#"


█▀▀ █▀█ █▀▀ █▀▀   █▀ ▄▀█ █▀▄▀█ █▀█ █░█ █▀█ ▄▀█ █
█▀░ █▀▄ ██▄ ██▄   ▄█ █▀█ █░▀░█ █▄█ █▄█ █▀▄ █▀█ █

Welcome to your Fulcrum Server!
Connected to $SERVER_VERSION
For information and updates: https://freesamourai.com"#.to_string()
        });
        banner_file.write_all(banner_text.as_bytes())?;
    }

    Ok(())
}
