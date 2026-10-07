"""Read-only exhaustive verification of the database bank; stdlib only."""
import csv
import io
import itertools
import subprocess
from collections import Counter


def expected_bank():
    expected = set()
    for a, b in itertools.product(range(1, 100), repeat=2):
        if a < 10 and b < 10:
            if a + b < 4:
                continue
            level = "S1"
        elif min(a, b) < 10:
            # Compare the units of the sum with the units of the larger operand.
            level = "S2" if (a + b) % 10 >= max(a, b) % 10 else "S3"
        else:
            carries = (a % 10 + b % 10 >= 10) or (a + b >= 100)
            level = "S5" if carries else "S4"
        expected.add(("addition", a, b, a + b, level))

    factors = {1: {2, 5, 10}, 2: {2, 3, 4, 5, 10}, 3: {2, 3, 4, 5, 6, 7, 10}}
    for difficulty in range(1, 7):
        maximum = 10 if difficulty <= 4 else 12 if difficulty == 5 else 16
        for a, b in itertools.product(range(2, maximum + 1), repeat=2):
            if difficulty <= 3 and not ({a, b} & factors[difficulty]):
                continue
            expected.add(("multiplication", a, b, a * b, f"M{difficulty}"))
    return expected


def main():
    query = "COPY (SELECT type,operand_a,operand_b,result,level,active FROM public.operations) TO STDOUT CSV"
    result = subprocess.run(["psql", "-X", "-w", "-v", "ON_ERROR_STOP=1", "-q", "-c", query],
                            capture_output=True, text=True)
    if result.returncode:
        raise SystemExit("Database query failed; connection details suppressed")
    rows = list(csv.reader(io.StringIO(result.stdout)))
    actual = {(kind, int(a), int(b), int(value), level) for kind, a, b, value, level, _ in rows}
    assert len(actual) == len(rows), "Duplicate operations"
    assert all(active == "t" for *_, active in rows), "Inactive seeded operations"
    expected = expected_bank()
    assert actual == expected, f"Bank mismatch: {len(expected - actual)} missing, {len(actual - expected)} unexpected"
    counts = Counter(row[4] for row in actual)
    assert counts == {"S1": 78, "S2": 810, "S3": 810, "S4": 1980, "S5": 6120,
                      "M1": 45, "M2": 65, "M3": 77, "M4": 81, "M5": 121, "M6": 225}
    print(f"PASS: {len(actual)} operations exhaustively verified across all 11 levels")
    print(dict(sorted(counts.items())))


if __name__ == "__main__":
    main()
