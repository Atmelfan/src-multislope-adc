use std::env;
use std::path::Path;
use std::process::Command;

fn main() {
    let out_dir = env::var("OUT_DIR").unwrap();
    let root = env::var("CARGO_MANIFEST_DIR").unwrap();
    let makeflags = env::var("CARGO_MAKEFLAGS").unwrap_or_default();

    // Rerun if makefile changes
    // Note that the makefile also prints out cargo:rerun-if-changed for its dependencies
    println!(
        "cargo:rerun-if-changed={}",
        Path::new(&root).join("rtl").join("Makefile").display()
    );

    // Cosimulation requires exporting symbols so that ghdl can call them.
    if cfg!(feature = "cosim") {
        println!("cargo:rustc-link-arg=-export-dynamic");
    }

    // Run RTL synthesis and model compilation 
    let status = Command::new("make")
        .current_dir(Path::new(&root).join("rtl"))
        .env("BUILD_DIR", Path::new(&out_dir))
        .env("MAKEFLAGS", makeflags.clone())
        .arg("all")
        .status()
        .expect("Failed to run make");

    if !status.success() {
        panic!("Failed to make HDL")
    }
}
