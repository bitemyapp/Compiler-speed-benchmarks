#include "data.hpp"
#include "vendor/nlohmann/json.hpp"
#include <algorithm>
#include <cmath>
#include <fstream>
#include <iostream>
#include <numeric>
#include <stdexcept>

using json = nlohmann::json;

std::vector<double> load_and_filter(const std::string& data_path,
                                     const std::string& field,
                                     double threshold) {
    std::ifstream ifs(data_path);
    if (!ifs.is_open()) {
        throw std::runtime_error("cannot open data file: " + data_path);
    }

    json data = json::parse(ifs);
    if (!data.is_array()) {
        throw std::runtime_error("data file must contain a JSON array");
    }

    std::vector<double> values;
    for (const auto& record : data) {
        if (!record.is_object() || !record.contains(field)) {
            continue;
        }
        const auto& val = record[field];
        if (!val.is_number()) {
            continue;
        }
        double v = val.get<double>();
        if (v > threshold) {
            values.push_back(v);
        }
    }
    return values;
}

Stats compute_stats(std::vector<double>& values) {
    Stats s{};
    s.count = values.size();
    if (s.count == 0) {
        return s;
    }

    std::sort(values.begin(), values.end());

    s.min = values.front();
    s.max = values.back();
    s.mean = std::accumulate(values.begin(), values.end(), 0.0) /
             static_cast<double>(s.count);

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

static json round_to(double v, int decimals) {
    double factor = std::pow(10.0, decimals);
    return std::round(v * factor) / factor;
}

void write_output(const Stats& stats, const std::string& output_path) {
    json out;
    out["count"] = stats.count;
    out["mean"] = round_to(stats.mean, 6);
    out["median"] = round_to(stats.median, 6);
    out["stddev"] = round_to(stats.stddev, 6);
    out["min"] = round_to(stats.min, 6);
    out["max"] = round_to(stats.max, 6);

    std::ofstream ofs(output_path);
    if (!ofs.is_open()) {
        throw std::runtime_error("cannot open output file: " + output_path);
    }
    ofs << out.dump(2) << "\n";
}

void write_output_stdout(const Stats& stats) {
    json out;
    out["count"] = stats.count;
    out["mean"] = round_to(stats.mean, 6);
    out["median"] = round_to(stats.median, 6);
    out["stddev"] = round_to(stats.stddev, 6);
    out["min"] = round_to(stats.min, 6);
    out["max"] = round_to(stats.max, 6);

    std::cout << out.dump(2) << "\n";
}
