mod config;
mod data;

use std::env;

fn main() {
    let args: Vec<String> = env::args().collect();
    let config_path = args.get(1).map(|s| s.as_str()).unwrap_or("config.toml");
    let data_path = args.get(2).map(|s| s.as_str()).unwrap_or("data.json");

    let cfg = config::load_config(config_path);
    let mut values = data::load_and_filter(data_path, &cfg.field, cfg.threshold);

    if values.is_empty() {
        eprintln!("no records matched filter");
        std::process::exit(1);
    }

    let stats = data::compute_stats(&mut values);
    print!("{}", data::format_output(&stats));
}
