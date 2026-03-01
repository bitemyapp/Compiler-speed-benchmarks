SHELL := /bin/bash

CXX := clang++
CXXFLAGS := -O3 -std=c++17 --gcc-install-dir=/usr/lib/gcc/x86_64-linux-gnu/13
CARGO := cargo
CARGOFLAGS := --release

# Simple benchmark
CPP_SRC := simple/cpp/main.cpp
CPP_BIN := simple/cpp/main

RUST_DIR := simple/rust
RUST_BIN := $(RUST_DIR)/target/release/simple-bench

TEST_INPUT := simple/test_input.txt
NUM_VALUES := 100000

# Fullfat benchmark
FF_CPP_DIR := fullfat/cpp
FF_CPP_SRCS := $(FF_CPP_DIR)/config.cpp $(FF_CPP_DIR)/data.cpp $(FF_CPP_DIR)/main.cpp
FF_CPP_OBJS := $(FF_CPP_SRCS:.cpp=.o)
FF_CPP_BIN := $(FF_CPP_DIR)/fullfat-bench
FF_RUST_DIR := fullfat/rust
FF_RUST_BIN := $(FF_RUST_DIR)/target/release/fullfat-bench
FF_CONFIG := fullfat/config.toml
FF_DATA := fullfat/data.json
FF_EXPECTED := fullfat/expected_output.json

.PHONY: all clean bench bench-cpp bench-rust generate-input verify \
        bench-fullfat bench-fullfat-cpp bench-fullfat-rust \
        bench-fullfat-incr-cpp bench-fullfat-incr-rust \
        verify-fullfat vendor-rust

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
	rm -f $(FF_CPP_BIN) $(FF_CPP_OBJS)
	cd $(FF_RUST_DIR) && $(CARGO) clean 2>/dev/null; true

# ============================================================
#  Fullfat benchmark targets
# ============================================================

bench-fullfat: bench-fullfat-cpp bench-fullfat-rust
	@echo ""
	@echo "===================================="
	@echo " Fullfat benchmark complete"
	@echo "===================================="

bench-fullfat-cpp:
	@echo ""
	@echo "===================================="
	@echo " C++ fullfat (clang++) — full rebuild"
	@echo "===================================="
	@rm -f $(FF_CPP_BIN) $(FF_CPP_OBJS)
	@TIMEFORMAT='real %Rs  user %Us  sys %Ss'; \
	time { \
		$(CXX) $(CXXFLAGS) -I$(FF_CPP_DIR) -c $(FF_CPP_DIR)/config.cpp -o $(FF_CPP_DIR)/config.o && \
		$(CXX) $(CXXFLAGS) -I$(FF_CPP_DIR) -c $(FF_CPP_DIR)/data.cpp -o $(FF_CPP_DIR)/data.o && \
		$(CXX) $(CXXFLAGS) -I$(FF_CPP_DIR) -c $(FF_CPP_DIR)/main.cpp -o $(FF_CPP_DIR)/main.o && \
		$(CXX) $(CXXFLAGS) -o $(FF_CPP_BIN) $(FF_CPP_OBJS); \
	} 2>&1
	@echo "--- verifying binary runs ---"
	@$(FF_CPP_BIN) $(FF_CONFIG) $(FF_DATA) > /dev/null

bench-fullfat-rust:
	@echo ""
	@echo "===================================="
	@echo " Rust fullfat (cargo) — full rebuild"
	@echo "===================================="
	@cd $(FF_RUST_DIR) && $(CARGO) clean 2>/dev/null; true
	@TIMEFORMAT='real %Rs  user %Us  sys %Ss'; \
	cd $(FF_RUST_DIR) && time $(CARGO) build $(CARGOFLAGS) 2>&1
	@echo "--- verifying binary runs ---"
	@$(FF_RUST_BIN) $(FF_CONFIG) $(FF_DATA) > /dev/null

bench-fullfat-incr-cpp:
	@echo ""
	@echo "===================================="
	@echo " C++ fullfat — incremental (touch data.cpp)"
	@echo "===================================="
	@# Ensure a full build exists first
	@if [ ! -f $(FF_CPP_BIN) ]; then \
		$(CXX) $(CXXFLAGS) -I$(FF_CPP_DIR) -c $(FF_CPP_DIR)/config.cpp -o $(FF_CPP_DIR)/config.o && \
		$(CXX) $(CXXFLAGS) -I$(FF_CPP_DIR) -c $(FF_CPP_DIR)/data.cpp -o $(FF_CPP_DIR)/data.o && \
		$(CXX) $(CXXFLAGS) -I$(FF_CPP_DIR) -c $(FF_CPP_DIR)/main.cpp -o $(FF_CPP_DIR)/main.o && \
		$(CXX) $(CXXFLAGS) -o $(FF_CPP_BIN) $(FF_CPP_OBJS); \
	fi
	@touch $(FF_CPP_DIR)/data.cpp
	@TIMEFORMAT='real %Rs  user %Us  sys %Ss'; \
	time { \
		$(CXX) $(CXXFLAGS) -I$(FF_CPP_DIR) -c $(FF_CPP_DIR)/data.cpp -o $(FF_CPP_DIR)/data.o && \
		$(CXX) $(CXXFLAGS) -o $(FF_CPP_BIN) $(FF_CPP_OBJS); \
	} 2>&1

bench-fullfat-incr-rust:
	@echo ""
	@echo "===================================="
	@echo " Rust fullfat — incremental (touch data.rs)"
	@echo "===================================="
	@# Ensure a full build exists first
	@if [ ! -f $(FF_RUST_BIN) ]; then \
		cd $(FF_RUST_DIR) && $(CARGO) build $(CARGOFLAGS); \
	fi
	@touch $(FF_RUST_DIR)/src/data.rs
	@TIMEFORMAT='real %Rs  user %Us  sys %Ss'; \
	cd $(FF_RUST_DIR) && time $(CARGO) build $(CARGOFLAGS) 2>&1

verify-fullfat:
	@echo "--- C++ fullfat output ---"
	@$(FF_CPP_BIN) $(FF_CONFIG) $(FF_DATA)
	@echo ""
	@echo "--- Rust fullfat output ---"
	@$(FF_RUST_BIN) $(FF_CONFIG) $(FF_DATA)
	@echo ""
	@echo "--- diff against expected ---"
	@diff <($(FF_CPP_BIN) $(FF_CONFIG) $(FF_DATA)) $(FF_EXPECTED) && echo "C++:  PASS" || echo "C++:  FAIL"
	@diff <($(FF_RUST_BIN) $(FF_CONFIG) $(FF_DATA)) $(FF_EXPECTED) && echo "Rust: PASS" || echo "Rust: FAIL"

vendor-rust:
	cd $(FF_RUST_DIR) && $(CARGO) vendor
