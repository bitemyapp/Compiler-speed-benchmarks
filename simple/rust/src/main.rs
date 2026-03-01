use std::io::{self, BufRead};

struct Stats {
    mean: f64,
    median: f64,
    stddev: f64,
    min: f64,
    max: f64,
    count: usize,
}

fn compute_stats(values: &mut Vec<f64>) -> Stats {
    let count = values.len();
    if count == 0 {
        return Stats {
            mean: 0.0,
            median: 0.0,
            stddev: 0.0,
            min: 0.0,
            max: 0.0,
            count: 0,
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

    let variance: f64 = values.iter().map(|v| {
        let diff = v - mean;
        diff * diff
    }).sum::<f64>() / count as f64;
    let stddev = variance.sqrt();

    Stats { mean, median, stddev, min, max, count }
}

fn build_histogram(values: &[f64], num_buckets: usize) -> Vec<usize> {
    if values.is_empty() || num_buckets == 0 {
        return vec![];
    }

    let min_val = values[0];
    let max_val = values[values.len() - 1];
    let range = max_val - min_val;

    let mut buckets = vec![0usize; num_buckets];
    if range == 0.0 {
        buckets[0] = values.len();
        return buckets;
    }

    for &v in values {
        let mut idx = ((v - min_val) / range * num_buckets as f64) as usize;
        if idx >= num_buckets {
            idx = num_buckets - 1;
        }
        buckets[idx] += 1;
    }
    buckets
}

fn main() {
    let stdin = io::stdin();
    let mut values: Vec<f64> = Vec::new();

    for line in stdin.lock().lines() {
        let line = match line {
            Ok(l) => l,
            Err(_) => continue,
        };
        if line.is_empty() {
            continue;
        }
        match line.trim().parse::<f64>() {
            Ok(v) => values.push(v),
            Err(_) => eprintln!("skipping invalid input: {}", line),
        }
    }

    if values.is_empty() {
        eprintln!("no values provided");
        std::process::exit(1);
    }

    let s = compute_stats(&mut values);

    println!("count:  {}", s.count);
    println!("mean:   {}", s.mean);
    println!("median: {}", s.median);
    println!("stddev: {}", s.stddev);
    println!("min:    {}", s.min);
    println!("max:    {}", s.max);

    let num_buckets = 10;
    let histogram = build_histogram(&values, num_buckets);

    println!("\nhistogram ({} buckets):", num_buckets);
    let max_count = *histogram.iter().max().unwrap_or(&0);
    let bucket_width = (s.max - s.min) / num_buckets as f64;

    for i in 0..num_buckets {
        let lo = s.min + i as f64 * bucket_width;
        let hi = lo + bucket_width;
        let bar_len = if max_count > 0 {
            histogram[i] * 40 / max_count
        } else {
            0
        };
        let bar: String = std::iter::repeat('#').take(bar_len).collect();
        println!("[{:8.2}, {:8.2}) {:6} {}", lo, hi, histogram[i], bar);
    }
}
