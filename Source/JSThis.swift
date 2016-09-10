import Foundation
import JavaScriptCore

protocol JSThis: class {
    
    var ref: JSObjectRef { get }
    
    var context: JSContext { get }
    
    subscript(property: JSProperty) -> JSValue { get set }
    
    subscript(property: JSProperty) -> (_: JSValue...) throws -> (JSValue) { get }
    
    func valueOf(_ value: Bool) -> JSValue
    
    func valueOf(_ value: Double) -> JSValue
    
    func valueOf(_ value: String) -> JSValue
    
    func valueOf<Wrapped>(_ value: Optional<Wrapped>, wrapped: (Wrapped) -> JSValue) -> JSValue
    
    func valueOf<Element>(_ value: Array<Element>, element: (Element) -> JSValue) -> JSValue
    
    func valueOf(_ object: AnyObject) -> JSValue
    
    func valueOf(_ object: AnyObject, with eval: (JSContext) -> (JSValue)) -> JSValue
    
    func valueOf(_ value: Any?) -> JSValue
}

extension JSValue: JSThis {
    
    subscript(property: JSProperty) -> (_: JSValue...) throws -> (JSValue) {
        get {
            return { (args: JSValue...) -> JSValue in try self[property].call(self, args: args) }
        }
    }
    
    func valueOf(_ value: Bool) -> JSValue {
        return JSValue(context, ref: JSValueMakeBoolean(context.ref, value))
    }
    
    func valueOf(_ value: Double) -> JSValue {
        return JSValue(context, ref: JSValueMakeNumber(context.ref, value))
    }
    
    func valueOf(_ value: String) -> JSValue {
        let string = JSStringCreateWithUTF8CString(value)
        defer {
            JSStringRelease(string)
        }
        return JSValue(context, ref: JSValueMakeString(context.ref, string))
    }
    
    func valueOf<Wrapped>(_ value: Optional<Wrapped>, wrapped: (Wrapped) -> JSValue) -> JSValue {
        return value == nil ? JSValue(context, ref: JSValueMakeNull(context.ref)): wrapped(value!)
    }
    
    func valueOf<Element>(_ value: Array<Element>, element: (Element) -> JSValue) -> JSValue {
        return JSValue(context, ref: try! context.invoke {
            JSObjectMakeArray(self.context.ref, value.count, value.map({ element($0).ref }), &$0)
            })
    }
    
    func valueOf(_ object: AnyObject) -> JSValue {
        return bindings.object(forKey: object)!
    }
    
    func valueOf<T: AnyObject>(_ object: T, with eval: (JSContext) -> (JSValue)) -> JSValue {
        let value: JSValue? = bindings.object(forKey: object)
        return value ?? eval(context)
    }
    
    func valueOf(_ value: Any?) -> JSValue {
        switch value {
        case nil:
            return JSValue(context, ref: JSValueMakeNull(context.ref))
        case let bool as Bool:
            return self.valueOf(bool)
        case let double as Double:
            return self.valueOf(double)
        case let string as String:
            return self.valueOf(string)
        case let object as JSAnyObject:
            return object.this
        case let object as AnyObject:
            return JSObject(context, wrap: object)
        default:
            fatalError("Uknown type: \(value)")
        }
    }
    
}

