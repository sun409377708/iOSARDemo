import UIKit

class ReportDetailViewController: UIViewController {
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        table.backgroundColor = .systemGroupedBackground
        return table
    }()
    
    private let report: HealthReport
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
        return formatter
    }()
    
    // 分组数据
    private var sections: [(title: String, metrics: [HealthMetric])] = []
    
    init(report: HealthReport) {
        self.report = report
        super.init(nibName: nil, bundle: nil)
        categorizeMetrics()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "报告详情"
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func categorizeMetrics() {
        // 基本信息
        sections.append((
            title: "基本信息",
            metrics: [
                HealthMetric(
                    type: "检查日期",
                    value: dateFormatter.string(from: report.date),
                    unit: "",
                    reference: "",
                    originalText: "",
                    category: .other
                ),
                HealthMetric(
                    type: "数据来源",
                    value: report.source.rawValue,
                    unit: "",
                    reference: "",
                    originalText: "",
                    category: .other
                )
            ]
        ))
        
        // 分类指标
        var generalMetrics: [HealthMetric] = []
        var bloodMetrics: [HealthMetric] = []
        var urineMetrics: [HealthMetric] = []
        
        for metric in report.metrics {
            switch metric.category {
            case .general:
                generalMetrics.append(metric)
            case .blood:
                bloodMetrics.append(metric)
            case .urine:
                urineMetrics.append(metric)
            case .other:
                if metric.type.contains("(") && metric.type.contains(")") {
                    bloodMetrics.append(metric)
                } else {
                    generalMetrics.append(metric)
                }
            }
        }
        
        // 按名称排序
        generalMetrics.sort { $0.type < $1.type }
        bloodMetrics.sort { $0.type < $1.type }
        urineMetrics.sort { $0.type < $1.type }
        
        // 添加非空分组
        if !generalMetrics.isEmpty {
            sections.append((title: "一般检查", metrics: generalMetrics))
        }
        if !bloodMetrics.isEmpty {
            sections.append((title: "血常规检查", metrics: bloodMetrics))
        }
        if !urineMetrics.isEmpty {
            sections.append((title: "尿常规检查", metrics: urineMetrics))
        }
    }
}

// MARK: - UITableViewDataSource
extension ReportDetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].metrics.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let metric = sections[indexPath.section].metrics[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = metric.type
        
        // 格式化值和单位
        var detailText = "\(metric.value)"
        if !metric.unit.isEmpty {
            detailText += " \(metric.unit)"
        }
        if !metric.hint.isEmpty {
            detailText += " (\(metric.hint))"
        }
        if !metric.reference.isEmpty {
            detailText += "\n参考范围: \(metric.reference)"
        }
        
        content.secondaryText = detailText
        content.secondaryTextProperties.color = getHintColor(metric.hint)
        content.secondaryTextProperties.numberOfLines = 0
        
        cell.contentConfiguration = content
        cell.backgroundColor = .systemBackground
        return cell
    }
    
    private func getHintColor(_ hint: String) -> UIColor {
        switch hint {
        case "偏高":
            return .systemRed
        case "偏低":
            return .systemBlue
        default:
            return .secondaryLabel
        }
    }
}

// MARK: - UITableViewDelegate
extension ReportDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
