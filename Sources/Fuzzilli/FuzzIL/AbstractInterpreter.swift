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

/// Analyzes the types of variables.
public struct AbstractInterpreter {
    // States are kept in a stack to support conditional execution.
    private var ifStack: [VariableMap<Type>] = []
    private var stack: [VariableMap<Type>] = [VariableMap<Type>()]
    private var ifList: [Int] = [] // 1 means single if; 2 means if-else
    
    // The currently active state.
    private var currentState: VariableMap<Type> {
        return stack.last!
    }
    
    // Program-wide property and method types.
    private var propertyTypes = [String: Type]()
    private var methodSignatures = [String: FunctionSignature]()
    
    // The environment model from which to obtain various pieces of type information.
    private let environment: Environment
    
    init(for fuzzer: Fuzzer) {
        self.environment = fuzzer.environment
    }
    
    /// Abstractly execute the given instruction, thus updating type information.
    public mutating func execute(_ instr: Instruction) {
        switch instr.operation {
        case is BeginFunctionDefinition:
            stack.append(currentState)
        case is EndFunctionDefinition:
            let functionState = stack.removeLast()
            let previousState = stack.removeLast()
            stack.append(merge(functionState, previousState))
        case is BeginIf:
            stack.append(currentState)
            ifList.append(1)
        case is BeginElse:
            ifStack.append(stack.removeLast())
            ifList[ifList.count-1] = 2
        case is EndIf:
            if ( ifList.removeLast() > 1) {
                let ifState = ifStack.removeLast()
                let elseState = stack.removeLast()
                stack.append(merge(ifState, elseState))
            } else {
                stack.append(merge(stack.removeLast(), stack.removeLast()))
            }
        case is BeginWhile:
            stack.append(currentState)
        case is EndWhile:
            let loopState = stack.removeLast()
            let previousState = stack.removeLast()
            stack.append(merge(loopState, previousState))
        case is BeginDoWhile:
            stack.append(currentState)
        case is EndDoWhile:
            let loopState = stack.removeLast()
            let previousState = stack.removeLast()
            stack.append(merge(loopState, previousState))
        case is BeginFor:
            stack.append(currentState)
        case is EndFor:
            let loopState = stack.removeLast()
            let previousState = stack.removeLast()
            stack.append(merge(loopState, previousState))
        case is BeginForIn:
            stack.append(currentState)
        case is EndForIn:
            let loopState = stack.removeLast()
            let previousState = stack.removeLast()
            stack.append(merge(loopState, previousState))
        case is BeginForOf:
            stack.append(currentState)
        case is EndForOf:
            let loopState = stack.removeLast()
            let previousState = stack.removeLast()
            stack.append(merge(loopState, previousState))
        case is BeginTry:
            // Ignored for now, TODO
            break
        case is BeginCatch:
            break
        case is EndTryCatch:
            break
        case is BeginWith:
            break
        case is EndWith:
            break
        default:
            assert(instr.isSimple)
        }

        executeEffects(instr)
    }


    /// Returns the type of the given variable as computed by this interpreter.
    /// Will return .unknown for variables not known to this interpreter.
    public func type(of variable: Variable) -> Type {
        return currentState[variable] ?? .unknown
    }
    
    /// Sets the type of the given variable.
    public mutating func setType(of variable: Variable, to type: Type) {
        set(variable, type)
    }
    
    
    /// Sets a program wide type for the given property.
    public mutating func setType(ofProperty propertyName: String, to type: Type) {
        propertyTypes[propertyName] = type
    }
    
    /// Sets a program wide signature for the given method name.
    public mutating func setSignature(ofMethod methodName: String, to signature: FunctionSignature) {
        methodSignatures[methodName] = signature
    }
    
    
    /// Attempts to infer the signature of the given method on the given object type.
    public func inferMethodSignature(of methodName: String, on object: Variable) -> FunctionSignature {
        // First check global property types.
        if let signature = methodSignatures[methodName] {
            return signature
        }
        
        // Then check well-known methods of this execution environment. return the registed signature
        return environment.signature(ofMethod: methodName, on: type(of: object))
    }
    
    /// Attempts to infer the type of the given property on the given object type.
    private func inferPropertyType(of propertyName: String, on object: Variable) -> Type {
        // First check global property types.
        if let type = propertyTypes[propertyName] {
            return type
        }
        
        // Then check well-known properties of this execution environment.
        return environment.type(ofProperty: propertyName, on: type(of: object))
    }
    
    /// Attempts to infer the return value type if the given method on the given object type.
    private func inferMethodReturnType(of methodName: String, on obj: Variable) -> Type {
        return inferMethodSignature(of: methodName, on: obj).outputType
    }
    
    /// Attempts to infer the constructed type of the given constructor.
    private func inferConstructedType(of constructor: Variable) -> Type {
        if let signature = type(of: constructor).constructorSignature {

            return signature.outputType
        }
        
        return .object()
    }
    
    /// Attempts to infer the return value type of the given function.
    private func inferCallResultType(of function: Variable) -> Type {
        if let signature = type(of: function).functionSignature {
            return signature.outputType
        }
        
        return .unknown
    }
    
    /// Sets the type of the given variable in the current state.
    private mutating func set(_ v: Variable, _ t: Type) {
        stack[stack.count - 1][v] = t
    }
    
