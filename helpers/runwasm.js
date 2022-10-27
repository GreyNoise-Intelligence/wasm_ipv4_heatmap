const fs = require('fs');
const buf = fs.readFileSync('out/main.wasm');

const start = async function () {
    console.log("In runwasm.js: ");
    await WebAssembly.instantiate(new Uint8Array(buf),
        {
        }).then(res => {
            var memoryView = new Uint8ClampedArray(res.instance.exports.mem.buffer)
            res.instance.exports.insertIP(0, 0, 0, 0);
            console.log(memoryView);
            res.instance.exports.insertIP(0, 0, 0, 0);
            console.log(memoryView);
        });
}
start();