//
//  LogManager.swift
//  MediationAd
//
//  Created by Dev_iOS on 25/6/25.
//

import Foundation

class AdLogManager: @unchecked Sendable {
    static let shared = AdLogManager()
    
    func log(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
#if DEBUG
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMess = "[MediationAd] - [file: \(fileName)] - [func: \(function)] - [line: \(line)]"
        print(logMess, items, separator: " ", terminator: "\n")
#endif
    }
    
    func logTime(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
#if DEBUG
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let dateStr = formatter.string(from: Date())
        let logMess = "[MediationAd] - [file: \(fileName)] - [func: \(function)] - [line: \(line)] - [time: \(dateStr)]"
        print(logMess, items, separator: " ", terminator: "\n")
#endif
    }
}
