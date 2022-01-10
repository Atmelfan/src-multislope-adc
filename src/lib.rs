use embedded_hal::adc;

use std::error::Error;

pub fn really_complicated_code(a: u8, b: u8) -> Result<u8, Box<dyn Error>> {
    Ok(a + b)
}


struct MultislopeAdc {

}

pub mod channel {
    pub struct Multislope;
    pub struct Residue;
    pub struct Integrator;
    pub struct Aux1;
    pub struct Aux2;
    pub struct Aux3;
    pub struct Aux4;
    pub struct Aux5;
    pub struct Aux6;
}

pub enum ChannelSelection {
    Multislope,
    Residue,
    Integrator,
    Aux1,
    Aux2,
    Aux3,
    Aux4,
    Aux5,
    Aux6,
}



macro_rules! impl_channel {
    ( $IC:ident, $CH:ident ) => {
        impl adc::Channel<MultislopeAdc> for channel::$CH {
            type ID = ChannelSelection;

            fn channel() -> Self::ID {
                ChannelSelection::$CH
            }
        }
    };
}

impl_channel!(MultislopeAdc, Multislope);
impl_channel!(MultislopeAdc, Residue);
impl_channel!(MultislopeAdc, Integrator);
impl_channel!(MultislopeAdc, Aux1);
impl_channel!(MultislopeAdc, Aux2);
impl_channel!(MultislopeAdc, Aux3);
impl_channel!(MultislopeAdc, Aux4);
impl_channel!(MultislopeAdc, Aux5);
impl_channel!(MultislopeAdc, Aux6);





#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        let result = 2 + 2;
        assert_eq!(result, 4);
    }
}
