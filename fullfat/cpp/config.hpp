#pragma once
#include <string>

struct Config {
    std::string field;
    double threshold;
    std::string output_path;
};

Config load_config(const std::string& path);
