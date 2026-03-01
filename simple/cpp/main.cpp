#include <algorithm>
#include <cmath>
#include <cstdint>
#include <iostream>
#include <numeric>
#include <string>
#include <vector>

struct Stats {
    double mean;
    double median;
    double stddev;
    double min;
    double max;
    size_t count;
};

Stats compute_stats(std::vector<double>& values) {
    Stats s{};
    s.count = values.size();
    if (s.count == 0) {
        return s;
    }

    std::sort(values.begin(), values.end());

    s.min = values.front();
    s.max = values.back();
    s.mean = std::accumulate(values.begin(), values.end(), 0.0) / static_cast<double>(s.count);

    if (s.count % 2 == 0) {
        s.median = (values[s.count / 2 - 1] + values[s.count / 2]) / 2.0;
    } else {
        s.median = values[s.count / 2];
    }

    double variance = 0.0;
    for (double v : values) {
        double diff = v - s.mean;
        variance += diff * diff;
    }
    variance /= static_cast<double>(s.count);
    s.stddev = std::sqrt(variance);

    return s;
}

std::vector<size_t> build_histogram(const std::vector<double>& values, size_t num_buckets) {
    if (values.empty() || num_buckets == 0) {
        return {};
    }

    double min_val = values.front();
    double max_val = values.back();
    double range = max_val - min_val;

    std::vector<size_t> buckets(num_buckets, 0);
    if (range == 0.0) {
        buckets[0] = values.size();
        return buckets;
    }

    for (double v : values) {
        size_t idx = static_cast<size_t>((v - min_val) / range * static_cast<double>(num_buckets));
        if (idx >= num_buckets) {
            idx = num_buckets - 1;
        }
        buckets[idx]++;
    }
    return buckets;
}

int main() {
    std::vector<double> values;
    std::string line;

    while (std::getline(std::cin, line)) {
        if (line.empty()) {
            continue;
        }
        try {
            values.push_back(std::stod(line));
        } catch (...) {
            std::cerr << "skipping invalid input: " << line << "\n";
        }
    }

    if (values.empty()) {
        std::cerr << "no values provided\n";
        return 1;
    }

    Stats s = compute_stats(values);

    std::cout << "count:  " << s.count << "\n";
    std::cout << "mean:   " << s.mean << "\n";
    std::cout << "median: " << s.median << "\n";
    std::cout << "stddev: " << s.stddev << "\n";
    std::cout << "min:    " << s.min << "\n";
    std::cout << "max:    " << s.max << "\n";

    const size_t num_buckets = 10;
    std::vector<size_t> histogram = build_histogram(values, num_buckets);

    std::cout << "\nhistogram (" << num_buckets << " buckets):\n";
    size_t max_count = *std::max_element(histogram.begin(), histogram.end());
    double bucket_width = (s.max - s.min) / static_cast<double>(num_buckets);

    for (size_t i = 0; i < num_buckets; i++) {
        double lo = s.min + static_cast<double>(i) * bucket_width;
        double hi = lo + bucket_width;
        size_t bar_len = 0;
        if (max_count > 0) {
            bar_len = histogram[i] * 40 / max_count;
        }
        std::string bar(bar_len, '#');
        printf("[%8.2f, %8.2f) %6zu %s\n", lo, hi, histogram[i], bar.c_str());
    }

    return 0;
}
