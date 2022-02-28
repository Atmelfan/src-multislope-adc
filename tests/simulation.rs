#![cfg(all(test, feature = "cosim"))]
use embedded_hal::{self, prelude::_embedded_hal_blocking_spi_Transfer};
use lazy_static::lazy_static;
use libc::{self, c_char};
use libloading::Library;
use std::{
    fmt::{Display, Write},
    ops::{Index, IndexMut},
    panic,
    sync::{
        atomic::{AtomicBool, Ordering},
        mpsc::{channel, Receiver, Sender, TryRecvError},
        Mutex,
    },
    thread,
    time::Duration,
};

lazy_static! {
    static ref SPI_RX: Mutex<Option<Receiver<u8>>> = Mutex::new(None);
    static ref SPI_TX: Mutex<Option<Sender<u8>>> = Mutex::new(None);
}

static START_TEST: AtomicBool = AtomicBool::new(true);

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum StdLogic {
    Uninitialized,
    Unknown,
    High,
    Low,
    Hiz,
    Weak,
    WeakLow,
    WeakHigh,
    DontCare,
}

impl StdLogic {
    fn to_char(self) -> char {
        match self {
            StdLogic::Uninitialized => 'U',
            StdLogic::Unknown => 'X',
            StdLogic::High => '1',
            StdLogic::Low => '0',
            StdLogic::Hiz => 'Z',
            StdLogic::Weak => 'W',
            StdLogic::WeakLow => 'L',
            StdLogic::WeakHigh => 'H',
            StdLogic::DontCare => '-',
        }
    }
}

impl Default for StdLogic {
    fn default() -> Self {
        Self::Uninitialized
    }
}

impl From<bool> for StdLogic {
    fn from(x: bool) -> Self {
        if x {
            Self::High
        } else {
            Self::Low
        }
    }
}

impl From<StdLogic> for bool {
    fn from(x: StdLogic) -> Self {
        match x {
            StdLogic::Low | StdLogic::WeakLow => false,
            StdLogic::High | StdLogic::WeakHigh => true,
            _ => panic!("Cannot convert {} to bool", x.to_char()),
        }
    }
}

impl From<libc::c_char> for StdLogic {
    fn from(c: libc::c_char) -> Self {
        match c {
            0 => Self::Uninitialized,
            1 => Self::Unknown,
            2 => Self::Low,
            3 => Self::High,
            4 => Self::Hiz,
            5 => Self::Weak,
            6 => Self::WeakLow,
            7 => Self::WeakHigh,
            8 => Self::DontCare,
            _ => Self::Unknown,
        }
    }
}

impl From<StdLogic> for libc::c_char {
    fn from(c: StdLogic) -> Self {
        (match c {
            StdLogic::Uninitialized => 0,
            StdLogic::Unknown => 1,
            StdLogic::Low => 2,
            StdLogic::High => 3,
            StdLogic::Hiz => 4,
            StdLogic::Weak => 5,
            StdLogic::WeakLow => 6,
            StdLogic::WeakHigh => 7,
            StdLogic::DontCare => 8,
        }) as c_char
    }
}

impl Display for StdLogic {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "'{}'", self.to_char())
    }
}

struct StdLogicVector {
    data: *mut libc::c_char,
    len: usize,
}

impl StdLogicVector {
    fn new(data: *mut libc::c_char, len: usize) -> Self {
        Self { data, len }
    }

    fn get_value(&self, index: usize) -> StdLogic {
        assert!(index < self.len, "std_logic_vector out of range");
        unsafe {
            let c: *mut libc::c_char = self.data.offset(index as isize);
            StdLogic::from(*c)
        }
    }

    fn set_value(&mut self, index: usize, val: StdLogic) {
        assert!(index < self.len, "std_logic_vector out of range");
        unsafe {
            let c: *mut libc::c_char = self.data.offset(index as isize);
            *c = libc::c_char::from(val)
        }
    }

    fn get_unsigned(&self) -> u32 {
        let mut out = 0;
        for x in 0..self.len {
            out = out | ((self.get_value(x) == StdLogic::High) as u32) << x;
        }
        out
    }

    fn set_unsigned(&mut self, value: u32) {
        for x in 0..self.len {
            self.set_value(x, StdLogic::from(value & (1 << x) != 0));
        }
    }
}

impl Display for StdLogicVector {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_char('"')?;
        for x in 0..self.len as isize {
            unsafe {
                let c: *mut libc::c_char = self.data.offset(x);
                f.write_char(StdLogic::from(*c).to_char())?;
            }
        }
        f.write_char('"')
    }
}

#[no_mangle]
pub extern "C" fn sim_spi_init() {
    println!("sim_spi_init");
}

