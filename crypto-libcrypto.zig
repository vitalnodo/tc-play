const std = @import("std");
const libcrypto = @import("libcrypto");
const xts = libcrypto.modes.xts;
const serpent = libcrypto.ciphers.serpent;
const twofish = libcrypto.ciphers.twofish;
pub const struct_tc_crypto_algo = extern struct {
    name: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    dm_crypt_str: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    klen: c_int = @import("std").mem.zeroes(c_int),
    ivlen: c_int = @import("std").mem.zeroes(c_int),
};

pub fn docrypt(
    ciphername: []const u8,
    key: []u8,
    in: []u8,
    out: []u8,
    iv: []u8,
    arg_do_encrypt: c_int,
) void {
    if (std.mem.eql(u8, ciphername, "AES-128-XTS")) {
        const cipher = std.crypto.core.aes.Aes128;
        const XTS = xts(
            cipher,
            std.crypto.core.aes.AesEncryptCtx,
            std.crypto.core.aes.AesDecryptCtx,
        );
        const X = XTS.init(key);
        if (arg_do_encrypt == 1) {
            X.encrypt(out, in, iv);
        }
        if (arg_do_encrypt == 0) {
            X.decrypt(out, in, iv);
        }
    }
    if (std.mem.eql(u8, ciphername, "AES-256-XTS")) {
        const cipher = std.crypto.core.aes.Aes256;
        const XTS = xts(
            cipher,
            std.crypto.core.aes.AesEncryptCtx,
            std.crypto.core.aes.AesDecryptCtx,
        );
        const X = XTS.init(key);
        if (arg_do_encrypt == 1) {
            X.encrypt(out, in, iv);
        }
        if (arg_do_encrypt == 0) {
            X.decrypt(out, in, iv);
        }
    }
    if (std.mem.eql(u8, ciphername, "TWOFISH-128-XTS")) {
        const cipher = twofish.Twofish128;
        const XTS = xts(
            cipher,
            twofish.TwofishEncryptCtx,
            twofish.TwofishDecryptCtx,
        );
        const X = XTS.init(key);
        if (arg_do_encrypt == 1) {
            X.encrypt(out, in, iv);
        }
        if (arg_do_encrypt == 0) {
            X.decrypt(out, in, iv);
        }
    }
    if (std.mem.eql(u8, ciphername, "TWOFISH-256-XTS")) {
        const cipher = twofish.Twofish256;
        const XTS = xts(
            cipher,
            twofish.TwofishEncryptCtx,
            twofish.TwofishDecryptCtx,
        );
        const X = XTS.init(key);
        if (arg_do_encrypt == 1) {
            X.encrypt(out, in, iv);
        }
        if (arg_do_encrypt == 0) {
            X.decrypt(out, in, iv);
        }
    }
    if (std.mem.eql(u8, ciphername, "SERPENT-128-XTS")) {
        const cipher = serpent.Serpent128;
        const XTS = xts(
            cipher,
            serpent.SerpentEncryptCtx,
            serpent.SerpentDecryptCtx,
        );
        const X = XTS.init(key);
        if (arg_do_encrypt == 1) {
            X.encrypt(out, in, iv);
        }
        if (arg_do_encrypt == 0) {
            X.decrypt(out, in, iv);
        }
    }
    if (std.mem.eql(u8, ciphername, "SERPENT-256-XTS")) {
        const cipher = serpent.Serpent256;
        const XTS = xts(
            cipher,
            serpent.SerpentEncryptCtx,
            serpent.SerpentDecryptCtx,
        );
        const X = XTS.init(key);
        if (arg_do_encrypt == 1) {
            X.encrypt(out, in, iv);
        }
        if (arg_do_encrypt == 0) {
            X.decrypt(out, in, iv);
        }
    }
}

pub export fn syscrypt(
    arg_cipher: [*c]struct_tc_crypto_algo,
    arg_key: [*c]u8,
    arg_klen: usize,
    arg_iv: [*c]u8,
    arg_in: [*c]u8,
    arg_out: [*c]u8,
    arg_len: usize,
    arg_do_encrypt: c_int,
) c_int {
    const ciphername = std.mem.span(arg_cipher.*.name);
    const key = arg_key[0..arg_klen];
    const iv = arg_iv[0..8];
    const in = arg_in[0..arg_len];
    const out = arg_out[0..arg_len];

    // When chaining ciphers, we reuse the input buffer as the output buffer
    if (arg_in != arg_out) {
        @memcpy(out, in);
    }
    docrypt(
        ciphername,
        key,
        in,
        out,
        iv,
        arg_do_encrypt,
    );
    return 0;
}

pub export fn tc_crypto_init() c_int {
    return 0;
}
