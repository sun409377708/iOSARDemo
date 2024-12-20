//
//  HealthReportManager.swift
//  iOSARDemo
//
//  Created by maoge on 2024/12/20.
//

import Foundation

// MARK: - Storage Manager
class HealthReportManager {
    static let shared = HealthReportManager()
    private let defaults = UserDefaults.standard
    private let reportsKey = "savedHealthReports"

    private init() {
        // 如果是第一次运行，添加一些示例数据
        if getAllReports().isEmpty {
            addSampleReports()
        }
    }

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
    
    // 添加示例数据
    private func addSampleReports() {
        let bloodMetrics = [
            HealthMetric(
                type: "血红蛋白",
                value: "145",
                unit: "g/L",
                reference: "130-175",
                originalText: "血红蛋白 145 g/L",
                abbreviation: "HGB",
                hint: "正常",
                category: .blood
            ),
            HealthMetric(
                type: "白细胞",
                value: "6.5",
                unit: "10^9/L",
                reference: "4.0-10.0",
                originalText: "白细胞 6.5 10^9/L",
                abbreviation: "WBC",
                hint: "正常",
                category: .blood
            )
        ]
        
        let urineMetrics = [
            HealthMetric.urineMetric(
                name: "尿蛋白",
                abbreviation: "PRO",
                value: "阴性",
                hint: "正常",
                reference: "阴性",
                unit: "",
                originalText: "尿蛋白 阴性"
            ),
            HealthMetric.urineMetric(
                name: "尿糖",
                abbreviation: "GLU",
                value: "阴性",
                hint: "正常",
                reference: "阴性",
                unit: "",
                originalText: "尿糖 阴性"
            )
        ]
        
        let bloodReport = HealthReport(
            metrics: bloodMetrics,
            source: .pdf
        )
        
        let urineReport = HealthReport(
            metrics: urineMetrics,
            source: .pdf
        )
        
        saveReport(bloodReport)
        saveReport(urineReport)
    }
}
