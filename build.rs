use std::env;
use std::path::Path;
use std::process::Command;

fn main() {
    let out_dir = env::var("OUT_DIR").unwrap();
    let hdl_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
    let makeflags = env::var("CARGO_MAKEFLAGS").unwrap_or_default();

    println!("{}", out_dir);
    println!("{}", hdl_dir);

    // makefile is using a special env variable
    Command::new("make")
        .current_dir(Path::new(&hdl_dir).join("rtl"))
        .env("BUILD_DIR", Path::new(&out_dir))
        .env("MAKEFLAGS", makeflags)
        .status()
        .expect("Failed to run synthesis");
}