#[no_mangle]
pub extern "C" fn sim_spi_rxtx(data: *mut libc::c_char, flags: *mut libc::c_char) {
    let chrx = SPI_RX.lock().unwrap();
    let chtx = SPI_TX.lock().unwrap();
    let rxc = chrx.as_ref().unwrap();
    let txc = chtx.as_ref().unwrap();

    let mut datav = StdLogicVector::new(data, 8);
    let mut flagsv = StdLogicVector::new(flags, 4);
    //println!("sim_spi_rxtx {}, {}", datav, flagsv);

    match rxc.try_recv() {
        Ok(rxb) => {
            let txb = (datav.get_unsigned() as u8).reverse_bits();
            datav.set_unsigned(rxb.reverse_bits() as u32);
            println!("spi xfer MOSI: {:02x}, MISO: {:02x}", rxb, txb);

            if txc.send(txb).is_ok() {
                flagsv.set_value(3, StdLogic::from(true))
            } else {
                println!("Failed to send!");
                flagsv.set_value(0, StdLogic::from(true))
            }
        }
        Err(TryRecvError::Empty) => {
            //println!("Rx buffer empty");
            flagsv.set_value(3, StdLogic::from(false))
        }
        Err(TryRecvError::Disconnected) => flagsv.set_value(0, StdLogic::from(true)),
    }
}

struct SimSpiMaster {
    mosi: Sender<u8>,
    miso: Receiver<u8>,
}

impl SimSpiMaster {
    fn new(mosi: Sender<u8>, miso: Receiver<u8>) -> Self {
        Self { mosi, miso }
    }
}

impl embedded_hal::blocking::spi::Transfer<u8> for SimSpiMaster {
    type Error = ();

    fn transfer<'w>(&mut self, words: &'w mut [u8]) -> Result<&'w [u8], Self::Error> {
        for x in words.iter_mut() {
            self.mosi.send(*x).map_err(|_| ())?;
            *x = self.miso.recv().map_err(|_| ())?
        }
        Ok(words)
    }
}

#[cfg(feature = "cosim")]
#[test]
fn ghdl_cosim() {
    let (spi_rx_sender, spi_rx_receiver) = channel::<u8>();
    let (spi_tx_sender, spi_tx_receiver) = channel::<u8>();
    {
        let mut chrx = SPI_RX.lock().unwrap();
        chrx.replace(spi_rx_receiver);
        let mut chtx = SPI_TX.lock().unwrap();
        chtx.replace(spi_tx_sender);
    }

    let ghdl_handle = thread::spawn(move || unsafe {
        let lib = libloading::Library::new(concat!(env!("OUT_DIR"), "/test.so")).unwrap();
        let grt_init: libloading::Symbol<unsafe extern "C" fn()> = lib.get(b"grt_init").unwrap();

        let grt_main_options: libloading::Symbol<
            unsafe extern "C" fn(argc: libc::c_int, argv: *const *const libc::c_char),
        > = lib.get(b"grt_main_options").unwrap();

        let grt_main_elab: libloading::Symbol<unsafe extern "C" fn()> =
            lib.get(b"grt_main_elab").unwrap();

        let __ghdl_simulation_init: libloading::Symbol<unsafe extern "C" fn()> =
            lib.get(b"__ghdl_simulation_init").unwrap();

        let __ghdl_simulation_step: libloading::Symbol<unsafe extern "C" fn() -> libc::c_int> =
            lib.get(b"__ghdl_simulation_step").unwrap();

        let ghw = CString::new("--trace").unwrap();
        let argv = [ghw.as_ptr(), std::ptr::null()];

        println!("Initializing simulation...");
        grt_init();
        println!("grt_main_options");
        grt_main_options(argv.len() as libc::c_int, argv.as_ptr());
        println!("grt_main_elab");
        grt_main_elab();
        println!("__ghdl_simulation_init");
        __ghdl_simulation_init();
        let mut ecode: libc::c_int = 0;
        println!("Running simulation...");
        while ecode < 3 && START_TEST.load(Ordering::Relaxed) {
            ecode = __ghdl_simulation_step();
            //println!("__ghdl_simulation_step {}",ecode);
        }
        thread::sleep(Duration::from_secs(1));
        println!("Simulation finished, ecode = {}", ecode);
        lib.close().unwrap();
        ecode
    });

    println!("Running test");
    {
        let mut spi = SimSpiMaster::new(spi_rx_sender, spi_tx_receiver);
        let mut buffer = [
            0x11u8, 0x02, 0x03, 0x04, 0x12, 0x34, 0x56, 0x78, 0x00, 0x00, 0x00,
        ];
        println!("Sending {:?}", &buffer);
        let recv = spi.transfer(&mut buffer).unwrap();
        println!("Recv {:?}", recv);
    }

    println!("Stopping simulation...");
    START_TEST.store(false, Ordering::Relaxed);

    let exit = ghdl_handle.join().unwrap();
    //assert!(exit == 0, "Simulation failed");

    use std::ffi::CString;
}

#[test]
fn rtl_tests() {}
