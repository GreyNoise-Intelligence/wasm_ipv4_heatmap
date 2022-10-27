(module
  (memory $memory 1024)
  (export "mem" (memory $memory))

  (export "get_at" (func $get_at))
  (func $get_at (param $idx i32) (result i32)
	  local.get $idx
    i32.load   
  )

  (export "insertIP" (func $insertIP))
  (func $insertIP (param $oct1 i32) (param $oct2 i32) (param $oct3 i32) (param $oct4 i32)

    ;;call $initMemory

    ;;Cast 4 octcts to int32 cast as i64
    local.get $oct1
    local.get $oct2
    local.get $oct3
    local.get $oct4
    call $ipv4Toi64

    ;;Bin into a /24 CIDR
    call $ipi64ToSlash24Bin

    ;;Convert CIDR block to x,y coordinates
    ;;Wrap i64 sequence as i32
    i32.wrap_i64
    ;;Hilbert order 12
    i32.const 12
    call $hil_xy_from_s

    ;;Convert x,y coordinates to memory offset
    call $xyToMemoryOffset

    ;;Initialize pixel and/or decrement alpha channel of pixel
    call $decrementMemoryOffset
  
  )

  (func $initMemory
    (local $memSize i32)
    (local $counter i32)

    ;;How many 4 byte chunks (i32) there is
    i32.const 16777216
    local.set $memSize

    i32.const 0
    local.set $counter

    (loop $paintItBlack
      ;;Else initialize memory

      ;;Memory offset for loop
      local.get $counter
      ;;Black
      i32.const -1
      ;;Set Memory region
      i32.store

      ;;Step 4 bytes
      local.get $counter
      i32.const 4
      i32.add
      local.set $counter

      ;;Break loop if we're done
      local.get $memSize
      local.get $counter
      i32.ne
      br_if $paintItBlack
    )
  )
  
  ;;(export "ipv4Toi64" (func $ipv4Toi64))
  (func $ipv4Toi64 (param $oct1 i32) (param $oct2 i32) (param $oct3 i32) (param $oct4 i32) (result i64)
    ;;Takes the four octets of an IPv4 address and converts to an int32
    ;;Actually cast as i64 of int32 of weird signed-ness purposes
    ;;192.168.1.1 = (192 * 256^3) + (168 * 256^2) + (1 * 256^1) + (1 * 256^0)
    
    local.get $oct1
    i64.extend_i32_s
    ;; 256^3
    i64.const 16777216
    i64.mul
    
    local.get $oct2
    i64.extend_i32_s
    ;; 256^2
    i64.const 65536
    i64.mul

    local.get $oct3
    i64.extend_i32_s
    ;; 256^1
    i64.const 256
    i64.mul

    local.get $oct4
    i64.extend_i32_s

    ;;4 values on the stack, sum them
    i64.add
    i64.add
    i64.add
  )

  ;;(export "ipi64ToSlash24Bin" (func $ipi64ToSlash24Bin))
  (func $ipi64ToSlash24Bin (param $ipi64 i64) (result i64)
    ;;Takes an ip i64 and bins it into a /24 CIDR range
    ;; (256 IP's per bin)
    local.get $ipi64
    i64.const 256
    i64.div_u
  )

  ;;(export "slash24Toxy" (func $slash24Toxy))
  (func $slash24Toxy (param $slash24 i64) (result i64 i64)
    ;;Takes a /24 bin number and gives an x,y coordinate
    ;;that represents that IP space

    ;;Get X
    local.get $slash24
    i64.const 4096
    i64.rem_u

    ;;Get Y
    local.get $slash24
    i64.const 4096
    i64.div_u
  )

  ;;Please don't ask me to explain this
  ;;I screwed it up so many times
  ;;But it produces identical results to C implementation
  ;;so...ship it
  (func $hil_xy_from_s (param $s i32) (param $n i32) (result i64 i64)
  (local $2 i32)
  (local $3 i32)
  (local $4 i32)
  (local $5 i32)
  (local $i i32)
  (local $x i32)
  (local $y i32)
  (local $temp i32)
  (local $outx i32)
  (local $outy i32)
  (block $label$0
   (block $label$1
    (br_if $label$1
     (i32.lt_s
      (get_local $n)
      (i32.const 1)
     )
    )
    (set_local $2
     (i32.shl
      (get_local $n)
      (i32.const 1)
     )
    )
    (set_local $i
     (i32.const 0)
    )
    (loop $label$2
     (block $label$3
      (block $label$4
       (br_if $label$4
        (i32.eqz
         (tee_local $4
          (i32.and
           (i32.xor
            (tee_local $3
             (i32.shr_u
              (get_local $s)
              (i32.add
               (get_local $i)
               (i32.const 1)
              )
             )
            )
            (i32.shr_u
             (get_local $s)
             (get_local $i)
            )
           )
           (i32.const 1)
          )
         )
        )
       )
       (set_local $temp
        (get_local $x)
       )
       (br $label$3)
      )
      (set_local $temp
       (i32.xor
        (get_local $y)
        (tee_local $5
         (i32.sub
          (i32.const 0)
          (i32.and
           (get_local $3)
           (i32.const 1)
          )
         )
        )
       )
      )
      (set_local $y
       (i32.xor
        (get_local $x)
        (get_local $5)
       )
      )
     )
     (set_local $x
      (i32.or
       (i32.shr_u
        (get_local $temp)
        (i32.const 1)
       )
       (i32.shl
        (get_local $4)
        (i32.const 31)
       )
      )
     )
     (set_local $y
      (i32.or
       (i32.shr_u
        (get_local $y)
        (i32.const 1)
       )
       (i32.shl
        (get_local $3)
        (i32.const 31)
       )
      )
     )
     (br_if $label$2
      (i32.lt_s
       (tee_local $i
        (i32.add
         (get_local $i)
         (i32.const 2)
        )
       )
       (get_local $2)
      )
     )
     (br $label$0)
    )
   )
  )
   (i32.shr_u
    (get_local $x)
    (tee_local $i
     (i32.sub
      (i32.const 32)
      (get_local $n)
     )
    )
   )
   local.set $outx
   (i32.shr_u
    (get_local $y)
    (get_local $i)
   )
   local.set $outy

   ;;Output swap order and extend to i64
   local.get $outy
   i64.extend_i32_s
   local.get $outx
   i64.extend_i32_s
 )
 
  
  ;;(export "xyToMemoryOffset" (func $xyToMemoryOffset))
  (func $xyToMemoryOffset (param $x i64) (param $y i64) (result i64)
    ;;Multiply y coordinate by width of image (4096)
    local.get $y
    i64.const 4096
    i64.mul
    ;;Add our x coordinate
    local.get $x
    i64.add
    ;;Multiply by 4 (RGBA)
    i64.const 4
    i64.mul
  )

  ;;(export "decrementMemoryOffset" (func $decrementMemoryOffset))
  (func $decrementMemoryOffset (param $offset64 i64)
    ;;Convert offset64 to offset32
    (local $offset32 i32)
    (local $basecolor i32)
    local.get  $offset64
    i32.wrap_i64
    local.set $offset32
    ;;Define Base color
    ;; (255, 0, 0, 255) (R, B, G, A) (Int32 -16776961)
    ;; (255, 0, 0, 0) (R, B, G, A) (Int32 255)
    i32.const -16777216
    local.set $basecolor
    ;;Check if pixel is initialized
    (block $initializePixel
      local.get  $offset32
      ;;Load 4 bytes at offset as i32
      i32.load
      i32.const 0
      i32.ne
      ;;Branch out of block if value is not equal to zero (uninitialized)
      br_if $initializePixel
      local.get $offset32
      ;; (255, 0, 0, 255) (R, B, G, A) (Int32 -16776961)
      local.get $basecolor
      i32.store
    )

    ;;Load offset into stack
    local.get  $offset32
    ;;Load i32 at offset
    local.get  $offset32
    ;;Load 4 bytes at offset as i32
    i32.load
    ;;Shift Alpha down (make pixel darker)
    ;;i32 is Little Endian
    ;;256^3
    i32.const 130560
    i32.add
    ;;Store new i32 at offset
    i32.store
  )

)