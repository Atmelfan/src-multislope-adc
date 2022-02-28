
# src-multislope-adc

See [examples](examples).

# Usage
Add the following to your Cargo.toml:
```toml
[dependencies.multislope-adc]
git = "https://github.com/Atmelfan/src-multislope-adc"
tag = v0.1.0
```
If you want to override the default pinout constraints file, add this to your.cargo/config.toml:
```toml
[env]
PCF = { value = "your/pinout.pcf", relative = true }
```

If larger changes are wanted you can try adding the crate as a submodule and add it to your manifest 
using `multislope-adc = { path = "src-multislope-adc", default-features = false }` and build the hdl yourself with a custom top entity.


# Organization
- `rtl` - Hardware design files (gateware)
- `src` - Rust library sources
- `tests` - Rust integration tests

# Tools
1. Yosys with ice40 synthesis, follow [this tutorial](https://projectf.io/posts/building-ice40-fpga-toolchain/).
2. GHDL with synth support, follow [this tutorial](https://ghdl.github.io/ghdl/development/building/index.html)
3. ghdl-yosys-plugin, follow the [README](https://github.com/ghdl/ghdl-yosys-plugin)
4. Cocotb, cocotb-bus, and cocotb-test, follow the [README](https://github.com/cocotb/cocotb) or `pip install -r requirements.txt`

# License
This projects is licensed under CERN Open Hardware Licence Version 2 - Strongly Reciprocal.

See [LICENSE.txt](LICENSE.txt).