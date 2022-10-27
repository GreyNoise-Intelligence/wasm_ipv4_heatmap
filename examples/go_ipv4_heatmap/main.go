package main

import (
	"bufio"
	"encoding/binary"
	"fmt"
	"image"
	"image/png"
	"io/ioutil"
	"log"
	"os"
	"runtime/debug"
	"strconv"
	"strings"

	wasmer "github.com/wasmerio/wasmer-go/wasmer"
)

func i32ToBs(i32 int32) []byte {
	bs := make([]byte, 4)
	binary.LittleEndian.PutUint32(bs, uint32(i32))
	return bs
}

func main() {
	//Don't let Go GC the memory out from under us
	debug.SetGCPercent(-1)
	wasmBytes, _ := ioutil.ReadFile("../../out/main.wasm")

	engine := wasmer.NewEngine()
	store := wasmer.NewStore(engine)

	// Compiles the module
	module, _ := wasmer.NewModule(store, wasmBytes)

	// Instantiates the module
	importObject := wasmer.NewImportObject()
	instance, _ := wasmer.NewInstance(module, importObject)

	memory, _ := instance.Exports.GetMemory("mem")

	// Gets the exported functions from the WebAssembly instance.
	insertIP, _ := instance.Exports.GetFunction("insertIP")
	getAt, _ := instance.Exports.GetFunction("get_at")

	//Read in list of IP's
	file, err := os.Open("ips.txt")
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)

	for scanner.Scan() {
		//fmt.Println(scanner.Text())
		s := strings.Split(scanner.Text(), ".")
		oct1, _ := strconv.Atoi(s[0])
		oct2, _ := strconv.Atoi(s[1])
		oct3, _ := strconv.Atoi(s[2])
		oct4, _ := strconv.Atoi(s[3])

		_, _ = insertIP(oct1, oct2, oct3, oct4)
	}

	if err := scanner.Err(); err != nil {
		fmt.Println(scanner.Text())
		log.Fatal(err)
	}

	// Calls that exported function with Go standard values. The WebAssembly
	// types are inferred and values are casted automatically.
	_, _ = insertIP(0, 0, 0, 0)

	//Peek at first pixel
	result, _ := getAt(0)
	fmt.Println(i32ToBs(result.(int32)))

	img := image.NewRGBA(image.Rectangle{image.Point{0, 0}, image.Point{4096, 4096}})

	img.Pix = memory.Data()

	// // // Encode as PNG.
	f, _ := os.Create("image.png")
	png.Encode(f, img)
}
