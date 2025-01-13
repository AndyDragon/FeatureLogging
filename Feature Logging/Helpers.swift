//
//  Helpers.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import Combine
import CommonCrypto
import SwiftUI

extension Binding where Value: Equatable {
    @discardableResult func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                if self.wrappedValue != newValue {
                    self.wrappedValue = newValue
                    handler(newValue)
                }
            }
        )
    }
}

extension View {
    @ViewBuilder func onValueChanged<T: Equatable>(value: T, onChange: @escaping (T) -> Void) -> some View {
        if #available(macOS 14.0, *) {
            self.onChange(of: value) { oldValue, newValue in
                onChange(newValue)
            }
        } else {
            self.onReceive(Just(value)) { (value) in
                onChange(value)
            }
        }
    }
}

func ?? <T>(lhs: Binding<T?>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}

func matches(of regex: String, in text: String) -> [String] {
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(
            in: text,
            range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    } catch let error {
        debugPrint("invalid regex: \(error.localizedDescription)")
        return []
    }
}

extension Locale {
    static var preferredLanguageCode: String {
        guard let preferredLanguage = preferredLanguages.first,
            let code = Locale(identifier: preferredLanguage).language.languageCode?.identifier
        else {
            return "en"
        }
        return code
    }

    static var preferredLanguageCodes: [String] {
        return Locale.preferredLanguages.compactMap({ Locale(identifier: $0).language.languageCode?.identifier })
    }
}

extension URLSession {
    func decode<T: Decodable>(
        _ type: T.Type = T.self,
        from url: URL,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
        dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .deferredToData,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate
    ) async throws -> T {
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 120.0)
        let (data, _) = try await data(for: request)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy
        decoder.dataDecodingStrategy = dataDecodingStrategy
        decoder.dateDecodingStrategy = dateDecodingStrategy

        let decoded = try decoder.decode(T.self, from: data)
        return decoded
    }

    func dataTask(
        with request: MultipartFormDataRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        return dataTask(with: request.asURLRequest(), completionHandler: completionHandler)
    }
}

extension NSMutableData {
    func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}

func copyToClipboard(_ text: String) {
    let pasteBoard = NSPasteboard.general
    pasteBoard.clearContents()
    pasteBoard.writeObjects([text as NSString])
}

func stringFromClipboard() -> String {
    let pasteBoard = NSPasteboard.general
    return pasteBoard.string(forType: .string) ?? ""
}

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    var releaseVersionNumberPretty: String {
        return "\(releaseVersionNumber ?? "1.0").\(buildVersionNumber ?? "0")"
    }
    func releaseVersionOlder(than: String) -> Bool {
        return releaseVersionNumberPretty.compare(than, options: .numeric) == .orderedAscending
    }
    var displayName: String? {
        return infoDictionary?["CFBundleDisplayName"] as? String ?? infoDictionary?["CFBundleName"] as? String
    }
}

@resultBuilder
public struct StringBuilder {
    public static func buildBlock(_ components: String...) -> String {
        return components.reduce("", +)
    }
}

extension String {
    public init(@StringBuilder _ builder: () -> String) {
        self.init(builder())
    }

    public func timestamp() -> Date? {
        let dateParserFormatter = DateFormatter()
        dateParserFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"
        dateParserFormatter.timeZone = .gmt
        return dateParserFormatter.date(from: self)
    }

    public func removeExtraSpaces(includeNewlines: Bool = true) -> String {
        if (includeNewlines) {
            return self.replacingOccurrences(of: "[\\s]+", with: " ", options: .regularExpression)
        }
        return self.split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "[\\s]+", with: " ", options: .regularExpression) }
            .joined(separator: "\n")
    }

    static func * (str: String, repeatTimes: Int) -> String {
        return String(repeating: str, count: repeatTimes)
    }
}

extension Double {
    public func formatUsingPrecision(_ precision: Int) -> String {
        return String(format: "%.\(precision)f", self)
    }
}

extension Date? {
    public func formatTimestamp() -> String {
        if let date = self {
            let distance = -date.timeIntervalSinceNow
            let days = floor(distance / (24 * 60 * 60))
            if days <= 1 {
                let hours = floor(distance / (60 * 60))
                return "\(hours.formatUsingPrecision(0))h"
            } else if days <= 7 {
                return "\(days.formatUsingPrecision(0))d"
            }
            let components = Calendar.current.dateComponents([.year], from: date)
            let componentsNow = Calendar.current.dateComponents([.year], from: Date.now)
            let dateFormatter = DateFormatter()
            if components.year == componentsNow.year {
                dateFormatter.dateFormat = "MMM d"
            } else {
                dateFormatter.dateFormat = "MMM d, yyyy"
            }
            return dateFormatter.string(from: date)
        }
        return "-"
    }
}

