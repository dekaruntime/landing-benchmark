# landing-benchmark

Reproduction kit for the throughput comparison on [deka.gg](https://deka.gg).

Nothing here computes a result. `oha` takes every measurement, each server is
the real runtime, and `run.sh` only starts and stops things.

## What it measures

The cheapest possible request — `GET /` returning the string `hello` over plain
HTTP, no framework, no routing, no JSON — on Node, Bun, Deno and deka. That isolates
the runtime's request path, which is the thing being compared. It is not a
measure of how fast your application will be.

## Why the default configuration

Node, Bun and Deno each run a **single event loop** unless you opt into more. Using
the rest of the machine means a cluster module, `reusePort`, or a process
manager in front. deka starts **one event loop per core** with no configuration.

The headline table compares each runtime as installed, because that is what you
get when you deploy something. The tuned comparison is in the box too — run
`./run.sh tuned` — and is reported alongside, because a comparison you can only
win by omission is not worth publishing.

## Running it

Needs [`oha`](https://github.com/hatoo/oha), `node`, `bun`, `deno`, and `deka`.

```sh
brew install oha        # or: cargo install oha
curl -fsSL https://deno.land/install.sh | sh
curl -fsSL https://deka.gg/install.sh | sh

git clone https://github.com/dekaruntime/landing-benchmark
cd landing-benchmark
./setup.sh              # creates the deka project (once)
./run.sh                # default configuration
./run.sh tuned          # Node cluster + Bun reusePort
./run.sh all            # both tables
```

Knobs, all environment variables:

| variable | default | meaning |
|---|---|---|
| `CONN`   | `50`   | concurrent connections |
| `DUR`    | `10s`  | length of one run |
| `RUNS`   | `3`    | runs per runtime; the median is reported |
| `WARMUP` | `5s`   | discarded before measuring |
| `DEKA`   | `deka` | path to the deka binary |
| `OHA`    | `oha`  | path to oha |

## Reading the output

Every run prints the host, the load average, the version of every binary, and
the individual runs behind each median. If the spread across runs is wide, or
the load average is high, the numbers are noise and should be discarded.

## Known limitations

- **A `hello` response is not an application.** Real handlers do work, and the
  gap between runtimes narrows as that work grows.
- **50 connections may not saturate a large machine.** Raise `CONN` and watch
  for the point where throughput stops climbing.
- **Loopback only.** No network, no TLS, no proxy — all of which matter in
  production and none of which are being measured here.
- **The load generator competes for the same cores** as the server. On a small
  machine this depresses everything; the effect is not identical across
  runtimes.
- Single-machine, single-run numbers are indicative. If a result matters to you,
  run it yourself on hardware you control.

## Results

Committed under `results/`, one file per run, each with the full environment it
was taken in. Add yours if you run it somewhere interesting.

Please do not quote a number from this repository without the machine and
configuration it came from.
