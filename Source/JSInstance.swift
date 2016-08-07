import Foundation
import JavaScriptCore

protocol JSInstance: JSThis {
    func bind(_ object: AnyObject)
    func unbind(_ object: AnyObject)
}

extension JSValue: JSInstance {
    
    func bind(_ object: AnyObject) {
        bindings.setObject(self, forKey: object)
    }
    
    func unbind(_ object: AnyObject) {
        bindings.removeObject(forKey: object)
    }
}

extension JSContext {
    var globalObject: JSInstance {
        get {
            return JSValue(self, ref: JSContextGetGlobalObject(self.ref))
        }
    }
    
    func eval(_ path: String) throws -> JSInstance {
        try eval(path) as Void;
        return globalObject
    }
}

protocol JSClass: JSThis {
    func construct(_ args: JSValue...) throws -> JSInstance
}

extension JSValue: JSClass {
    func construct(_ args: JSValue...) throws -> JSInstance {
        return JSValue(context, ref: try context.invoke {
            JSObjectCallAsConstructor(self.context.ref, self.ref, args.count, args.map({ $0.ref}), &$0)
        })
    }
}

