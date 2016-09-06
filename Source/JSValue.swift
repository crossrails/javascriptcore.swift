import Foundation
import JavaScriptCore

extension JSType: CustomStringConvertible {
    public var description: String {
        switch self {
        case kJSTypeNull:
            return "Null"
        case kJSTypeNumber:
            return "Number"
        case kJSTypeObject:
            return "Object"
        case kJSTypeString:
            return "String"
        case kJSTypeBoolean:
            return "Boolean"
        case kJSTypeUndefined:
            return "Undefined"
        default:
            return "Unknown"
        }
    }
}

class JSValue: CustomStringConvertible {
    
    let ref: JSValueRef
    let context: JSContext
    
    init(_ context: JSContext, ref: JSValueRef!) {
        self.ref = ref
        self.context = context
    }
    
    var description: String {
        return String(context, ref: ref)
    }
    
    subscript(property: JSProperty) -> JSValue {
        get {
            let value = try! context.invoke {
                JSObjectGetProperty(self.context.ref, self.ref, property.ref, &$0)
            }
            return JSValue(context, ref: value)
        }
        set(newValue) {
            try! context.invoke {
                JSObjectSetProperty(self.context.ref, self.ref, property.ref, newValue.ref, UInt32(kJSPropertyAttributeNone), &$0)
            }
        }
    }
    
    subscript(index: UInt32) -> JSValue {
        get {
            let value = try! context.invoke {
                JSObjectGetPropertyAtIndex(self.context.ref, self.ref, index, &$0)
            }
            return JSValue(context, ref: value)
        }
        set(newValue) {
            try! context.invoke {
                JSObjectSetPropertyAtIndex(self.context.ref, self.ref, index, newValue.ref, &$0)
            }
        }
    }
    
    func infer() -> Any {
        switch JSValueGetType(context.ref, ref) {
        case kJSTypeNumber:
            return Double(self)
        case kJSTypeObject:
            return JSAnyObject(self)
        case kJSTypeString:
            return String(self)
        case kJSTypeBoolean:
            return Bool(self)
        default:
            fatalError("Unknown type encounted: \(JSValueGetType(context.ref, ref))")
        }
    }
}

class JSAnyObject {
    
    let this: JSValue;
    
    init(_ instance: JSValue) {
        this = instance
        this.bind(self)
    }
    
    deinit {
        this.unbind(self)
    }
    
}

extension String {
    init(_ context: JSContext, ref: JSValueRef) {
        self = JSStringCopyCFString(nil, try! context.invoke {
            JSValueToStringCopy(context.ref, ref, &$0)
            }) as String
    }
}

extension Bool {
    init(_ value: JSValue) {
        assert(JSValueIsBoolean(value.context.ref, value.ref), "\(kJSTypeBoolean) expected but got \(JSValueGetType(value.context.ref, value.ref)): \(String(value.context, ref: value.ref))")
        self = JSValueToBoolean(value.context.ref, value.ref)
    }
}

extension Double {
    init(_ value: JSValue) {
        assert(JSValueIsNumber(value.context.ref, value.ref), "\(kJSTypeNumber) expected but got \(JSValueGetType(value.context.ref, value.ref)): \(String(value.context, ref: value.ref))")
        self = try! value.context.invoke {
            JSValueToNumber(value.context.ref, value.ref, &$0)
        }
    }
}

extension UInt32 {
    init(_ value: JSValue) {
        self = UInt32(Double(value))
    }
}

extension String {
    init(_ value: JSValue) {
        assert(JSValueIsString(value.context.ref, value.ref), "\(kJSTypeString) expected but got \(JSValueGetType(value.context.ref, value.ref)): \(String(value.context, ref: value.ref))")
        self.init(value.context, ref: value.ref)
    }
}

extension Optional {
    init(_ value: JSValue, wrapped:@noescape(JSValue) -> Wrapped) {
        self = JSValueIsNull(value.context.ref, value.ref) || JSValueIsUndefined(value.context.ref, value.ref) ? .none : wrapped(value)
    }
}

extension Array {
    init(_ value: JSValue, element:@noescape(JSValue) -> Element) {
        if #available(OSX 10.11, *) {
            assert(JSValueIsArray(value.context.ref, value.ref), "Array expected but got \(JSValueGetType(value.context.ref, value.ref)): \(String(value.context, ref: value.ref))")
        }
        self = [Element]()
        let count = UInt32(value[length])
        for index in 0..<count {
            self.append(element(value[index]))
        }
    }
}
