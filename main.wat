(module
  (export "runner" (func $runner))
  (func $runner (param $js i32) (result i32)
	  local.get $js
    i32.const 1
    i32.add
  )
)