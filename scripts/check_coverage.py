"""Fails unless coverage is 100% for every source file, function, line, region and type.

llvm-cov reports lines, functions and regions per file. It has no notion of files it
never saw or of types, so this script adds both checks:

- every .swift file under Sources must appear in the report, unless it has no executable
  code at all (only protocol declarations and empty conformances);
- every class, struct and enum declared under Sources must have at least one function
  that ran. A type with no instrumented functions at all (a plain enum or struct whose
  conformances are compiler-synthesised) has no code to run and counts as declaration-only.
"""
import json
import pathlib
import re
import subprocess
import sys

report_path, sources_dir = sys.argv[1], pathlib.Path(sys.argv[2]).resolve()
data = json.load(open(report_path))["data"][0]
problems = []

# Files, lines, functions and regions.
covered_files = {}
for entry in data["files"]:
    path = pathlib.Path(entry["filename"]).resolve()
    summary = entry["summary"]
    covered_files[path] = summary
    for metric in ("lines", "functions", "regions"):
        m = summary[metric]
        if m["covered"] != m["count"]:
            problems.append(f"{path.relative_to(sources_dir)}: {metric} {m['covered']}/{m['count']}")


def has_executable_code(text):
    """True unless the file only declares protocols and empty extensions."""
    body = re.sub(r"//.*", "", text)
    body = re.sub(r"(?s)/\*.*?\*/", "", body)
    body = re.sub(r"(?s)(@MainActor\s+)?public\s+protocol\s+\w+[^{]*\{.*?\n\}", "", body)
    body = re.sub(r"(@MainActor\s+)?protocol\s+\w+[^{]*\{[^}]*\}", "", body)
    body = re.sub(r"extension\s+[\w.]+\s*:\s*[\w, ]+\{\s*\}", "", body)
    body = re.sub(r"import\s+\w+", "", body)
    return body.strip() != ""


sources = sorted(sources_dir.rglob("*.swift"))
for source in sources:
    if source.resolve() not in covered_files and has_executable_code(source.read_text()):
        problems.append(f"{source.relative_to(sources_dir)}: never ran")

# Types: every declared class, struct and enum has a function that ran.
def demangle(functions):
    names = "\n".join(f["name"] for f in functions)
    return subprocess.run(["xcrun", "swift-demangle", "--simplified"], input=names,
                          capture_output=True, text=True, check=True).stdout


ran = demangle(f for f in data["functions"] if f["count"] > 0)
instrumented = demangle(data["functions"])
type_pattern = re.compile(r"^\s*(?:@\w+\s+)*(?:(?:public|private|fileprivate|internal|final)\s+)*"
                          r"(?:class|struct|enum)\s+(\w+)", re.M)
types = sorted({(m.group(1), s.relative_to(sources_dir)) for s in sources for m in type_pattern.finditer(s.read_text())})
declaration_only_types = 0
for name, source in types:
    if not re.search(rf"\b{name}\b", instrumented):
        declaration_only_types += 1
    elif not re.search(rf"\b{name}\b", ran):
        problems.append(f"{source}: type {name} never ran")

totals = data["totals"]
print()
print(f"Files: {len(covered_files)} with code, {len(sources) - len(covered_files)} declaration-only, all checked")
code_types = len(types) - declaration_only_types
print(f"Types: {code_types - sum('type ' in p for p in problems)}/{code_types} with code ran, "
      f"{declaration_only_types} declaration-only")
for metric in ("lines", "functions", "regions"):
    m = totals[metric]
    print(f"{metric.capitalize()}: {m['covered']}/{m['count']}")
print("Branches: counted as regions (Swift emits no llvm-cov branch counters)")

if problems:
    print("\nCoverage is below 100%:")
    print("\n".join(f"  {p}" for p in problems))
    sys.exit(1)
print("\nCoverage is 100%")
