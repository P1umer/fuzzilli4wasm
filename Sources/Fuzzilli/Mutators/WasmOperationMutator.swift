// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// A mutator that randomly mutates parameters of the Operations in the given program.
public class WasmOperationMutator: BaseInstructionMutator {
    public init() {
        super.init(maxSimultaneousMutations: 3)
    }
    
    override public func canMutate(_ instr: Instruction) -> Bool {
        return (instr.isParametric && instr.isMutable) || instr.operation is CallFunction
    }

    override public func mutate(_ instr: Instruction, _ b: ProgramBuilder) {
        var newOp = instr.operation
        
        switch instr.operation {
//        case is LoadInteger:
//            newOp = LoadInteger(value: b.genInt()) //need
        case is LoadNumber:
            newOp = LoadNumber(value: b.genInt())
        case is LoadFloat:
            newOp = LoadFloat(value: b.genFloat())
//        case is LoadString:
//            newOp = LoadString(value: b.genString())
        case let op as LoadBoolean:
            newOp = LoadBoolean(value: !op.value)
            
        case is LoadProperty:
            let object = b.adopt(instr.input(0))
            let propertyName = b.type(of: object).randomProperty() ?? b.genPropertyNameForRead()
            newOp = LoadProperty(propertyName: propertyName)
            
        case is StoreProperty:
            let object = b.adopt(instr.input(0))
            let propertyName = b.type(of: object).randomProperty() ?? b.genPropertyNameForWrite()
            newOp = StoreProperty(propertyName: propertyName)
            
        case is DeleteProperty:
            let object = b.adopt(instr.input(0))
            let propertyName = b.type(of: object).randomProperty() ?? b.genPropertyNameForRead()
            newOp = DeleteProperty(propertyName: propertyName)
        // ADD
        case is CallMethod:
            let object = b.adopt(instr.input(0))
            var objectType = b.type(of: object)
            let methodName = objectType.randomMethod() ?? b.genMethodName()
            let arguments:[Variable]

            switch objectType {
            case .GlobalWasmObject,
                 .MemoryWasmObject,
                 .InstanceWasmObject:
                arguments = b.generateCallArguments(forMethod: methodName, on: object)

            case .TableWasmObject:
                switch methodName {
                case "get":
                    arguments = [b.loadNumber(Int.random(in: 0...42))]
                case "grow":
                    arguments = [b.loadNumber(Int.random(in: 0...42))]
                default:
                    arguments = b.generateCallArguments(forMethod: methodName, on: object)
                }
            default:
                arguments = b.generateCallArguments(forMethod: methodName, on: object)
            }
            b.callMethod(methodName, on: object, withArgs: arguments)
            
        // ADD
        case is CallFunction:
            if instr.numInputs >= 2  {
                let object = b.adopt(instr.input(1))
                var objectType = b.type(of: object)

                switch objectType {
                case .ModuleWasmObject:
                    let methodName = objectType.randomMethod() ?? b.genMethodName()
                    let function = b.loadBuiltin(methodName)
                    let arguments:[Variable]

                    switch methodName {
                    case "WebAssembly.Module.customSections":
                        arguments = [object, b.loadString(chooseUniform(from: JavaScriptEnvironment.sectionName))]
                    case "WebAssembly.Module.exports":
                        arguments = [object]
                    case "WebAssembly.Module.imports":
                        arguments = [object]
                    default:
                        fatalError("No such method for Module")
                    }

                    b.callFunction(function, withArgs: arguments)
                default:
                    break
                }
            }else{
                break
            }
//
            
            
//        case is LoadElement:
//            newOp = LoadElement(index: b.genIndex())
//        case is StoreElement:
//            newOp = StoreElement(index: b.genIndex())
//        case is DeleteElement:
//            newOp = DeleteElement(index: b.genIndex())
//        case let op as CallMethod:
//            newOp = CallMethod(methodName: , numArguments: op.numArguments)
//        case let op as CallFunctionWithSpread:
//            var spreads = op.spreads
//            if spreads.count > 0 {
//                let idx = Int.random(in: 0..<spreads.count)
//                spreads[idx] = !spreads[idx]
//            }
//            newOp = CallFunctionWithSpread(numArguments: op.numArguments, spreads: spreads)
//        case is UnaryOperation:
//            newOp = UnaryOperation(chooseUniform(from: allUnaryOperators))
//        case is BinaryOperation:
//            newOp = BinaryOperation(chooseUniform(from: allBinaryOperators))
//        case is Compare:
//            newOp = Compare(chooseUniform(from: allComparators))
//        case is LoadFromScope:
//            newOp = LoadFromScope(id: b.genPropertyNameForRead())
//        case is StoreToScope:
//            newOp = StoreToScope(id: b.genPropertyNameForWrite())
        case is BeginWhile:
            newOp = BeginWhile(comparator: chooseUniform(from: allComparators))
        case is EndDoWhile:
            newOp = EndDoWhile(comparator: chooseUniform(from: allComparators))
        case let op as BeginFor:
            if probability(0.5) {
                newOp = BeginFor(comparator: chooseUniform(from: allComparators), op: op.op)
            } else {
                newOp = BeginFor(comparator: op.comparator, op: chooseUniform(from: allBinaryOperators))
            }
        default:
            break //fatalError("[WasmOperationMutator] Unhandled Operation: \(type(of: instr.operation))")
        }
                
        b.adopt(Instruction(operation: newOp, inouts: instr.inouts))
    }
}
