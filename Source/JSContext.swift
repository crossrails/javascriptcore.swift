import Foundation
import JavaScriptCore

let bindings = NSMapTable<AnyObject, JSValue>(keyOptions: [.objectPointerPersonality, .weakMemory], valueOptions: [.objectPointerPersonality])

struct JSContext {
    
    let ref: JSContextRef
    
    init() {
        self.init(JSGlobalContextCreate(nil))
    }
    
    private init(_ ref: JSContextRef) {
        self.ref = ref
    }
    
    func eval(_ path: String) throws {
        let string = JSStringCreateWithCFString(try NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as CFString)
        let url = JSStringCreateWithCFString(path as CFString)
        defer {
            JSStringRelease(url)
            JSStringRelease(string)
        }
        _ = try self.invoke {
            JSEvaluateScript(self.ref, string, nil, url, 0, &$0)
        }
    }
    
    func invoke<T>( _ f: (_ exception: inout JSValueRef?) -> T) throws -> T {
        var exception: JSValueRef? = nil
        let result = f(&exception)
        if exception != nil {
            print("Exception thrown: \(String(self, ref: exception!))")
            throw JSError(JSValue(self, ref: exception!))
        }
        return result
    }
    
}

public struct JSError: Error, CustomStringConvertible {
    
    let exception: JSValue
    
    init(_ value: JSValue) {
        self.exception = value
    }
    
    public var description: String {
        return String(exception[message])
    }
}

private func cast(_ any: Any) -> JSValue? {
    if let value = bindings.object(forKey: any as AnyObject?) {
        return value
    }
    return nil
}

func == (lhs: Any, rhs: Any) -> Bool {
    if let left = cast(lhs) {
        if let right = cast(rhs) {
            return try! left.context.invoke({
                JSValueIsEqual(left.context.ref, left.ref, right.ref, &$0)
            })
        }
    }
    return false
}
