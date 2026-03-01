#include "config.hpp"
#include "vendor/toml.hpp"
#include <stdexcept>

Config load_config(const std::string& path) {
    auto tbl = toml::parse_file(path);

    auto field = tbl["field"].value<std::string>();
    if (!field) {
        throw std::runtime_error("config: missing 'field'");
    }

    auto threshold = tbl["threshold"].value<double>();
    if (!threshold) {
        throw std::runtime_error("config: missing 'threshold'");
    }

    auto output_path = tbl["output_path"].value<std::string>();
    if (!output_path) {
        throw std::runtime_error("config: missing 'output_path'");
    }

    return Config{*field, *threshold, *output_path};
}
