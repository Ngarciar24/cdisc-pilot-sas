"""CI check for the committed SAS evidence (SAS itself does not run in CI).

Fails if:
  1. a committed log has a finding (same rules as macros/logcheck.sas);
  2. a .sas file lacks the standard header fields;
  3. two programs share a file name (their logs would overwrite each other).
Warns (does not fail) if a program under programs/ or qc/ has no
logs/<name>.log yet; pass --require-logs to make that a failure too.

Usage: python tools/check_logs.py [repo_root] [--require-logs]
"""
import pathlib
import sys
from collections import defaultdict

# Keep in sync with the PAT array in macros/logcheck.sas.
PATTERNS = [
    "uninitialized",
    "repeats of BY values",
    "values have been converted",
    "Invalid data",
    "Invalid argument",
    "W.D format was too small",
    "Missing values were generated",
    "Division by zero",
    "Mathematical operations could not be performed",
    "will be overwritten by data set",
    "stopped processing",
]

HEADER_FIELDS = [
    "Program", "Study", "Purpose", "Inputs", "Outputs", "Macros",
    "Author", "Created", "SAS version", "Change log",
]

PROGRAM_DIRS = ["programs", "qc"]


def log_findings(path):
    """Yield (line number, finding, text) for each flagged line of a log."""
    with open(path, encoding="utf-8", errors="replace") as fh:
        for n, line in enumerate(fh, 1):
            text = line.rstrip("\r\n")
            if text.startswith("ERROR"):
                yield n, "ERROR", text
            elif text.startswith("WARNING"):
                yield n, "WARNING", text
            elif text.startswith(("NOTE", "INFO")):
                for pat in PATTERNS:
                    if pat in text:
                        yield n, pat, text
                        break


def header_missing(path):
    """Header fields absent from the first comment block of a .sas file."""
    head = path.read_text(encoding="utf-8", errors="replace")[:3000]
    return [f for f in HEADER_FIELDS if f"* {f}" not in head]


def main(root, require_logs=False):
    root = pathlib.Path(root).resolve()
    problems = []
    warnings = []

    def report(file, msg, line=None, level="error"):
        loc = f"file={file.relative_to(root)}" + (f",line={line}" if line else "")
        print(f"::{level} {loc}::{msg}")
        (problems if level == "error" else warnings).append(msg)

    # 3. headers on every .sas file in the repo
    for sas in sorted(root.rglob("*.sas")):
        missing = header_missing(sas)
        if missing:
            report(sas, "header missing: " + ", ".join(missing))

    # 1 and 4. every program has a log; names are unique
    programs = [p for d in PROGRAM_DIRS for p in sorted((root / d).rglob("*.sas"))]
    by_name = defaultdict(list)
    for p in programs:
        by_name[p.stem].append(p)
    for name, paths in by_name.items():
        if len(paths) > 1:
            report(paths[1], f"program name '{name}' used more than once")
        log = root / "logs" / f"{name}.log"
        if not log.exists():
            report(paths[0], f"no committed log: logs/{name}.log "
                             "(run run_all.sas in SAS and commit logs/)",
                   level="error" if require_logs else "warning")

    # 2. every committed log is clean
    logs = sorted((root / "logs").glob("*.log"))
    for log in logs:
        for n, finding, text in log_findings(log):
            report(log, f"{finding}: {text.strip()[:200]}", n)

    print(f"{len(programs)} program(s), {len(logs)} log(s), "
          f"{len(problems)} problem(s), {len(warnings)} warning(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if a != "--require-logs"]
    sys.exit(main(args[0] if args else ".",
                  require_logs="--require-logs" in sys.argv[1:]))
