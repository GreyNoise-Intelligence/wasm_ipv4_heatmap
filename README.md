# WebAssembly IPv4 Hilbert Curve

This repo contains proof-of-concept code for a WebAssembly module to produce an IPv4 heatmap mapped to a Hilbert Curve.

* https://blog.benjojo.co.uk/post/scan-ping-the-internet-hilbert-curve

IPv4 addresses can be represented as int32 values [0 --> 4294967295] and if you graph their existence linearly, you tend to just get a bunch of streaky horizontal lines.

Using a hilbert Curve groups together IP's into square, block-like groups.

![XKCD](https://imgs.xkcd.com/comics/map_of_the_internet.jpg)
* Source: [_XKCD: Map of the Internet_](https://xkcd.com/195/)

# How and Why?

WebAssembly runtimes are available for Rust, C, C++, C#, D, Python, Javascript, Go, PHP, Ruby, Java, Elixir, R, Postgres, Swift, Zig, Dart, Crystal, Lisp, Julia, V, ... and a ton more languages for proprietary microcontrollers.

While there are [prior examples](https://github.com/measurement-factory/ipv4-heatmap) of tools to map IPv4 addresses to a Hilbert curve, I wrote this WebAssembly Module during a [GreyNoise](https://greynoise.io) Hack Week to challenge myself to see how small I could make a functioning and re-usable implementation in WebAssembly.

The result is a 465 _byte_ module that can readily be re-used in almost any code language. The module exposes a singular function:

* `insertIP(i32, i32, i32, i32)`

This function is called with each octet of an IPv4 address as paramaters

* `192.168.1.1` --> `insertIP(192, 168, 1, 1)`


After inserting the needed IPv4 addresses, the exported reference to sharded memory "`mem`" can be read into your native code language.

`mem` is 67108864 bytes in size and is a 4096x4096 RGBA Image where each pixel represents a `/24` CIDR block.

Intensity of IP's seen in a pixel will shift from Green --> Blue in color.
 * Defined in `$decrementMemoryOffset` of `main.wat`

# Running

There are Browser/Golang examples available in `/examples`) which take a list of IPv4 addresses from either `ips.json` or `ips.txt`.

`NodeJs` is recommended for any development changes/recompiling. The required libraries can be installed quickly with `npm install`.

This repo contains built in helper scripts which can be activated with `npm run (...)`, the most useful of which is `watch`.

`watch` will:
* Monitor `main.wat` for changes
* Build `out/main.wasm`
* Validate `out/main.wasm`
* Run `out/main.wasm` in `helpers/runwasm.js`, a handy debugging script which integrates well with VSCode tooling.

# Example

![A hilbert curve IPv4 heatmap generated with the WebAssembly module from this repo](examples/go_ipv4_heatmap/image.png?raw=true)
