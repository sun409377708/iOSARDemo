import Foundation

// 血常规检查项目
enum BloodRoutineItem: String, Codable, CaseIterable {
    // 红细胞系统
    case rbc = "红细胞计数"
    case hgb = "血红蛋白"
    case hct = "红细胞压积"
    case mcv = "平均红细胞体积"
    case mch = "平均红细胞血红蛋白含量"
    case mchc = "平均红细胞血红蛋白浓度"
    case rdw = "红细胞分布宽度"
    
    // 白细胞系统
    case wbc = "白细胞计数"
    case neutrophils = "中性粒细胞百分比"
    case lymphocytes = "淋巴细胞百分比"
    case monocytes = "单核细胞百分比"
    case eosinophils = "嗜酸性粒细胞百分比"
    case basophils = "嗜碱性粒细胞百分比"
    case neutrophilsCount = "中性粒细胞计数"
    case lymphocytesCount = "淋巴细胞计数"
    case monocytesCount = "单核细胞计数"
    case eosinophilsCount = "嗜酸性粒细胞计数"
    case basophilsCount = "嗜碱性粒细胞计数"
    
    // 血小板系统
    case plt = "血小板计数"
    case mpv = "平均血小板体积"
    case pct = "血小板压积"
    case pdw = "血小板分布宽度"
    
    var abbreviation: String {
        switch self {
        case .rbc: return "RBC"
        case .hgb: return "HGB"
        case .hct: return "HCT"
        case .mcv: return "MCV"
        case .mch: return "MCH"
        case .mchc: return "MCHC"
        case .rdw: return "RDW"
        case .wbc: return "WBC"
        case .neutrophils: return "NEUT%"
        case .lymphocytes: return "LYMPH%"
        case .monocytes: return "MONO%"
        case .eosinophils: return "EO%"
        case .basophils: return "BASO%"
        case .neutrophilsCount: return "NEUT#"
        case .lymphocytesCount: return "LYMPH#"
        case .monocytesCount: return "MONO#"
        case .eosinophilsCount: return "EO#"
        case .basophilsCount: return "BASO#"
        case .plt: return "PLT"
        case .mpv: return "MPV"
        case .pct: return "PCT"
        case .pdw: return "PDW"
        }
    }
    
    var unit: String {
        switch self {
        case .rbc:
            return "10^12/L"
        case .hgb:
            return "g/L"
        case .hct:
            return "%"
        case .mcv:
            return "fL"
        case .mch:
            return "pg"
        case .mchc:
            return "g/L"
        case .rdw:
            return "%"
        case .wbc:
            return "10^9/L"
        case .neutrophils, .lymphocytes, .monocytes, .eosinophils, .basophils:
            return "%"
        case .neutrophilsCount, .lymphocytesCount, .monocytesCount, .eosinophilsCount, .basophilsCount:
            return "10^9/L"
        case .plt:
            return "10^9/L"
        case .mpv:
            return "fL"
        case .pct:
            return "%"
        case .pdw:
            return "%"
        }
    }
    
    var referenceRange: String {
        switch self {
        case .rbc:
            return "4.3-5.8"
        case .hgb:
            return "130-175"
        case .hct:
            return "40.0-50.0"
        case .mcv:
            return "82.0-100.0"
        case .mch:
            return "27.0-34.0"
        case .mchc:
            return "316-354"
        case .rdw:
            return "11.5-14.5"
        case .wbc:
            return "3.5-9.5"
        case .neutrophils:
            return "40.0-75.0"
        case .lymphocytes:
            return "20.0-50.0"
        case .monocytes:
            return "3.0-10.0"
        case .eosinophils:
            return "0.4-8.0"
        case .basophils:
            return "0.0-1.0"
        case .neutrophilsCount:
            return "1.8-6.3"
        case .lymphocytesCount:
            return "1.1-3.2"
        case .monocytesCount:
            return "0.1-0.6"
        case .eosinophilsCount:
            return "0.02-0.52"
        case .basophilsCount:
            return "0.00-0.06"
        case .plt:
            return "125-350"
        case .mpv:
            return "6.5-12.0"
        case .pct:
            return "0.108-0.282"
        case .pdw:
            return "15.5-18.1"
        }
    }
    
