const std = @import("std");
const libcrypto = @import("libcrypto");
const xts = libcrypto.modes.xts;
const serpent = libcrypto.ciphers.serpent;
const twofish = libcrypto.ciphers.twofish;

const EINVAL: c_int = @backingInt(std.c.E.INVAL);

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
    do_encrypt: bool,
) error{InvalidLength}!bool {
    if (std.mem.eql(u8, ciphername, "AES-128-XTS")) {
        const cipher = std.crypto.core.aes.Aes128;
        const XTS = xts(
            cipher,
            std.crypto.core.aes.AesEncryptCtx,
            std.crypto.core.aes.AesDecryptCtx,
        );
        var X = try XTS.init(key);
        defer X.deinit();
        if (do_encrypt) {
            try X.encrypt(out, in, iv);
        } else {
            try X.decrypt(out, in, iv);
        }
        return true;
    }
    if (std.mem.eql(u8, ciphername, "AES-256-XTS")) {
        const cipher = std.crypto.core.aes.Aes256;
        const XTS = xts(
            cipher,
            std.crypto.core.aes.AesEncryptCtx,
            std.crypto.core.aes.AesDecryptCtx,
        );
        var X = try XTS.init(key);
        defer X.deinit();
        if (do_encrypt) {
            try X.encrypt(out, in, iv);
        } else {
            try X.decrypt(out, in, iv);
        }
        return true;
    }
    if (std.mem.eql(u8, ciphername, "TWOFISH-128-XTS")) {
        const cipher = twofish.Twofish128;
        const XTS = xts(
            cipher,
            twofish.TwofishEncryptCtx,
            twofish.TwofishDecryptCtx,
        );
        var X = try XTS.init(key);
        defer X.deinit();
        if (do_encrypt) {
            try X.encrypt(out, in, iv);
        } else {
            try X.decrypt(out, in, iv);
        }
        return true;
    }
    if (std.mem.eql(u8, ciphername, "TWOFISH-256-XTS")) {
        const cipher = twofish.Twofish256;
        const XTS = xts(
            cipher,
            twofish.TwofishEncryptCtx,
            twofish.TwofishDecryptCtx,
        );
        var X = try XTS.init(key);
        defer X.deinit();
        if (do_encrypt) {
            try X.encrypt(out, in, iv);
        } else {
            try X.decrypt(out, in, iv);
        }
        return true;
    }
    if (std.mem.eql(u8, ciphername, "SERPENT-128-XTS")) {
        const cipher = serpent.Serpent128;
        const XTS = xts(
            cipher,
            serpent.SerpentEncryptCtx,
            serpent.SerpentDecryptCtx,
        );
        var X = try XTS.init(key);
        defer X.deinit();
        if (do_encrypt) {
            try X.encrypt(out, in, iv);
        } else {
            try X.decrypt(out, in, iv);
        }
        return true;
    }
    if (std.mem.eql(u8, ciphername, "SERPENT-256-XTS")) {
        const cipher = serpent.Serpent256;
        const XTS = xts(
            cipher,
            serpent.SerpentEncryptCtx,
            serpent.SerpentDecryptCtx,
        );
        var X = try XTS.init(key);
        defer X.deinit();
        if (do_encrypt) {
            try X.encrypt(out, in, iv);
        } else {
            try X.decrypt(out, in, iv);
        }
        return true;
    }
    return false;
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
    if (arg_do_encrypt != 0 and arg_do_encrypt != 1) {
        return EINVAL;
    }
    const ciphername = std.mem.span(arg_cipher.*.name);
    const key = arg_key[0..arg_klen];
    const iv = arg_iv[0..8];
    const in = arg_in[0..arg_len];
    const out = arg_out[0..arg_len];

    // When chaining ciphers, we reuse the input buffer as the output buffer
    if (arg_in != arg_out) {
        @memcpy(out, in);
    }
    const ok = docrypt(
        ciphername,
        key,
        in,
        out,
        iv,
        arg_do_encrypt == 1,
    ) catch false;
    if (!ok) {
        // Don't leave a plaintext copy behind for an unknown cipher or bad length
        if (arg_in != arg_out) {
            std.crypto.secureZero(u8, out);
        }
        return EINVAL;
    }
    return 0;
}

pub export fn tc_crypto_init() c_int {
    return 0;
}