    /// Merge two states.
    private func merge(_ state1: VariableMap<Type>, _ state2: VariableMap<Type>) -> VariableMap<Type> {
        var result = state1
        for (i, t) in state2 {
            if let current = result[i] {
                result[i] = current | t
            } else {
                result[i] = t
            }
        }
        return result
    }
    
    private mutating func executeEffects(_ instr: Instruction) {
        switch instr.operation {
            
        case let op as LoadBuiltin:
            set(instr.output, environment.type(ofBuiltin: op.builtinName))
            
        case is LoadInteger:
            set(instr.output, environment.intType)
            
        case is LoadNumber:
            
            set(instr.output, environment.intType)
            
        case is LoadFloat:
            set(instr.output, environment.floatType)
            
        case is LoadString:
            set(instr.output, environment.stringType)
            
        case is LoadBoolean:
            set(instr.output, environment.booleanType)
            
        case is LoadUndefined:
            set(instr.output, .undefined)
            
        case is LoadNull:
            set(instr.output, .undefined)
            
        case let op as CreateObject:
            var properties: [String] = []
            var methods: [String] = []
            for (i, p) in op.propertyNames.enumerated() {
                if type(of: instr.input(i)).Is(.function()) {
                    methods.append(p)
                } else {
                    properties.append(p)
                }
            }
            set(instr.output, environment.objectType + .object(withProperties: properties, withMethods: methods))
            
        case let op as CreateObjectWithSpread:
            var properties: [String] = []
            var methods: [String] = []
            for (i, p) in op.propertyNames.enumerated() {
                if type(of: instr.input(i)).Is(.function()) {
                    methods.append(p)
                } else {
                    properties.append(p)
                }
            }
            for i in op.propertyNames.count..<instr.numInputs {
                let v = instr.input(i)
                properties.append(contentsOf: type(of: v).properties)
                methods.append(contentsOf: type(of: v).methods)
            }
            set(instr.output, environment.objectType + .object(withProperties: properties, withMethods: methods))
            
        case is CreateArray,
             is CreateArrayWithSpread:
            set(instr.output, environment.arrayType)
            
        case let op as StoreProperty:
            set(instr.input(0), type(of: instr.input(0)).adding(property: op.propertyName)) //?
            
        case let op as DeleteProperty:
            set(instr.input(0), type(of: instr.input(0)).removing(property: op.propertyName))
            
        case let op as LoadProperty:
            set(instr.output, inferPropertyType(of: op.propertyName, on: instr.input(0)))
            
        case is LoadElement,
             is LoadComputedProperty:
            set(instr.output, .unknown)
            
        case is CallFunction,
             is CallFunctionWithSpread:
            set(instr.output, inferCallResultType(of: instr.input(0)))
            
        case let op as CallMethod:
            
            set(instr.output, inferMethodReturnType(of: op.methodName, on: instr.input(0)))
            
        case is Construct:
            set(instr.output, inferConstructedType(of: instr.input(0)))
            
        case let op as UnaryOperation:
            switch op.op {
            case .Inc:
                set(instr.output, .primitive)
            case .Dec:
                set(instr.output, .primitive)
            case .LogicalNot:
                set(instr.output, .boolean)
            case .BitwiseNot:
                set(instr.output, .boolean)
            }
            
        case let op as BinaryOperation:
            switch op.op {
            case .Add:
                set(instr.output, .primitive)
            case .Sub,
                 .Mul,
                 .Div,
                 .Mod:
                set(instr.output, .number)
            case .BitAnd,
                 .BitOr,
                 .Xor,
                 .LShift,
                 .RShift:
                set(instr.output, .integer)
            case .LogicAnd,
                 .LogicOr:
                set(instr.output, .boolean)
            }
            
        case is TypeOf:
            set(instr.output, .string)
            
        case is InstanceOf:
            set(instr.output, .boolean)
            
        case is In:
            set(instr.output, .boolean)
            
        case is Phi:
            set(instr.output, .phi(of: type(of: instr.input(0))))
            
        case is Copy:
            set(instr.input(0), .phi(of: type(of: instr.input(1))))
            
        case is Compare:
            set(instr.output, .boolean)
            
        case is LoadFromScope:
            set(instr.output, .unknown)
            
        case let op as BeginFunctionDefinition:
            let signature = op.signature
            set(instr.output, .function(signature))
            for (i, param) in instr.innerOutputs.enumerated() {
                let paramType = signature.inputTypes[i]
                var varType = paramType
                if paramType == .anything {
                    varType = .unknown
                }
                if paramType.isList {
                    // Could also make it an array? Or fetch the type from the Environment
                    varType = .object()
                }
                set(param, varType)
            }
            
        case is BeginFor:
            // Primitive type is currently guaranteed due to the structure of for loops
            set(instr.innerOutput, .primitive)
            
        case is BeginForIn:
            set(instr.innerOutput, .string)
            
        case is BeginForOf:
            set(instr.innerOutput, .unknown)
            
        case is BeginCatch:
            set(instr.innerOutput, .unknown)
        
        //add the Alter opcode
        case let op as Alter:
            set(instr.output, environment.type(forTypeName: op.typeName))
        
        case is Const:
            set(instr.output, type(of: instr.input(0)))
            
        default:
            assert(!instr.hasOutput)
        }
        
        // Variables must not be .anything or .nothing. For variables that can be anything, .unknown is the correct type.
        assert(instr.allOutputs.allSatisfy({ type(of: $0) != .anything && type(of: $0) != .nothing }))
    }
}