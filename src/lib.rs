use core::time::Duration;

use byteorder::{ByteOrder, NetworkEndian};

/// FPGA configuration bitestream
#[cfg(feature = "include-bin")]
pub const FPGA_BITSTREAM : &[u8] = include_bytes!(concat!(env!("OUT_DIR"), "/top.bin"));

pub const NANOS_PER_CLK: u32 = 20;

pub enum MeasurementError {
    CalSetupError
}

pub struct Calibration {
    vref: f64,
    vref_asymmetry: f64,
    offset: f64
}

#[derive(Debug)]
pub struct MeasResult {
    run_up: u32,
    run_up_add: u32,
    run_up_sub: u32,
    run_down: u32,
    remainder: i16
}

impl MeasResult {

    /// Calculate vin based on measured counts and calibration data
    pub fn calculate_with_cal(&self, cal: &Calibration) -> Result<f64, MeasurementError> {

        todo!()
    }

    /// Calculate vref based on a known input voltage
    pub fn calculate_vref<'a>(&self, cal: &'a mut Calibration, vin: f64) -> Result<&'a Calibration, MeasurementError> {
        let estimated_vin = self.calculate_with_cal(cal)?;
        let new_vref = vin / estimated_vin * cal.vref;
        cal.vref = new_vref;
        Ok(cal)
    }

    /// Calculate the asymmetry between VREF+ and VREF-.
    /// 
    /// *Note: Only valid for mode = [SlopeMode::DualSlope]!*
    /// 
    pub fn calculate_vref_asymmetry<'a>(&self, cal: &'a mut Calibration) -> Result<&'a Calibration, MeasurementError> {
        if self.run_up_add != 0 || self.run_up_sub != 0 {
            // Sanity check
            Err(MeasurementError::CalSetupError)
        } else {
            let asym = (self.run_up as f64) / (self.run_down as f64);
            cal.vref_asymmetry = asym - cal.offset / cal.vref;
            Ok(cal)
        }
    }
}

pub enum Error<E> {
    Other(E),
}

#[derive(Debug, PartialEq, Eq)]
pub enum InputMux {
    Vin = 0x01,
    Vref = 0x02,
    Zero = 0x03,
}

pub enum SlopeMode {
    /// Peform a only one runup and one rundown
    DualSlope = 0x0,
    /// Perform multiple runup cycles and one rundown
    Multislope = 0x1
}

pub trait AbstractMultiSlopeAdc {
    type OtherError;

    /// Set the adc integration time. Rounds down to an closest number of clock cycles.
    /// Returns the integration time in clock cycles.
    fn set_integration_time(&mut self, intg: Duration) -> Result<u32, Error<Self::OtherError>> {
        let clks = intg.as_nanos() as u32 / NANOS_PER_CLK;
        self.write_word(0x101, clks)?;
        Ok(clks)
    }

    fn start(&mut self, input: InputMux, mode: SlopeMode) -> Result<(), Error<Self::OtherError>> {
        self.write_word(0x100, 0x00000001)?;
        Ok(())
    }

    fn read_word(&mut self, addr: usize) -> Result<u32, Error<Self::OtherError>>;

    fn write_word(&mut self, addr: usize, word: u32) -> Result<(), Error<Self::OtherError>>;
}

/// RTL located begind a SPI<->AXI bridge
#[cfg(feature = "spi-bridge")]
pub struct SpiMultiSlopeAdc<SPI> {
    dev: SPI,
}

impl<SPI> SpiMultiSlopeAdc<SPI> {
    const OP_READ: u32 = 0x10000000;
    const OP_WRITE: u32 = 0x20000000;

    pub fn new(spi: SPI) -> Self {
        Self { dev: spi }
    }
}

impl<SPI, E> AbstractMultiSlopeAdc for SpiMultiSlopeAdc<SPI>
where
    SPI: embedded_hal::blocking::spi::Transfer<u8, Error = E>
        + embedded_hal::blocking::spi::Write<u8, Error = E>,
{
    type OtherError = E;

    fn read_word(&mut self, addr: usize) -> Result<u32, Error<Self::OtherError>> {
        let addr = Self::OP_READ | ((addr as u32) & 0x0fffffffu32);
        let mut buffer = [0u8; 9];
        NetworkEndian::write_u32(&mut buffer[0..3], addr);
        let res = self
            .dev
            .transfer(&mut buffer)
            .map_err(|err| Error::Other(err))?;
        Ok(NetworkEndian::read_u32(&res[5..8]))
    }

    fn write_word(&mut self, addr: usize, word: u32) -> Result<(), Error<Self::OtherError>> {
        let addr = Self::OP_WRITE | ((addr as u32) & 0x0fffffffu32);
        let mut buffer = [0u8; 9];
        NetworkEndian::write_u32(&mut buffer[0..3], addr);
        NetworkEndian::write_u32(&mut buffer[4..7], word);
        self.dev
            .transfer(&mut buffer)
            .map_err(|err| Error::Other(err))?;
        Ok(())
    }
}

/// Memory mapped
pub struct DirectMultiSlopeAdc<const BASE_ADDR: usize>;

impl<const BASE_ADDR: usize> DirectMultiSlopeAdc<BASE_ADDR> {
    ///
    ///
    pub unsafe fn new() -> Self {
        Self
    }
}
