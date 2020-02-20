# Fuzzilli-WASM
A (coverage-)guided fuzzer for dynamic language interpreters based on [Fuzzilli](https://github.com/googleprojectzero/fuzzilli)

## WASM Features
#### [Global](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WebAssembly/Global)

- [x] globalwasm 
	- [x] var globalwasm = new WebAssembly.Global(GlobalParameters)

- [x] WasmTypeInt 
	- [x] "i32"
	- [x] "i64"

- [x] WasmTypeFloat 
	- [x] "f32"
	- [x] "f64"

- [x] GlobalDescriptorFloat 
	- [x] {value: WasmTypeFloat, mutable: common:bool}

- [x] GlobalDescriptorInt 
	- [x] {value: WasmTypeInt, mutable: common:bool}

- [x] GlobalParameters 
	- [x] GlobalDescriptorFloat, common:decimal_number
	- [x] GlobalDescriptorInt, common:integer

- [x] GlobalWasmMethods 
	- [x] globalwasm.value = number;
	- [x] globalwasm.value = common:number;
	- [x] number = globalwasm.value;
	- [x] number = globalwasm.valueOf();
	- [x] string = globalwasm.toString();


#### [Module](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WebAssembly/Module)

- [x] modulewasm 
	- [x] var  modulewasm = new WebAssembly.Module(bufferSource); 

- [x] bufferSource  
	- [x] new Uint8Array([0,97,115,109,1,0,0,0,1,133,128,128,128,0,1,96,0,1,127,3,130,128,128,128,0,1,0,4,132,128,128,128,0,1,112,0,0,5,131,128,128,128,0,1,0,1,6,129,128,128,128,0,0,7,145,128,128,128,0,2,6,109,101,109,111,114,121,2,0,4,109,97,105,110,0,0,10,138,128,128,128,0,1,132,128,128,128,0,0,65,42,11])

- [x] SectionName 
	- [x] "name"
	- [x] ""
	- [x] "debug"

- [x] ModuleWasmMethods 
	- [x] array = WebAssembly.Module.customSections(modulewasm, SectionName);
	- [x] array = WebAssembly.Module.customSections(modulewasm, string);
	- [x] array = WebAssembly.Module.exports(modulewasm);
	- [ ] string = WebAssembly.Module.exports(modulewasm).toString();
	- [x] array = WebAssembly.Module.imports(modulewasm);
	- [ ] string = WebAssembly.Module.imports(modulewasm).toString();
	- [x] modulewasm = new WebAssembly.Module(bufferSource);
 

#### [Memory](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WebAssembly/Memory)

- [x] memorywasm 
    - [x] var memorywasm = new WebAssembly.Memory(memoryDescriptor)


- [x] memoryDescriptor 
	- [x] {initial: range(0-9)}
	- [x] {initial: range(0-9), maximum: range(9-999)}

- [x] MemoryWasmMethods 
	- [x] number = memorywasm.buffer.length - 1;
	- [x] array = memorywasm.buffer;
	- [x] number = memorywasm.grow(number);
	- [x] number = memorywasm.grow(range(0-9));
	- [ ] memorywasm.buffer[range(0-9)] = range(0-9);
	- [ ] memorywasm.buffer[number] = range(0-9);
	- [ ] memorywasm.buffer[number] = number;


#### [Instance](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WebAssembly/Instance)

- [x] instancewasm 
	- [x] var instancewasm = new WebAssembly.Instance(modulewasm, importObject)

- [x] importObject 
	- [x] {}
	- [ ] { js: { globalwasm } }
	- [x] { js: { tbl: tablewasm } }
	- [x] { js: { mem: memorywasm } }

- [x] InstanceWasmMethods 
	- [x] instancewasm.exports.main();
	- [x] memorywasm = instancewasm.exports.memory;
	- [x] instancewasm = new WebAssembly.Instance(modulewasm, importObject);


#### [Table](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WebAssembly/Table)

- [x] tablewasm 
	- [x] var tablewasm = new WebAssembly.Table(TableDescriptor)

- [x] TableDescriptor 
	- [x] {element: "anyfunc", initial: range(0-42)}
	- [x] {element: "anyfunc", initial: range(0-42), maximum: range(43-99)}

- [x] TableWasmMethods 
	- [x] number = tablewasm.length - 1;
	- [x] funcRef = tablewasm.get(range(0-42));
	- [x] funcRef = tablewasm.get(number);
	- [x] number = tablewasm.grow(range(0-42));
	- [x] number = tablewasm.grow(number);
	- [x] tablewasm.set(range(0-42), funcRef);
	- [x] tablewasm.set(number, funcRef);
	
#### [Method](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/WebAssembly#Methods)

- [ ] WasmMethods 
	- [ ] bool = WebAssembly.validate(bufferSource);
	- [ ] WebAssembly.compile(bufferSource);

## TODO
- [ ] 完成 Feature 列表未完成部分
- [ ] bufferSource 的修改
- [ ] 逐步测试启用更多的生成器
- [ ] 进一步优化变异策略