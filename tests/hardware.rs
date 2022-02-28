use ftdi_embedded_hal as hal;
use std::{fs, thread::sleep, time::Duration};

struct DummyDelay;
impl embedded_hal::blocking::delay::DelayUs<u16> for DummyDelay {
    fn delay_us(&mut self, us: u16) {
        sleep(Duration::from_micros(us.into()))
    }
}

#[test]
fn main() {
    let bitstream =
        fs::read(concat!(env!("CARGO_PKG_NAME"), "/ftdi")).expect("Failed to read binary file");
    println!("Read binary file, size = {}", bitstream.len());

    let device: libftd2xx::Ft2232h = libftd2xx::Ftdi::new()
        .unwrap()
        .try_into()
        .expect("Failed to open device");
    println!("Connected to FT2232");

    let hal = hal::FtHal::init_freq(device, 3000000).expect("Failed to init device");
    let spi = hal.spi().unwrap();
    let ss = hal.ad4().unwrap();
    let done = hal.adi6().unwrap();
    let reset = hal.ad7().unwrap();

    println!("Configuring device...");
    let mut device = ice40::Device::new(spi, ss, done, reset, DummyDelay);
    device
        .configure(&bitstream[..])
        .expect("Failed to configure FPGA");
    println!("done!");
}