    var category: BloodRoutineCategory {
        switch self {
        case .rbc, .hgb, .hct, .mcv, .mch, .mchc, .rdw:
            return .redBloodCell
        case .wbc, .neutrophils, .lymphocytes, .monocytes, .eosinophils, .basophils,
             .neutrophilsCount, .lymphocytesCount, .monocytesCount, .eosinophilsCount, .basophilsCount:
            return .whiteBloodCell
        case .plt, .mpv, .pct, .pdw:
            return .platelet
        }
    }
}

// 血常规检查类别
enum BloodRoutineCategory: String, Codable {
    case redBloodCell = "红细胞系统"
    case whiteBloodCell = "白细胞系统"
    case platelet = "血小板系统"
    
    var icon: String {
        switch self {
        case .redBloodCell:
            return "drop.fill"
        case .whiteBloodCell:
            return "allergens"
        case .platelet:
            return "bandage"
        }
    }
    
    var color: String {
        switch self {
        case .redBloodCell:
            return "#F44336"  // 红色
        case .whiteBloodCell:
            return "#4CAF50"  // 绿色
        case .platelet:
            return "#2196F3"  // 蓝色
        }
    }
}

// 血常规检查结果
struct BloodRoutineResult: Codable {
    let item: BloodRoutineItem
    let value: String
    let unit: String
    let referenceRange: String
    let hint: String?  // 提示信息，例如"偏高"、"偏低"等
    var category: BloodRoutineCategory { item.category }
    var abbreviation: String { item.abbreviation }
    
    // 判断结果是否在参考范围内
    var isNormal: Bool {
        guard !referenceRange.isEmpty,
              let numericValue = Double(value) else { return true }
        
        let components = referenceRange.split(separator: "-")
        guard components.count == 2,
              let lower = Double(components[0]),
              let upper = Double(components[1]) else {
            return true
        }
        
        return numericValue >= lower && numericValue <= upper
    }
}

// 用于解析PDF文本的辅助函数
extension BloodRoutineResult {
    static func parse(from text: String) -> [BloodRoutineResult] {
        var results: [BloodRoutineResult] = []
        
        // 遍历所有可能的检查项目
        for item in BloodRoutineItem.allCases {
            // 构建正则表达式模式
            // 匹配格式：项目名称或缩写 数值 单位 参考范围 提示(可选)
            let pattern = "(?:\(item.rawValue)|\\b\(item.abbreviation)\\b)\\s*[：:]*\\s*([\\d.]+)\\s*(\(item.unit))?\\s*(?:参考值?[：:]*\\s*([\\d.-]+))?\\s*(?:提示[：:]*\\s*([^\\n]+))?"
            
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(text.startIndex..., in: text)
                let matches = regex.matches(in: text, options: [], range: range)
                
                for match in matches {
                    if let valueRange = Range(match.range(at: 1), in: text) {
                        let value = String(text[valueRange])
                        
                        var unit = item.unit
                        if match.numberOfRanges > 2,
                           let unitRange = Range(match.range(at: 2), in: text) {
                            unit = String(text[unitRange])
                        }
                        
                        var reference = item.referenceRange
                        if match.numberOfRanges > 3,
                           let refRange = Range(match.range(at: 3), in: text) {
                            reference = String(text[refRange])
                        }
                        
                        var hint: String? = nil
                        if match.numberOfRanges > 4,
                           let hintRange = Range(match.range(at: 4), in: text) {
                            hint = String(text[hintRange])
                        }
                        
                        let result = BloodRoutineResult(
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
        }
        
        return results
    }
}
