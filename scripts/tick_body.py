"""Tick QA checkboxes in a PR body read from stdin (used by tick.sh).

tick_body.py N [N ...]  prints the body with those steps ticked; exit 2, printing nothing,
                        if a step matches no box or more than one.
tick_body.py --list     prints one line per box: its step number and the start of the line.

A box is numbered by its own text ("N. - [ ] ..." or "- [ ] N. ..."). When the body has no
numbered boxes, its boxes are counted from 1 in order instead.
"""
import re
import sys

NUM_FIRST = re.compile(r"^\s*(\d+)\.\s+[-*]\s+\[[ xX]\]")  # "N. - [ ] text"
BOX_FIRST = re.compile(r"^\s*[-*]\s+\[[ xX]\]\s+(\d+)\.")  # "- [ ] N. text"
PLAIN = re.compile(r"^\s*[-*]\s+\[[ xX]\]")  # "- [ ] text"


def boxes(lines):
    """[(line index, step)] for every checkbox line, numbered as the module doc says."""
    numbered, plain = [], []
    for i, line in enumerate(lines):
        m = NUM_FIRST.match(line) or BOX_FIRST.match(line)
        if m:
            numbered.append((i, int(m.group(1))))
        elif PLAIN.match(line):
            plain.append(i)
    return numbered or [(i, n) for n, i in enumerate(plain, start=1)]


def main(argv):
    lines = sys.stdin.read().split("\n")
    found = boxes(lines)
    if argv == ["--list"]:
        for i, n in found:
            print(f"{n}: {lines[i].strip()[:40]}")
        return 0
    problems = []
    for s in map(int, argv):
        hits = [i for i, n in found if n == s]
        if len(hits) != 1:
            problems.append(f"step {s} matches {len(hits)} boxes")
            continue
        lines[hits[0]] = lines[hits[0]].replace("[ ]", "[x]", 1)
    if problems:
        print("REFUSED, nothing changed: " + "; ".join(problems), file=sys.stderr)
        return 2
    sys.stdout.write("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
