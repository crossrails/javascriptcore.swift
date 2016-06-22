import Foundation
import JavaScriptCore

class JSObject : JSValue {
    
    private let object :AnyObject?
    private let callbacks: [String :([JSValue]) throws -> (JSValue?)]
    
    convenience init(_ context :JSContext, wrap object: AnyObject?) {
        self.init(context, object: object, callbacks: [:])
    }
    
    convenience init(_ context :JSContext, callback: ([JSValue]) throws -> (JSValue?)) {
        self.init(context, callbacks:["Function": callback])
        JSObjectSetPrototype(context.ref, self.ref, context.globalObject[Function].ref)
    }
    
    convenience init(_ context :JSContext, callbacks: [String :([JSValue]) throws -> (JSValue?)]) {
        self.init(context, object: nil, callbacks: callbacks)
    }
    
    convenience init(_ context :JSContext, prototype :JSThis, callbacks: [String :([JSValue]) throws -> (JSValue?)]) {
        self.init(context, object: nil, callbacks: callbacks)
        JSObjectSetPrototype(context.ref, JSObjectGetPrototype(context.ref, self.ref), prototype.ref)
    }
    
    private init(_ context :JSContext, object: AnyObject?, callbacks: [String :([JSValue]) throws -> (JSValue?)]) {
        self.object = object
        self.callbacks = callbacks
        var definition :JSClassDefinition = kJSClassDefinitionEmpty
        definition.finalize = {
            Unmanaged<JSObject>.fromOpaque(OpaquePointer(JSObjectGetPrivate($0))).release()
        }
        definition.callAsFunction = { (_, function, this, argCount, args, exception) -> JSValueRef? in
            let data = JSObjectGetPrivate(this)
            let object :JSObject = Unmanaged.fromOpaque(OpaquePointer((data == nil ? JSObjectGetPrivate(function) : data)!)).takeUnretainedValue()
            do {
                let value = JSValue(object.context, ref: function!)
                var arguments = [JSValue]()
                for index in 0..<argCount {
                    arguments.append(JSValue(object.context, ref: (args?[index]!)!))
                }
                let callback = object.callbacks[String(value[name])]!
                return try callback(arguments)?.ref ?? JSValueMakeUndefined(object.context.ref)
            } catch let error as Error {
                exception?.initialize(with: error.exception.ref)
            } catch let error as CustomStringConvertible {
                var value: JSValueRef? = nil
                var message: JSValueRef?  = object.valueOf(error.description).ref
                value = JSObjectMakeError(object.context.ref, 1, &message, &value)
                exception?.initialize(with: value)
            } catch {
                var value : JSValueRef? = nil
                value = JSObjectMakeError(object.context.ref, 0, nil, &value)
                exception?.initialize(with: value)
            }
            return JSValueMakeUndefined(object.context.ref)
        }
        var functions: [JSStaticFunction] = callbacks.keys.map({
            JSStaticFunction(name: ($0 as NSString).utf8String, callAsFunction: definition.callAsFunction, attributes: UInt32(kJSPropertyAttributeNone))
        })
        functions.append(JSStaticFunction(name: nil, callAsFunction: nil, attributes: 0))
        definition.staticFunctions = UnsafePointer<JSStaticFunction>(functions)
        let clazz = JSClassCreate(&definition)
        super.init(context, ref: JSObjectMake(context.ref, clazz, nil))
        assert(JSObjectSetPrivate(ref, UnsafeMutablePointer(OpaquePointer(bitPattern:Unmanaged.passRetained(self)))))
        JSClassRelease(clazz)
    }
    
    //    override func infer() -> Any? {
    //        return object ?? self
    //    }
}
