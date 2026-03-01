#include "config.hpp"
#include "data.hpp"
#include <iostream>

int main(int argc, char* argv[]) {
    std::string config_path = "config.toml";
    std::string data_path = "data.json";

    if (argc >= 2) {
        config_path = argv[1];
    }
    if (argc >= 3) {
        data_path = argv[2];
    }

    try {
        Config cfg = load_config(config_path);
        auto values = load_and_filter(data_path, cfg.field, cfg.threshold);

        if (values.empty()) {
            std::cerr << "no records matched filter\n";
            return 1;
        }

        Stats stats = compute_stats(values);
        write_output_stdout(stats);
    } catch (const std::exception& e) {
        std::cerr << "error: " << e.what() << "\n";
        return 1;
    }

    return 0;
}
