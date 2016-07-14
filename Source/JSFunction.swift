import Foundation
import JavaScriptCore

protocol JSFunction {
    func bind(_ object: AnyObject)
    func call(_ this :JSThis, args :JSValue...) throws -> JSValue
    func call(_ this :JSThis, args :[JSValue]) throws -> JSValue
}

extension JSValue : JSFunction {
    @discardableResult
    func call(_ this :JSThis, args :JSValue...) throws -> JSValue {
        return try self.call(this, args: args)
    }
    
    func call(_ this :JSThis, args :[JSValue]) throws -> JSValue {
        //        print("calling \(self) with \(args) on object \(this)")
        //        for arg in args {
        //            if(JSValueIsObject(context.ref, arg.ref)) {
        //                print("  Properties of arg \(arg)")
        //                let names = JSObjectCopyPropertyNames(context.ref, JSObjectGetPrototype(context.ref, arg.ref))
        //                for index in 0..<JSPropertyNameArrayGetCount(names) {
        //                    let name = JSPropertyNameArrayGetNameAtIndex(names, index)
        //                    print("  ...\(JSStringCopyCFString(nil, name))")
        //                }
        //            }
        //        }
        return try JSValue(self.context, ref: self.context.invoke {
            JSObjectCallAsFunction(self.context.ref, self.ref, this.ref, args.count, args.map({ $0.ref }), &$0)
        })
    }
}