extension [String] {
    func includes(_ element: String) -> Bool {
        return self.contains(where: { item in item == element })
    }

    func includesWithoutCase(_ element: String) -> Bool {
        return self.contains(where: { item in item.lowercased() == element.lowercased() })
    }
}

extension String {
    func sha256() -> Data {
        let data = self.data(using: .utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data!.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data!.count), &hash)
        }
        return Data(hash)
    }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let hexDigits = options.contains(.upperCase) ? "0123456789ABCDEF" : "0123456789abcdef"
        if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
            let utf8Digits = Array(hexDigits.utf8)
            return String(unsafeUninitializedCapacity: 2 * self.count) { (ptr) -> Int in
                var p = ptr.baseAddress!
                for byte in self {
                    p[0] = utf8Digits[Int(byte / 16)]
                    p[1] = utf8Digits[Int(byte % 16)]
                    p += 2
                }
                return 2 * self.count
            }
        } else {
            let utf16Digits = Array(hexDigits.utf16)
            var chars: [unichar] = []
            chars.reserveCapacity(2 * self.count)
            for byte in self {
                chars.append(utf16Digits[Int(byte / 16)])
                chars.append(utf16Digits[Int(byte % 16)])
            }
            return String(utf16CodeUnits: chars, count: chars.count)
        }
    }
}

extension URL {
    var lastPathComponentWithoutExtension: String {
        return String(NSString(string: self.lastPathComponent).deletingPathExtension)
    }
}

extension NSImage {
    var pixelSize: NSSize? {
        if let rep = self.representations.first {
            let size = NSSize(width: rep.pixelsWide, height: rep.pixelsHigh)
            return size
        }
        return nil
    }
}

enum Direction {
    case first, previous, same, next, last
}

func directionFromModifiers(_ keyPress: KeyPress, horizontal: Bool = false) -> Direction {
    let maskedModifiers = keyPress.modifiers.rawValue &
    (EventModifiers.shift.rawValue | EventModifiers.control.rawValue | EventModifiers.option.rawValue | EventModifiers.command.rawValue);
    if (keyPress.key == .downArrow && !horizontal) || (keyPress.key == .rightArrow && horizontal) {
        if maskedModifiers == EventModifiers.command.rawValue {
            return .last
        }
        if maskedModifiers == 0 {
            return .next
        }
    } else if (keyPress.key == .upArrow && !horizontal) || (keyPress.key == .leftArrow && horizontal) {
        if maskedModifiers == EventModifiers.command.rawValue {
            return .first
        }
        if maskedModifiers == 0 {
            return .previous
        }
    }
    return .same
}

func navigateGeneric<T>(_ values: [T], _ selected: T, _ direction: Direction, allowWrap: Bool = true) -> (change: Bool, newValue: T) where T: Equatable {
    let count = values.count
    if count != 0 {
        if direction == .last {
            return (true, values.last!)
        }
        if direction == .next {
            if let current = values.firstIndex(where: { $0 == selected }) {
                if !allowWrap && current == (count - 1) {
                    return (false, selected)
                }
                return (true, values[(current + 1) % count])
            } else {
                return (true, values.first!)
            }
        }
        if direction == .previous {
            if let current = values.firstIndex(where: { $0 == selected }) {
                if !allowWrap && current == 0 {
                    return (false, selected)
                }
                return (true, values[(current - 1 + count) % count])
            } else {
                return (true, values.last!)
            }
        }
        if direction == .first {
            return (true, values.first!)
        }
        return (true, selected)
    }
    return (false, selected)
}

func navigateGenericWithPrefix(_ values: [String], _ selected: String, _ lowercasePrefix: String) -> (change: Bool, newValue: String) {
    let current = values.firstIndex(where: { selected == $0 })
    if let current {
        if let nextMatch = values[(current + 1)..<values.count].first(where: { $0.lowercased().hasPrefix(lowercasePrefix) }) {
            return (nextMatch != selected, nextMatch)
        } else {
            if let firstMatch = values.first(where: { $0.lowercased().hasPrefix(lowercasePrefix) }) {
                return (firstMatch != selected, firstMatch)
            }
        }
    } else {
        if let firstMatch = values.first(where: { $0.lowercased().hasPrefix(lowercasePrefix) }) {
            return (firstMatch != selected, firstMatch)
        }
    }
    return (false, selected)
}

