import subprocess
import time


def make_request(code: str, type: str = "python") -> None:
    cmd = [
        "python3",
        code,
    ]

    if type == "zig":
        cmd = [
            code,
        ]

    subprocess.run(cmd, capture_output=True, text=True, check=True)


def calculate_average_time(code: str, type="python", num_iter=10) -> float:
    print("=" * 25)
    print(f"SCRIPT TO TEST: {code}")
    print("-" * 10)
    times = []
    for i in range(num_iter):
        start_time = time.time()

        make_request(code,type)
        time_result = time.time() - start_time
        print(f"{code}: TEST NUMBER {i + 1}, TIME: {time_result:.4f}")
        times.append(time_result)

    print("-" * 10)
    average_time = sum(times) / num_iter
    print(f"AVERAGE TIME {code}: {(sum(times) / num_iter):.4f}s")
    print("=" * 25)
    return average_time


calculate_average_time("pandas/main.py")
calculate_average_time("polars-python/main.py")
calculate_average_time("duckdb/main.py")
calculate_average_time("zig-single/zig-out/bin/zig_single", "zig")
calculate_average_time("zig-multi/zig-out/bin/zig_multi", "zig")
