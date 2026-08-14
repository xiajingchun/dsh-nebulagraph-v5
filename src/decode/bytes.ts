/**
 * Little-endian byte readers used by the NebulaGraph columnar decoder.
 *
 * All multi-byte integers in the vector layout are little-endian, mirroring
 * nebula-go v5 `internal/decode/utils.go`. Go's `int64`/`uint64` conversions
 * are replicated with BigInt where the value can exceed the JS safe-integer
 * range; callers decide whether to keep the BigInt or convert to number/string.
 */

/** A cursor over a byte array that records the first out-of-range read. */
export class BytesReader {
  private bs: Uint8Array
  private offset = 0
  private err: Error | null = null

  constructor(bs: Uint8Array) {
    this.bs = bs
  }

  /** Remaining unread bytes (used by geography decoding). */
  get remaining(): number {
    return this.bs.length - this.offset
  }

  readN(n: number): Uint8Array {
    if (this.offset + n > this.bs.length) {
      if (this.err === null) this.err = new Error('out of range')
      return new Uint8Array(0)
    }
    const out = this.bs.subarray(this.offset, this.offset + n)
    this.offset += n
    return out
  }

  error(): Error | null {
    return this.err
  }
}

function leU16(bs: Uint8Array): number {
  return bs[0] | (bs[1] << 8)
}
function leU32(bs: Uint8Array): number {
  return (bs[0] | (bs[1] << 8) | (bs[2] << 16) | (bs[3] << 24)) >>> 0
}

export function bytesToInt8(bs: Uint8Array): number {
  return bs[0] << 24 >> 24
}
export function bytesToUint8(bs: Uint8Array): number {
  return bs[0]
}
export function bytesToInt16(bs: Uint8Array): number {
  return leU16(bs) << 16 >> 16
}
export function bytesToUint16(bs: Uint8Array): number {
  return leU16(bs)
}
export function bytesToInt32(bs: Uint8Array): number {
  return leU32(bs) | 0
}
export function bytesToUint32(bs: Uint8Array): number {
  return leU32(bs)
}

/**
 * Read an int64 from 8 little-endian bytes as a BigInt (lossless), then
 * downcast to a JS number when the value fits in the safe range.
 *
 * @param bs - exactly 8 bytes.
 * @returns the numeric value, or a BigInt when outside the safe-integer range.
 */
export function bytesToInt64Value(bs: Uint8Array): number | bigint {
  const value = bytesToInt64Big(bs)
  return downcastBigInt(value)
}

/** Read an int64 as BigInt, preserving the sign. */
export function bytesToInt64Big(bs: Uint8Array): bigint {
  let value = 0n
  for (let i = 7; i >= 0; i--) value = (value << 8n) | BigInt(bs[i])
  return value > 0x7fff_ffff_ffff_ffffn ? value - (1n << 64n) : value
}

/** Read a uint64 as BigInt. */
export function bytesToUint64Big(bs: Uint8Array): bigint {
  let value = 0n
  for (let i = 7; i >= 0; i--) value = (value << 8n) | BigInt(bs[i])
  return value
}

/**
 * Downcast a BigInt to a JS number when it is within the safe-integer range,
 * otherwise keep the BigInt so callers can render it losslessly (e.g. as a
 * decimal string for huge vertex ids).
 *
 * @param value - the integer.
 * @returns a number for safe values, the BigInt otherwise.
 */
export function downcastBigInt(value: bigint): number | bigint {
  if (value >= -9007199254740991n && value <= 9007199254740991n) return Number(value)
  return value
}

export function bytesToFloat32(bs: Uint8Array): number {
  const buf = new ArrayBuffer(4)
  new Uint8Array(buf).set(bs.subarray(0, 4))
  return new DataView(buf).getFloat32(0, true)
}

export function bytesToFloat64(bs: Uint8Array): number {
  const buf = new ArrayBuffer(8)
  new Uint8Array(buf).set(bs.subarray(0, 8))
  return new DataView(buf).getFloat64(0, true)
}