func navigateGenericWithPrefix<T: RawRepresentable<String>>(_ values: [T], _ selected: T, _ lowercasePrefix: String) -> (change: Bool, newValue: T) {
    let current = values.firstIndex(where: { selected == $0 })
    if let current {
        if let nextMatch = values[(current + 1)..<values.count].first(where: { $0.rawValue.lowercased().hasPrefix(lowercasePrefix) }) {
            return (nextMatch != selected, nextMatch)
        } else {
            if let firstMatch = values.first(where: { $0.rawValue.lowercased().hasPrefix(lowercasePrefix) }) {
                return (firstMatch != selected, firstMatch)
            }
        }
    } else {
        if let firstMatch = values.first(where: { $0.rawValue.lowercased().hasPrefix(lowercasePrefix) }) {
            return (firstMatch != selected, firstMatch)
        }
    }
    return (false, selected)
}

extension FileManager {
    func temporaryFileURL(fileName: String = UUID().uuidString) -> URL? {
        return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(fileName)
    }
}

struct MultipartFormDataRequest {
    private let boundary: String = UUID().uuidString
    var httpBody = NSMutableData()
    var headers = [String:String]()
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    func addTextField(named name: String, value: String) {
        httpBody.appendString(textFormField(named: name, value: value))
    }
    
    private func textFormField(named name: String, value: String) -> String {
        var fieldString = "--\(boundary)\r\n"
        fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        fieldString += "Content-Type: text/plain; charset=ISO-8859-1\r\n"
        fieldString += "Content-Transfer-Encoding: 8bit\r\n"
        fieldString += "\r\n"
        fieldString += "\(value)\r\n"
        
        return fieldString
    }
    
    func addDataField(fieldName: String, fieldValue: String) {
        httpBody.append(dataFormField(fieldName: fieldName, fieldValue: fieldValue))
    }
    
    private func dataFormField(fieldName: String, fieldValue: String) -> Data {
        let fieldData = NSMutableData()
        fieldData.appendString("--\(boundary)\r\n")
        fieldData.appendString("Content-Disposition: form-data; name=\"\(fieldName)\"\r\n")
        fieldData.appendString("\r\n")
        fieldData.appendString(fieldValue)
        fieldData.appendString("\r\n")
        return fieldData as Data
    }
    
    mutating func addHeader(header: String, value: String) {
        headers[header] = value
    }
    
    func asURLRequest() -> URLRequest {
        var request = URLRequest(url: url)
        for header in headers {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        httpBody.appendString("--\(boundary)--")
        request.httpBody = httpBody as Data
        return request
    }
}

struct RuntimeError: LocalizedError {
    let description: String

    init(_ description: String) {
        self.description = description
    }

    var errorDescription: String? {
        description
    }
}

public extension Color {
    static func random(opacity: Double = 0.4) -> Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            opacity: opacity
        )
    }
}

extension View {

    func testListRowBackground() -> some View {
#if DEBUG_BACKGROUNDS
        self.listRowBackground(Color.random())
#else
        self
#endif
    }

    func testBackground() -> some View {
#if DEBUG_BACKGROUNDS
        self.background(Color.random())
#else
        self
#endif
    }

    func testAnimatedBackground() -> some View {
#if DEBUG_BACKGROUNDS
        self.modifier(AnimatedBackground())
#else
        self
#endif
    }
}

struct AnimatedBackground: ViewModifier {
    @State private var isVisible: Bool = false
    let linewidth: CGFloat = 5

    func body(content: Content) -> some View {
        content
            .overlay(content: {
                Rectangle()
                    .trim(from: isVisible ? 1 : 0, to: 1)
                    .stroke(Color.red, lineWidth: linewidth)
                    .padding(linewidth)

                Rectangle()
                    .trim(from: isVisible ? 1 : 0, to: 1)
                    .stroke(Color.blue, lineWidth: linewidth)
                    .rotationEffect(.degrees(180))
            })
            .onAppear(perform: {
                withAnimation(.linear(duration: 1)) {
                    isVisible = true
                }
            })
    }
}
