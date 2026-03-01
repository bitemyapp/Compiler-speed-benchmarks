use serde::Deserialize;
use std::fs;

#[derive(Deserialize)]
pub struct Config {
    pub field: String,
    pub threshold: f64,
    pub output_path: String,
}

pub fn load_config(path: &str) -> Config {
    let content = fs::read_to_string(path)
        .unwrap_or_else(|e| panic!("cannot open config file '{}': {}", path, e));
    toml::from_str(&content)
        .unwrap_or_else(|e| panic!("cannot parse config file '{}': {}", path, e))
}
