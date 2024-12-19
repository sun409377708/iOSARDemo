import Foundation

enum UrineRoutineItem: String {
    case gravity = "尿比重"
    case ph = "尿酸碱度"
    case leukocytes = "尿白细胞"
    case protein = "尿蛋白"
    case glucose = "尿糖"
    case ketone = "尿酮体"
    case urobilinogen = "尿胆原"
    case bilirubin = "尿胆红素"
    case blood = "尿隐血"
    case nitrite = "尿亚硝酸盐"
    case color = "尿颜色"
    case clarity = "尿透明度"
    case sediment = "尿沉渣"
    
    // 获取缩写
    var abbreviation: String {
        switch self {
        case .leukocytes: return "LEU"
        case .protein: return "PRO"
        case .glucose: return "GLU"
        case .ketone: return "KET"
        case .urobilinogen: return "URO"
        case .bilirubin: return "BIL"
        case .blood: return "BLD"
        case .nitrite: return "NIT"
        default: return ""
        }
    }
}

struct UrineRoutineResult {
    let item: UrineRoutineItem
    let value: String
    let unit: String
    let referenceRange: String
    let hint: String
    
    static func parse(from text: String) -> [UrineRoutineResult] {
        var results: [UrineRoutineResult] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            for item in UrineRoutineItem.allCases {
                if line.contains(item.rawValue) {
                    // 提取数值
                    var value = ""
                    var unit = ""
                    var reference = ""
                    var hint = ""
                    
                    // 解析值和单位
                    if let numericValue = extractNumericValue(from: line) {
                        value = numericValue
                    } else if line.contains("阴性") {
                        value = "阴性"
                    } else if line.contains("阳性") {
                        value = "阳性"
                    }
                    
                    // 解析参考范围
                    if let range = extractReferenceRange(from: line) {
                        reference = range
                    }
                    
                    // 解析提示信息
                    if line.contains("偏高") {
                        hint = "偏高"
                    } else if line.contains("偏低") {
                        hint = "偏低"
                    } else {
                        hint = "正常"
                    }
                    
                    let result = UrineRoutineResult(
                        item: item,
                        value: value,
                        unit: unit,
                        referenceRange: reference,
                        hint: hint
                    )
                    results.append(result)
                }
            }
        }
        
        return results
    }
    
    private static func extractNumericValue(from text: String) -> String? {
        let pattern = "\\d+(\\.\\d+)?"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(text.startIndex..., in: text)
        
        if let match = regex?.firstMatch(in: text, options: [], range: range),
           let range = Range(match.range, in: text) {
            return String(text[range])
        }
        return nil
    }
    
    private static func extractReferenceRange(from text: String) -> String? {
        // 匹配形如 "1.005-1.030" 的范围
        let pattern = "\\d+(\\.\\d+)?\\s*-\\s*\\d+(\\.\\d+)?"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(text.startIndex..., in: text)
        
        if let match = regex?.firstMatch(in: text, options: [], range: range),
           let range = Range(match.range, in: text) {
            return String(text[range])
        }
        return nil
    }
}

extension UrineRoutineItem: CaseIterable {}
