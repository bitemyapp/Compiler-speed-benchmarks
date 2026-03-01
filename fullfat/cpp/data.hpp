#pragma once
#include <string>
#include <vector>

struct Stats {
    size_t count;
    double mean;
    double median;
    double stddev;
    double min;
    double max;
};

std::vector<double> load_and_filter(const std::string& data_path,
                                     const std::string& field,
                                     double threshold);

Stats compute_stats(std::vector<double>& values);

void write_output(const Stats& stats, const std::string& output_path);
void write_output_stdout(const Stats& stats);
