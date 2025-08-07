# Metrics

This repository contains binaries used to benchmark Vmprotect vs Themida vs Codedefender, along with all obfuscated binary variants, associated configuration files, and raw benchmark data.

Visualized metric data can be seen on https://metrics.codedefender.io/

> [!IMPORTANT]
> [Themida benchmarks are currently missing](#why-is-themida-missing-in-the-benchmarks).

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

In some rare cases, protected Codedefender run **faster** than the original binary.

_Why?_

We don't know

## Why are all charts empty?

This might indicate a problem with the benchmark run, please open an issue if you happen to see this!

## Why is Themida Missing in the benchmarks

Themida benchmark runs will be available soon!

The main challenge has been automating binary obfuscation with Themida.

_Why?_

- **Themida lacks support for PDB Files**
  Some of the test binaries used only ship with a PDB file attached.
  Themida however does not support PDB files and rather depends on a certain .map file structure (.map files do not follow any standards).
  This required us to write tooling to convert PDB files over to the .map file structure that Themida expects.

- **Themida crashing on certain Instructions/Macros**
  We run Themida over the CLI.
  When Themida can't handle specific instructions or macros, it crashes and leaves the CLI hanging indefinitely.
  We get no information about what went wrong or even if something went wrong, because Themida provides no feedback in these cases.
  When Themida doesn't crash but errors out, it often doesn't return any errors to stderr in CLI mode. Even when it does provide error messages, they're generic and don't specify the conflicting macro or provide useful debugging information.
