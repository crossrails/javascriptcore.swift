import Foundation
import JavaScriptCore

let length: JSProperty = "length"
let message: JSProperty = "message"
let name: JSProperty = "name"
let Function: JSProperty = "Function"

struct JSProperty: CustomStringConvertible, StringLiteralConvertible {
    
    private let string: StringLiteralType
    let ref: JSStringRef
    
    init(unicodeScalarLiteral value: String) {
        self.string = value
        self.ref = JSStringCreateWithUTF8CString(value)
    }
    
    init(extendedGraphemeClusterLiteral value: String) {
        self.string = value
        self.ref = JSStringCreateWithUTF8CString(value)
    }
    
    init(stringLiteral value: StringLiteralType) {
        self.string = value
        self.ref = JSStringCreateWithUTF8CString(value)
    }
    
    var description: String {
        return string
    }
}
