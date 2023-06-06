//
//  LoggerProxy.swift
//  LoggerProxy
//
//  Created by renwei on 2022/1/4.
//

//// 这是一个简单的日志代理工具，可以讲内部日志打印代理到外部

import Foundation

/// 延迟日志组装
public typealias AsyncLogMessage = () -> String

/// 日志标签
public typealias LogTag = String

/// 日志管理
public class LoggerProxy {
    public enum Level: Int32 {
        case Verbose = 0
        case Debug = 1
        case Info = 2
        case Warn = 3
        case Error = 4
        func desc() -> String {
            switch self {
            case .Verbose:
                return "V"
            case .Debug:
                return "D"
            case .Info:
                return "I"
            case .Warn:
                return "W"
            case .Error:
                return "E"
            }
        }
    }

    /// 日志输出函数
    public typealias LogFunc = (Level, Date /* time */, String /* module name */, StaticString /* file */, StaticString /* func */, Int /* line */, String /* label */, () -> String /* msg */ ) -> Void

    /// 共享日志对象
    public static let shared = LoggerProxy()

    /// 默认日期格式
    private static let iso8601DateFormatter = ISO8601DateFormatter()

    /// 默认控制台日志输出
    public static let defaultConsoleLogger: LogFunc = { level, now, module, file, funcName, line, tag, msg in
        let time = iso8601DateFormatter.string(from: now)
        let msg2 = msg().replacingOccurrences(of: "\n", with: "~n")
        print("\(time) [\(level.desc())] \(module):\(funcName):\(line) [\(tag)] \(msg2) ### \(file)")
    }

    /// 空白日志输出
    public static let defaultEmptyLogger: LogFunc = { _, _, _, _, _, _, _, _ in
    }

    /// 实际代理的日志输出
    public var logFunction: LogFunc

    /// 筛选日志等级
    public var acceptLevel: Level

    /// 异步日子队列
    private lazy var logQueue: DispatchQueue = {
        enum TypeInCurrentModule {}
        let moduleName = String(reflecting: TypeInCurrentModule.self)
            .split(separator: ".")[0]
        return DispatchQueue(label: "\(moduleName)-Logger")
    }()

    /// 是否启用异步日志输出
    public var enableAsync: Bool = false

    /// 日志等级详细控制
    /// 针对 logTag 控制
    public var logTagControl: Dictionary<LogTag, Level> = Dictionary()
    /// 针对 module 控制
    public var moduleLogControl: Dictionary<String, Level> = Dictionary()
    /// 针对 module中 LogTag控制
    public var moduleLogTagControl: Dictionary<String, Dictionary<LogTag, Level>> = Dictionary()

    /// 初始化日志代理
    public init() {
        #if DEBUG
            acceptLevel = Level.Verbose
            logFunction = LoggerProxy.defaultConsoleLogger
            enableAsync = false
        #else
            acceptLevel = Level.Warn
            logFunction = LoggerProxy.defaultEmptyLogger
            enableAsync = true
        #endif
    }

    /// 打印日志
    public func appendLog(level: Level, tag: String, msg: @escaping AsyncLogMessage, file: StaticString, funcName: StaticString, line: Int) {
        var specilControl = false
        // tag 控制
        if let tagLevel = logTagControl[tag] {
            if tagLevel.rawValue > level.rawValue {
                return
            } else {
                specilControl = true
            }
        }

        let module = file.withUTF8Buffer({ String(decoding: $0, as: UTF8.self).components(separatedBy: "/").first ?? "" })
        /// 模块控制
        if let moduleLevel = moduleLogControl[module] {
            if moduleLevel.rawValue > level.rawValue {
                return
            } else {
                specilControl = true
            }
        }

        /// 模块Tag控制
        if let moduleControl = moduleLogTagControl[module],
           let tagLevel = moduleControl[tag] {
            if tagLevel.rawValue > level.rawValue {
                return
            } else {
                specilControl = true
            }
        }
        // 通用控制
        if !specilControl,
           acceptLevel.rawValue > level.rawValue {
            return
        }

        let now = Date()
        let logFunc = logFunction
        if enableAsync {
            logQueue.async {
                logFunc(level, now, module, file, funcName, line, tag, msg)
            }
        } else {
            logFunc(level, now, module, file, funcName, line, tag, msg)
        }
    }
}

extension LoggerProxy {
    public static func VLog(tag: String, msg: @autoclosure @escaping AsyncLogMessage, file: StaticString = #fileID, funcName: StaticString = #function, line: Int = #line) {
        LoggerProxy.shared.appendLog(level: Level.Verbose, tag: tag, msg: msg, file: file, funcName: funcName, line: line)
    }

    public static func DLog(tag: String, msg: @autoclosure @escaping AsyncLogMessage, file: StaticString = #fileID, funcName: StaticString = #function, line: Int = #line) {
        LoggerProxy.shared.appendLog(level: Level.Debug, tag: tag, msg: msg, file: file, funcName: funcName, line: line)
    }

    public static func ILog(tag: String, msg: @autoclosure @escaping AsyncLogMessage, file: StaticString = #fileID, funcName: StaticString = #function, line: Int = #line) {
        LoggerProxy.shared.appendLog(level: Level.Info, tag: tag, msg: msg, file: file, funcName: funcName, line: line)
    }

    public static func WLog(tag: String, msg: @autoclosure @escaping AsyncLogMessage, file: StaticString = #fileID, funcName: StaticString = #function, line: Int = #line) {
        LoggerProxy.shared.appendLog(level: Level.Warn, tag: tag, msg: msg, file: file, funcName: funcName, line: line)
    }

    public static func ELog(tag: String, msg: @autoclosure @escaping AsyncLogMessage, file: StaticString = #fileID, funcName: StaticString = #function, line: Int = #line) {
        LoggerProxy.shared.appendLog(level: Level.Error, tag: tag, msg: msg, file: file, funcName: funcName, line: line)
    }
}
