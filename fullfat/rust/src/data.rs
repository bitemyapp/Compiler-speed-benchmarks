use serde_json::Value;
use std::fs;

pub struct Stats {
    pub count: usize,
    pub mean: f64,
    pub median: f64,
    pub stddev: f64,
    pub min: f64,
    pub max: f64,
}

pub fn load_and_filter(data_path: &str, field: &str, threshold: f64) -> Vec<f64> {
    let content = fs::read_to_string(data_path)
        .unwrap_or_else(|e| panic!("cannot open data file '{}': {}", data_path, e));
    let data: Value = serde_json::from_str(&content)
        .unwrap_or_else(|e| panic!("cannot parse data file '{}': {}", data_path, e));

    let records = data.as_array()
        .expect("data file must contain a JSON array");

    let mut values = Vec::new();
    for record in records {
        if let Some(obj) = record.as_object() {
            if let Some(val) = obj.get(field) {
                if let Some(v) = val.as_f64() {
                    if v > threshold {
                        values.push(v);
                    }
                }
            }
        }
    }
    values
}

pub fn compute_stats(values: &mut Vec<f64>) -> Stats {
    let count = values.len();
    if count == 0 {
        return Stats {
            count: 0,
            mean: 0.0,
            median: 0.0,
            stddev: 0.0,
            min: 0.0,
            max: 0.0,
        };
    }

    values.sort_by(|a, b| a.partial_cmp(b).unwrap());

    let min = values[0];
    let max = values[count - 1];
    let sum: f64 = values.iter().sum();
    let mean = sum / count as f64;

    let median = if count % 2 == 0 {
        (values[count / 2 - 1] + values[count / 2]) / 2.0
    } else {
        values[count / 2]
    };

    let variance: f64 = values.iter()
        .map(|v| {
            let diff = v - mean;
            diff * diff
        })
        .sum::<f64>() / count as f64;
    let stddev = variance.sqrt();

    Stats { count, mean, median, stddev, min, max }
}

fn round_to(v: f64, decimals: i32) -> f64 {
    let factor = 10f64.powi(decimals);
    (v * factor).round() / factor
}

pub fn format_output(stats: &Stats) -> String {
    let out = serde_json::json!({
        "count": stats.count,
        "mean": round_to(stats.mean, 6),
        "median": round_to(stats.median, 6),
        "stddev": round_to(stats.stddev, 6),
        "min": round_to(stats.min, 6),
        "max": round_to(stats.max, 6),
    });
    serde_json::to_string_pretty(&out).unwrap() + "\n"
}
