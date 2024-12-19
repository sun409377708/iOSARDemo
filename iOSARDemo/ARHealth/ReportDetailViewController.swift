import UIKit

// 自定义 cell 类
class DetailCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ReportDetailViewController: UIViewController {
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.register(DetailCell.self, forCellReuseIdentifier: "Cell")
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
    
    // 分类后的数据
    private var basicInfo: [HealthMetric] = []      // 基本信息
    private var generalExams: [HealthMetric] = []   // 一般检查
    private var bloodRoutine: [HealthMetric] = []   // 血常规
    private var urineRoutine: [HealthMetric] = []   // 尿常规
    
    init(report: HealthReport) {
        self.report = report
        super.init(nibName: nil, bundle: nil)
        categorizeMetrics()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func categorizeMetrics() {
        for metric in report.metrics {
            switch metric.category {
            case .general:
                generalExams.append(metric)
            case .blood:
                bloodRoutine.append(metric)
            case .urine:
                urineRoutine.append(metric)
            case .other:
                // 根据类型判断
                if metric.type.contains("(") && metric.type.contains(")") {
                    bloodRoutine.append(metric)
                } else {
                    generalExams.append(metric)
                }
            }
        }
        
        // 按名称排序
        bloodRoutine.sort { $0.type < $1.type }
        urineRoutine.sort { $0.type < $1.type }
        generalExams.sort { $0.type < $1.type }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "报告详情"
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ReportDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        var sections = 2 // 基本信息和一般检查总是存在
        if !bloodRoutine.isEmpty { sections += 1 }
        if !urineRoutine.isEmpty { sections += 1 }
        return sections
    }
    
    private func sectionType(for section: Int) -> MetricCategory {
        switch section {
        case 0: return .other // 基本信息
        case 1: return .general
        case 2: return !bloodRoutine.isEmpty ? .blood : .urine
        case 3: return .urine
        default: return .other
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sectionType(for: section) {
        case .other: return 2 // 基本信息：日期和来源
        case .general: return generalExams.count
        case .blood: return bloodRoutine.count
        case .urine: return urineRoutine.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! DetailCell
        cell.selectionStyle = .none
        
        var content = cell.defaultContentConfiguration()
        content.textProperties.font = .systemFont(ofSize: 16)
        content.secondaryTextProperties.font = .systemFont(ofSize: 14)
        content.secondaryTextProperties.color = .secondaryLabel
        
        switch sectionType(for: indexPath.section) {
        case .other:
            if indexPath.row == 0 {
                content.text = "日期"
                content.secondaryText = dateFormatter.string(from: report.date)
            } else {
                content.text = "来源"
                content.secondaryText = report.source.rawValue
            }
            
        case .general:
            let metric = generalExams[indexPath.row]
            content.text = metric.type
            content.secondaryText = metric.displayValue
            
        case .blood:
            let metric = bloodRoutine[indexPath.row]
            content.text = metric.type
            content.secondaryText = metric.originalText
            
        case .urine:
            let metric = urineRoutine[indexPath.row]
            content.text = metric.type
            if !metric.abbreviation.isEmpty {
                content.text! += " (\(metric.abbreviation))"
            }
            content.secondaryText = metric.displayValue
        }
        
        content.secondaryTextProperties.numberOfLines = 0
        cell.contentConfiguration = content
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch sectionType(for: section) {
        case .other: return "基本信息"
        case .general: return "一般检查"
        case .blood: return "血常规检查"
        case .urine: return "尿常规检查"
        }
    }
}
