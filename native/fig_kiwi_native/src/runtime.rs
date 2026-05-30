use rustler::{Encoder, Env, Error, NifResult, Term};

pub struct Decoder<'a> {
    data: &'a [u8],
    index: usize,
}

#[allow(dead_code)]
impl<'a> Decoder<'a> {
    pub fn new(data: &'a [u8]) -> Self {
        Self { data, index: 0 }
    }

    pub fn finish(&self) -> NifResult<()> {
        if self.index == self.data.len() {
            Ok(())
        } else {
            Err(Error::Term(Box::new("unexpected trailing bytes")))
        }
    }

    pub fn read_bool(&mut self) -> NifResult<bool> {
        match self.read_byte()? {
            0 => Ok(false),
            1 => Ok(true),
            _ => Err(Error::Term(Box::new("invalid bool"))),
        }
    }

    pub fn read_byte(&mut self) -> NifResult<u8> {
        let byte = self
            .data
            .get(self.index)
            .copied()
            .ok_or_else(|| Error::Term(Box::new("unexpected eof")))?;
        self.index += 1;
        Ok(byte)
    }

    pub fn read_var_uint(&mut self) -> NifResult<u32> {
        let value = self.read_var_uint64()?;
        if value <= u32::MAX as u64 {
            Ok(value as u32)
        } else {
            Err(Error::Term(Box::new("uint out of range")))
        }
    }

    pub fn read_var_uint64(&mut self) -> NifResult<u64> {
        let mut result = 0u64;
        let mut shift = 0u32;

        for count in 0..10 {
            let byte = self.read_byte()?;
            if count == 9 && (byte & 0x7f) > 1 {
                return Err(Error::Term(Box::new("varint out of range")));
            }

            result |= ((byte & 0x7f) as u64) << shift;

            if byte < 0x80 {
                return Ok(result);
            }

            shift += 7;
        }

        Err(Error::Term(Box::new("invalid varint")))
    }

    pub fn read_var_int(&mut self) -> NifResult<i32> {
        let value = self.read_var_uint()?;
        Ok(if (value & 1) != 0 {
            !((value >> 1) as i32)
        } else {
            (value >> 1) as i32
        })
    }

    pub fn read_var_int64(&mut self) -> NifResult<i64> {
        let value = self.read_var_uint64()?;
        Ok(if (value & 1) != 0 {
            !((value >> 1) as i64)
        } else {
            (value >> 1) as i64
        })
    }

    pub fn read_var_float_value(&mut self) -> NifResult<f32> {
        let first = self.read_byte()?;
        if first == 0 {
            return Ok(0.0);
        }

        if self.index + 3 > self.data.len() {
            return Err(Error::Term(Box::new("unexpected eof")));
        }

        let bits = first as u32
            | ((self.data[self.index] as u32) << 8)
            | ((self.data[self.index + 1] as u32) << 16)
            | ((self.data[self.index + 2] as u32) << 24);
        self.index += 3;
        Ok(f32::from_bits(bits.rotate_left(23)))
    }

    pub fn read_string(&mut self) -> NifResult<String> {
        let start = self.index;
        let offset = memchr::memchr(0, &self.data[start..])
            .ok_or_else(|| Error::Term(Box::new("unterminated string")))?;
        let end = start + offset;
        let bytes = &self.data[start..end];
        self.index = end + 1;
        simdutf8::basic::from_utf8(bytes)
            .map(|value| value.to_owned())
            .map_err(|_| Error::Term(Box::new("invalid utf-8")))
    }

    pub fn read_repeated<T, F>(&mut self, mut read: F) -> NifResult<Vec<T>>
    where
        F: FnMut(&mut Self) -> NifResult<T>,
    {
        let len = self.read_var_uint()? as usize;
        let mut values = Vec::with_capacity(len);
        for _ in 0..len {
            values.push(read(self)?);
        }
        Ok(values)
    }
}

#[allow(dead_code)]
pub trait EncodeFloat<'a> {
    fn encode_float(self, env: Env<'a>) -> Term<'a>;
}

impl<'a> EncodeFloat<'a> for f32 {
    fn encode_float(self, env: Env<'a>) -> Term<'a> {
        if self.is_infinite() && self.is_sign_positive() {
            rustler::types::atom::Atom::from_str(env, "infinity")
                .unwrap()
                .encode(env)
        } else if self.is_infinite() && self.is_sign_negative() {
            rustler::types::atom::Atom::from_str(env, "negative_infinity")
                .unwrap()
                .encode(env)
        } else if self.is_nan() {
            rustler::types::atom::Atom::from_str(env, "nan")
                .unwrap()
                .encode(env)
        } else {
            (self as f64).encode(env)
        }
    }
}
