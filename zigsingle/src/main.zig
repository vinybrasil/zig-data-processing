pub fn main() !void {
    var max_price = -std.math.inf(f64);
    var min_price = std.math.inf(f64);
    const cod = "WDON25";
    var price: f64 = undefined;
    var qnt: f64 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const filepath = "/home/vinybrasil/projects/b3/negocios/data/18-06-2025_NEGOCIOSAVISTA.txt";

    const file = try std.fs.cwd().openFile(filepath, .{});
    const file_size = try file.getEndPos();
    const fileContents = try std.posix.mmap(
        null,
        file_size,
        std.posix.PROT.READ,
        .{ .TYPE = .PRIVATE },
        file.handle,
        0,
    );
    defer std.posix.munmap(fileContents);

    _ = std.posix.madvise(fileContents.ptr, fileContents.len, std.posix.MADV.SEQUENTIAL) catch {};

    var lines = std.mem.splitSequence(u8, fileContents, "\n");

    var buffer: [32]u8 = undefined;
    var codigoInstrumento: []const u8 = undefined;
    var PrecoNegocio: []const u8 = undefined;
    var weights: f64 = 0.0;
    var soma: f64 = 0.0;
    var QuantidadeNegociada: []const u8 = undefined;

    while (lines.next()) |line| {
        if (line.len == 0) continue;

        var fields = std.mem.splitSequence(u8, line, ";");

        _ = fields.next();

        codigoInstrumento = fields.next() orelse continue;

        if (codigoInstrumento.len != cod.len) continue;

        if (!std.mem.eql(u8, codigoInstrumento, cod)) continue;

        _ = fields.next();
        PrecoNegocio = fields.next() orelse continue;

        const converted_len = @min(PrecoNegocio.len, buffer.len - 1);
        @memcpy(buffer[0..converted_len], PrecoNegocio[0..converted_len]);

        for (buffer[0..converted_len]) |*c| {
            if (c.* == ',') c.* = '.';
        }
        QuantidadeNegociada = fields.next() orelse continue;
        qnt = std.fmt.parseFloat(f64, QuantidadeNegociada) catch continue;
        //std.debug.print("{s},{d:.2}\n", .{ QuantidadeNegociada, qnt });
        price = std.fmt.parseFloat(f64, buffer[0..converted_len]) catch continue;

        max_price = @max(max_price, price);
        min_price = @min(min_price, price);

        weights += qnt;
        soma += (qnt * price);
        //std.debug.print("{s},{d:.2},{d:.2},{d:.2},{d:.2}\n", .{ QuantidadeNegociada, qnt, soma, weights, soma / weights });
    }

    std.debug.print("{d:.2},{d:.2},{d:.2}", .{ max_price, min_price, soma / weights });
}

const std = @import("std");
