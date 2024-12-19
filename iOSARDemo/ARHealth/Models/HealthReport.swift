import Foundation

// 检查项目类型
enum MetricCategory: String, Codable {
    case general = "一般检查"
    case blood = "血常规"
    case urine = "尿常规"
    case other = "其他"
}

struct HealthReport: Codable {
    let id: String
    let date: Date
    let metrics: [HealthMetric]
    let source: ReportSource
    
    init(id: String = UUID().uuidString, date: Date = Date(), metrics: [HealthMetric], source: ReportSource) {
        self.id = id
        self.date = date
        self.metrics = metrics
        self.source = source
    }
}

struct HealthMetric: Codable {
    let type: String           // 检查项目
    let abbreviation: String   // 缩写
    let value: String         // 测量结果
    let hint: String          // 提示（如：偏高、正常等）
    let reference: String     // 参考区间
    let unit: String          // 单位
    let category: MetricCategory // 检查类别
    let originalText: String   // 原始文本
    
    // 用于显示的格式化值
    var displayValue: String {
        var display = "\(value) \(unit)"
        if !hint.isEmpty {
            display += " (\(hint))"
        }
        if !reference.isEmpty {
            display += "\n参考范围: \(reference)"
        }
        return display
    }
    
    // 初始化方法，为了保持向后兼容性
    init(type: String, value: String, unit: String, reference: String, originalText: String, 
         abbreviation: String = "", hint: String = "", category: MetricCategory = .other) {
        self.type = type
        self.value = value
        self.unit = unit
        self.reference = reference
        self.originalText = originalText
        self.abbreviation = abbreviation
        self.hint = hint
        self.category = category
    }
    
    // 创建尿常规指标的便利初始化方法
    static func urineMetric(name: String, abbreviation: String, value: String, hint: String, 
                          reference: String, unit: String, originalText: String) -> HealthMetric {
        return HealthMetric(
            type: name,
            value: value,
            unit: unit,
            reference: reference,
            originalText: originalText,
            abbreviation: abbreviation,
            hint: hint,
            category: .urine
        )
    }
    
    var icon: String {
        switch category {
        case .blood:
            return "drop.fill"
        case .urine:
            return "flask.fill"
        case .general:
            switch type.lowercased() {
            case "血压", "bp":
                return "heart.fill"
            case "心率", "heart rate", "hr":
                return "waveform.path.ecg"
            case "身高", "height":
                return "person.fill"
            case "体重", "weight":
                return "scalemass.fill"
            default:
                return "cross.fill"
            }
        case .other:
            return "cross.fill"
        }
    }
    
    var color: String {
        switch category {
        case .blood:
            return "#FF4B4B"
        case .urine:
            return "#FFA726"
        case .general:
            switch type.lowercased() {
            case "血压", "bp":
                return "#FF4B4B"
            case "心率", "heart rate", "hr":
                return "#FF8E3C"
            case "身高", "height":
                return "#2196F3"
            case "体重", "weight":
                return "#4CAF50"
            default:
                return "#9E9E9E"
            }
        case .other:
            return "#9E9E9E"
        }
    }
}

enum ReportSource: String, Codable {
    case scan = "扫描"
    case pdf = "PDF"
}

// MARK: - Notification Names
extension Notification.Name {
    static let healthReportUpdated = Notification.Name("healthReportUpdated")
}

// MARK: - Storage Manager
class HealthReportManager {
    static let shared = HealthReportManager()
    private let defaults = UserDefaults.standard
    private let reportsKey = "savedHealthReports"
    
    private init() {}
    
    func saveReport(_ report: HealthReport) {
        var reports = getAllReports()
        reports.append(report)
        
        if let encoded = try? JSONEncoder().encode(reports) {
            defaults.set(encoded, forKey: reportsKey)
            NotificationCenter.default.post(name: .healthReportUpdated, object: nil)
        }
    }
    
    func getAllReports() -> [HealthReport] {
        guard let data = defaults.data(forKey: reportsKey),
              let reports = try? JSONDecoder().decode([HealthReport].self, from: data) else {
            return []
        }
        return reports.sorted { $0.date > $1.date }
    }
    
    func deleteReport(withId id: String) {
        var reports = getAllReports()
        reports.removeAll { $0.id == id }
        
        if let encoded = try? JSONEncoder().encode(reports) {
            defaults.set(encoded, forKey: reportsKey)
            NotificationCenter.default.post(name: .healthReportUpdated, object: nil)
        }
    }
    
    func clearAllReports() {
        defaults.removeObject(forKey: reportsKey)
        NotificationCenter.default.post(name: .healthReportUpdated, object: nil)
    }
}
