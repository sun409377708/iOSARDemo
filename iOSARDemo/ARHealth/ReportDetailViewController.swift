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
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.backgroundColor = .black
        scroll.showsVerticalScrollIndicator = false
        return scroll
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        return label
    }()
    
    private let sourceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        return label
    }()
    
    private lazy var generalCard = HealthDataCard(title: "一般检查")
    private lazy var bloodCard = HealthDataCard(title: "血常规检查")
    private lazy var urineCard = HealthDataCard(title: "尿常规检查")
    
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
        loadData()
    }
    
    private func setupUI() {
        title = "报告详情"
        view.backgroundColor = .black
        
        // Setup scroll view
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Setup content view
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Setup basic info
        let basicInfoStack = UIStackView(arrangedSubviews: [dateLabel, sourceLabel])
        basicInfoStack.axis = .vertical
        basicInfoStack.spacing = 8
        basicInfoStack.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        basicInfoStack.layer.cornerRadius = 12
        basicInfoStack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        basicInfoStack.isLayoutMarginsRelativeArrangement = true
        
        // Add all views to content view
        let mainStack = UIStackView(arrangedSubviews: [
            basicInfoStack,
            generalCard,
            bloodCard,
            urineCard
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 20
        mainStack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        mainStack.isLayoutMarginsRelativeArrangement = true
        
        contentView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    private func loadData() {
        // Set basic info
        dateLabel.text = "检查日期：\(dateFormatter.string(from: report.date))"
        sourceLabel.text = "数据来源：\(report.source.rawValue)"
        
        // Clear existing data
        generalCard.clearMetrics()
        bloodCard.clearMetrics()
        urineCard.clearMetrics()
        
        // Load new data
        for metric in report.metrics {
            switch metric.category {
            case .general:
                generalCard.addMetric(metric)
            case .blood:
                bloodCard.addMetric(metric)
            case .urine:
                urineCard.addMetric(metric)
            case .other:
                if metric.type.contains("(") && metric.type.contains(")") {
                    bloodCard.addMetric(metric)
                } else {
                    generalCard.addMetric(metric)
                }
            }
        }
        
        // Hide empty cards
        generalCard.isHidden = report.metrics.filter { $0.category == .general }.isEmpty
        bloodCard.isHidden = report.metrics.filter { $0.category == .blood }.isEmpty
        urineCard.isHidden = report.metrics.filter { $0.category == .urine }.isEmpty
    }
}
