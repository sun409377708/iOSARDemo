import Foundation

// 一般检查室的检查项目
enum GeneralExamItem: String, Codable, CaseIterable {
    // 身高体重
    case height = "身高"
    case weight = "体重"
    case bmi = "体重指数"
    case waistline = "腰围"
    
    // 血压心率
    case bloodPressure = "血压"
    case systolicPressure = "收缩压"
    case diastolicPressure = "舒张压"
    case heartRate = "心率"
    case pulseRate = "脉率"
    
    // 体温
    case temperature = "体温"
    
    // 视力
    case leftVision = "左眼视力"
    case rightVision = "右眼视力"
    case correctedLeftVision = "左眼矫正视力"
    case correctedRightVision = "右眼矫正视力"
    
    // 听力
    case leftHearing = "左耳听力"
    case rightHearing = "右耳听力"
    
    var unit: String {
        switch self {
        case .height:
            return "cm"
        case .weight:
            return "kg"
        case .bmi:
            return "kg/m²"
        case .waistline:
            return "cm"
        case .bloodPressure, .systolicPressure, .diastolicPressure:
            return "mmHg"
        case .heartRate, .pulseRate:
            return "次/分"
        case .temperature:
            return "℃"
        case .leftVision, .rightVision, .correctedLeftVision, .correctedRightVision:
            return ""
        case .leftHearing, .rightHearing:
            return "Hz"
        }
    }
    
    var referenceRange: String {
        switch self {
        case .bmi:
            return "18.5-23.9"
        case .bloodPressure:
            return "收缩压：90-140\n舒张压：60-90"
        case .systolicPressure:
            return "90-140"
        case .diastolicPressure:
            return "60-90"
        case .heartRate, .pulseRate:
            return "60-100"
        case .temperature:
            return "36.3-37.2"
        case .leftVision, .rightVision, .correctedLeftVision, .correctedRightVision:
            return "4.0-5.0"
        default:
            return ""
        }
    }
    
    var category: ExamCategory {
        switch self {
        case .height, .weight, .bmi, .waistline:
            return .bodyMeasurement
        case .bloodPressure, .systolicPressure, .diastolicPressure, .heartRate, .pulseRate:
            return .cardiovascular
        case .temperature:
            return .temperature
        case .leftVision, .rightVision, .correctedLeftVision, .correctedRightVision:
            return .vision
        case .leftHearing, .rightHearing:
            return .hearing
        }
    }
}

// 检查类别
enum ExamCategory: String, Codable {
    case bodyMeasurement = "身体测量"
    case cardiovascular = "心血管"
    case temperature = "体温"
    case vision = "视力"
    case hearing = "听力"
    
    var icon: String {
        switch self {
        case .bodyMeasurement:
            return "person.fill"
        case .cardiovascular:
            return "heart.fill"
        case .temperature:
            return "thermometer"
        case .vision:
            return "eye.fill"
        case .hearing:
            return "ear.fill"
        }
    }
    
    var color: String {
        switch self {
        case .bodyMeasurement:
            return "#4CAF50"  // 绿色
        case .cardiovascular:
            return "#F44336"  // 红色
        case .temperature:
            return "#FF9800"  // 橙色
        case .vision:
            return "#2196F3"  // 蓝色
        case .hearing:
            return "#9C27B0"  // 紫色
        }
    }
}

// 一般检查结果
struct GeneralExamResult: Codable {
    let item: GeneralExamItem
    let value: String
    let unit: String
    let referenceRange: String
    var category: ExamCategory { item.category }
    
    enum CodingKeys: String, CodingKey {
        case item
        case value
        case unit
        case referenceRange
    }
    
    // 判断结果是否在参考范围内
    var isNormal: Bool {
        guard !referenceRange.isEmpty else { return true }
        
        // 处理特殊的血压值
        if item == .bloodPressure {
            return isBloodPressureNormal()
        }
        
        // 处理常规数值范围
        if let numericValue = Double(value),
           let range = parseReferenceRange(referenceRange) {
            return numericValue >= range.lowerBound && numericValue <= range.upperBound
        }
        
        return true
    }
    
    private func isBloodPressureNormal() -> Bool {
        // 解析血压值（例如：120/80）
        let components = value.split(separator: "/")
        guard components.count == 2,
              let systolic = Double(components[0]),
              let diastolic = Double(components[1]) else {
            return true
        }
        
        // 检查收缩压和舒张压是否在正常范围内
        return systolic >= 90 && systolic <= 140 &&
               diastolic >= 60 && diastolic <= 90
    }
    
    private func parseReferenceRange(_ range: String) -> ClosedRange<Double>? {
        let components = range.split(separator: "-")
        guard components.count == 2,
              let lower = Double(components[0]),
              let upper = Double(components[1]) else {
            return nil
        }
        return lower...upper
    }
}

// 用于解析PDF文本的辅助函数
extension GeneralExamResult {
    static func parse(from text: String) -> [GeneralExamResult] {
        var results: [GeneralExamResult] = []
        
        // 遍历所有可能的检查项目
        for item in GeneralExamItem.allCases {
            // 对血压进行特殊处理
            if item == .bloodPressure {
                let bloodPressurePattern = "血压\\s*[：:]*\\s*([\\d.]+)/([\\d.]+)\\s*(\(item.unit))?"
                
                if let regex = try? NSRegularExpression(pattern: bloodPressurePattern, options: []) {
                    let range = NSRange(text.startIndex..., in: text)
                    let matches = regex.matches(in: text, options: [], range: range)
                    
                    for match in matches {
                        if let systolicRange = Range(match.range(at: 1), in: text),
                           let diastolicRange = Range(match.range(at: 2), in: text) {
                            let systolicValue = String(text[systolicRange])
                            let diastolicValue = String(text[diastolicRange])
                            
                            // 添加收缩压
                            let systolicResult = GeneralExamResult(
                                item: .systolicPressure,
                                value: systolicValue,
                                unit: "mmHg",
                                referenceRange: "90-140"
                            )
                            results.append(systolicResult)
                            
                            // 添加舒张压
                            let diastolicResult = GeneralExamResult(
                                item: .diastolicPressure,
                                value: diastolicValue,
                                unit: "mmHg",
                                referenceRange: "60-90"
                            )
                            results.append(diastolicResult)
                            
                            // 添加原始血压值
                            let bloodPressureResult = GeneralExamResult(
                                item: .bloodPressure,
                                value: "\(systolicValue)/\(diastolicValue)",
                                unit: "mmHg",
                                referenceRange: "收缩压：90-140\n舒张压：60-90"
                            )
                            results.append(bloodPressureResult)
                        }
                    }
                }
                continue
            }
            
            // 处理其他检查项目
            let pattern = "\(item.rawValue)\\s*[：:]*\\s*([\\d./]+)\\s*(\(item.unit))?\\s*(?:参考值?[：:]*\\s*([\\d.-]+))?"
            
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
                        
                        let result = GeneralExamResult(
                            item: item,
                            value: value,
                            unit: unit,
                            referenceRange: reference
                        )
                        results.append(result)
                    }
                }
            }
        }
        
        return results
    }
}
