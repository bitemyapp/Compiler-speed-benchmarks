SHELL := /bin/bash

CXX := clang++
CXXFLAGS := -O2 -std=c++17 --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/13
CARGO := cargo
CARGOFLAGS := --release

CPP_SRC := simple/cpp/main.cpp
CPP_BIN := simple/cpp/main

RUST_DIR := simple/rust
RUST_BIN := $(RUST_DIR)/target/release/simple-bench

# Generate test input deterministically with awk (no external deps)
TEST_INPUT := simple/test_input.txt
NUM_VALUES := 100000

.PHONY: all clean bench bench-cpp bench-rust generate-input verify

all: bench

generate-input: $(TEST_INPUT)

$(TEST_INPUT):
	@echo "Generating $(NUM_VALUES) test values..."
	@awk 'BEGIN { srand(42); for (i = 0; i < $(NUM_VALUES); i++) printf "%.6f\n", (rand() * 2000.0) - 1000.0 }' > $(TEST_INPUT)

bench: generate-input bench-cpp bench-rust
	@echo ""
	@echo "===================================="
	@echo " Benchmark complete"
	@echo "===================================="

bench-cpp: generate-input
	@echo ""
	@echo "===================================="
	@echo " C++ (clang++) — full rebuild"
	@echo "===================================="
	@rm -f $(CPP_BIN)
	@TIMEFORMAT='real %Rs  user %Us  sys %Ss'; \
	time $(CXX) $(CXXFLAGS) -o $(CPP_BIN) $(CPP_SRC) 2>&1
	@echo "--- verifying binary runs ---"
	@$(CPP_BIN) < $(TEST_INPUT) > /dev/null

bench-rust: generate-input
	@echo ""
	@echo "===================================="
	@echo " Rust (cargo/rustc) — full rebuild"
	@echo "===================================="
	@cd $(RUST_DIR) && $(CARGO) clean 2>/dev/null; true
	@TIMEFORMAT='real %Rs  user %Us  sys %Ss'; \
	cd $(RUST_DIR) && time $(CARGO) build $(CARGOFLAGS) 2>&1
	@echo "--- verifying binary runs ---"
	@$(RUST_BIN) < $(TEST_INPUT) > /dev/null

verify: generate-input $(CPP_BIN) $(RUST_BIN)
	@echo "--- C++ output ---"
	@$(CPP_BIN) < $(TEST_INPUT)
	@echo ""
	@echo "--- Rust output ---"
	@$(RUST_BIN) < $(TEST_INPUT)

$(CPP_BIN): $(CPP_SRC)
	$(CXX) $(CXXFLAGS) -o $(CPP_BIN) $(CPP_SRC)

$(RUST_BIN): $(RUST_DIR)/src/main.rs $(RUST_DIR)/Cargo.toml
	cd $(RUST_DIR) && $(CARGO) build $(CARGOFLAGS)

clean:
	rm -f $(CPP_BIN)
	rm -f $(TEST_INPUT)
	cd $(RUST_DIR) && $(CARGO) clean 2>/dev/null; true
