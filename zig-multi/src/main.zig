const std = @import("std");

const WorkerResult = struct {
    max_price: f64,
    min_price: f64,
    weights: f64,
    soma: f64,
};

const WorkerData = struct {
    lines: []const u8,
    cod: []const u8,
    result: WorkerResult,
};

fn workerThread(data: *WorkerData) void {
    var max_price = -std.math.inf(f64);
    var min_price = std.math.inf(f64);
    var weights: f64 = 0.0;
    var soma: f64 = 0.0;

    var lines = std.mem.splitSequence(u8, data.lines, "\n");
    var buffer: [32]u8 = undefined;

    while (lines.next()) |line| {
        if (line.len == 0) continue;

        var fields = std.mem.splitSequence(u8, line, ";");
        _ = fields.next();
        const codigoInstrumento = fields.next() orelse continue;
        if (codigoInstrumento.len != data.cod.len) continue;
        if (!std.mem.eql(u8, codigoInstrumento, data.cod)) continue;

        _ = fields.next();
        const PrecoNegocio = fields.next() orelse continue;
        const converted_len = @min(PrecoNegocio.len, buffer.len - 1);
        @memcpy(buffer[0..converted_len], PrecoNegocio[0..converted_len]);
        for (buffer[0..converted_len]) |*c| {
            if (c.* == ',') c.* = '.';
        }

        const QuantidadeNegociada = fields.next() orelse continue;
        const qnt = std.fmt.parseFloat(f64, QuantidadeNegociada) catch continue;
        const price = std.fmt.parseFloat(f64, buffer[0..converted_len]) catch continue;

        max_price = @max(max_price, price);
        min_price = @min(min_price, price);
        weights += qnt;
        soma += (qnt * price);
    }

    data.result = WorkerResult{
        .max_price = max_price,
        .min_price = min_price,
        .weights = weights,
        .soma = soma,
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const cod = "WDON25";
    const filepath = "/home/vinybrasil/projects/b3/negocios/data/18-06-2025_NEGOCIOSAVISTA.txt";

    const file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

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

    const num_threads = std.Thread.getCpuCount() catch 16;

    const chunk_size = fileContents.len / num_threads;
    var worker_data = try allocator.alloc(WorkerData, num_threads);
    defer allocator.free(worker_data);

    var threads = try allocator.alloc(std.Thread, num_threads);
    defer allocator.free(threads);

    var start: usize = 0;
    for (0..num_threads) |i| {
        var end = if (i == num_threads - 1) fileContents.len else start + chunk_size;

        if (end < fileContents.len) {
            while (end < fileContents.len and fileContents[end] != '\n') {
                end += 1;
            }
            if (end < fileContents.len) end += 1;
        }

        worker_data[i] = WorkerData{
            .lines = fileContents[start..end],
            .cod = cod,
            .result = WorkerResult{
                .max_price = -std.math.inf(f64),
                .min_price = std.math.inf(f64),
                .weights = 0.0,
                .soma = 0.0,
            },
        };

        start = end;
    }

    for (0..num_threads) |i| {
        threads[i] = try std.Thread.spawn(.{}, workerThread, .{&worker_data[i]});
    }

    for (0..num_threads) |i| {
        threads[i].join();
    }

    var final_max_price = -std.math.inf(f64);
    var final_min_price = std.math.inf(f64);
    var final_weights: f64 = 0.0;
    var final_soma: f64 = 0.0;

    for (worker_data) |data| {
        if (data.result.weights > 0) {
            final_max_price = @max(final_max_price, data.result.max_price);
            final_min_price = @min(final_min_price, data.result.min_price);
            final_weights += data.result.weights;
            final_soma += data.result.soma;
        }
    }

    std.debug.print("{d:.2},{d:.2},{d:.2}\n", .{ final_max_price, final_min_price, final_soma / final_weights });
}
