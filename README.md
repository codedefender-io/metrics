# Metrics

This repository contains binaries used to benchmark VMProtect vs Themida vs Codedefender, along with all obfuscated binary variants, associated configuration files, and raw benchmark data.

Visualized metric data can be seen on https://metrics.codedefender.io/

## What do the metrics include

The Metrics include:

- Execution time: mean, median, time trends, overhead.
- Size increase: bytes and percentage.
- Transformation: Functions that have been transformed and rejected including the rejection reason.

Folder structure:

```
binaries/
└── example/
    ├── example.exe
    ├── benchmarks/
    │   └── latest.json
    ├── configs/                    # includes all configs used
    └── obfuscated/                 # contains all obfuscated binaries
```

# Benchmark Environment

The performance benchmarks are run on a virtualized Intel Core Processor (Broadwell), 2.2 GHz, 3 cores/3 threads, with 8GB RAM.

The runners are warmed up and given 5 iterations of execution to prime the binary on the CPU, then 10 iterations of execution to record execution timings.

Each binary in the benchmark runner gets executed with the [PowerShell Measure-Command](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/measure-command?view=powershell-7.5) that returns execution speed.

If you believe that our data is biased or does not reflect the truth, we invite you to benchmark the binary yourself.

All configs and binaries are included in the `binary/binary_name/configs` folder.

## Why Is the Codedefender chart empty

The Performance overhead might appear empty in some cases.

First and foremost, this isn't a bug with the charts!

In some rare cases, the protected Codedefender binary runs **faster** than the original binary.

_Why?_

We don't know

## Why are all charts empty?

This might indicate a problem with the benchmark run, please open an issue if you happen to see this!

## Why are VMProtect transformation rates so low?

Our benchmark tool generates configs that include every symbol found in the PDB.

When VmProtect runs and hits errors, we parse the error messages to identify conflicting symbol and remove it from the config.

The problem: VmProtect sometimes reports incorrect symbol names in error messages, making it hard to identify which symbol actually caused the conflict.

As a workaround, we pre-filter symbols known to trigger this behavior.

We're actively working on a fix!
