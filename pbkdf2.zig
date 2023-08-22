const std = @import("std");
const testing = std.testing;
const p = std.crypto.pwhash.pbkdf2;
const errno = @cImport(@cInclude("errno.h"));
const tcplay = @cImport(@cInclude("tcplay.h"));
const whirlpool = @import("whirlpool");
const ripemd160 = @import("ripemd160");

fn do_pbkdf2(
    dk: []u8,
    password: []const u8,
    salt: []const u8,
    rounds: u32,
    comptime Prf: type,
) c_int {
    p(dk, password, salt, rounds, Prf) catch {
        tcplay.tc_log(1, "Error in PBKDF2\n");
        return errno.EINVAL;
    };
    return 0;
}

pub export fn pbkdf2(
    arg_hash: [*c]tcplay.struct_pbkdf_prf_algo,
    arg_pass: [*c]const u8,
    arg_passlen: c_int,
    arg_salt: [*c]const u8,
    arg_saltlen: c_int,
    arg_keylen: c_int,
    arg_out: [*c]u8,
) c_int {
    const algo = std.mem.span(arg_hash.*.algo);
    const rounds = @as(u32, @intCast(arg_hash.*.iteration_count));
    const pass = arg_pass[0..@as(
        usize,
        @intCast(arg_passlen),
    )];
    const salt = arg_salt[0..@as(
        usize,
        @intCast(arg_saltlen),
    )];
    const out = arg_out[0..@as(usize, @intCast(arg_keylen))];
    if (std.mem.eql(u8, algo, "SHA256")) {
        return do_pbkdf2(
            out,
            pass,
            salt,
            rounds,
            std.crypto.auth.hmac.sha2.HmacSha256,
        );
    }
    if (std.mem.eql(u8, algo, "SHA512")) {
        return do_pbkdf2(
            out,
            pass,
            salt,
            rounds,
            std.crypto.auth.hmac.sha2.HmacSha512,
        );
    }
    if (std.mem.eql(u8, algo, "whirlpool")) {
        return do_pbkdf2(
            out,
            pass,
            salt,
            rounds,
            std.crypto.auth.hmac.Hmac(whirlpool.Whirlpool),
        );
    }
    if (std.mem.eql(u8, algo, "RIPEMD160")) {
        return do_pbkdf2(
            out,
            pass,
            salt,
            rounds,
            std.crypto.auth.hmac.Hmac(ripemd160.Ripemd160),
        );
    }
    return errno.EINVAL;
}
