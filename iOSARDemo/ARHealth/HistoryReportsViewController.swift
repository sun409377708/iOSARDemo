import UIKit

class HistoryReportsViewController: UIViewController {
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.register(HistoryReportCell.self, forCellReuseIdentifier: "HistoryReportCell")
        table.backgroundColor = .systemGroupedBackground
        return table
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "暂无历史报告"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16)
        label.isHidden = true
        return label
    }()
    
    private var reports: [HealthReport] = []
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadReports()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadReports()
        tableView.reloadData()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "历史报告"
        
        // 添加编辑按钮
        navigationItem.rightBarButtonItem = editButtonItem
        
        [tableView, emptyStateLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func loadReports() {
        reports = HealthReportManager.shared.getAllReports()
        emptyStateLabel.isHidden = !reports.isEmpty
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension HistoryReportsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reports.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryReportCell", for: indexPath) as! HistoryReportCell
        let report = reports[indexPath.row]
        cell.configure(with: report, dateFormatter: dateFormatter)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let report = reports[indexPath.row]
        let detailVC = ReportDetailViewController(report: report)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let report = reports[indexPath.row]
            HealthReportManager.shared.deleteReport(withId: report.id)
            reports.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            emptyStateLabel.isHidden = !reports.isEmpty
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

// MARK: - HistoryReportCell
class HistoryReportCell: UITableViewCell {
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let sourceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        return label
    }()
    
    private let metricsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.distribution = .fillEqually
        return stack
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        accessoryType = .disclosureIndicator
        
        [dateLabel, sourceLabel, metricsStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            sourceLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            sourceLabel.leadingAnchor.constraint(equalTo: dateLabel.leadingAnchor),
            
            metricsStackView.topAnchor.constraint(equalTo: sourceLabel.bottomAnchor, constant: 8),
            metricsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            metricsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            metricsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with report: HealthReport, dateFormatter: DateFormatter) {
        dateLabel.text = dateFormatter.string(from: report.date)
        sourceLabel.text = "来源: \(report.source.rawValue)"
        
        // 清除旧的指标视图
        metricsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 添加新的指标视图
        let metrics = report.metrics.prefix(3) // 最多显示3个指标
        metrics.forEach { metric in
            let metricView = MetricView(metric: metric)
            metricsStackView.addArrangedSubview(metricView)
        }
    }
}

// MARK: - MetricView
class MetricView: UIView {
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let typeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .right
        return label
    }()
    
    init(metric: HealthMetric) {
        super.init(frame: .zero)
        setupUI()
        configure(with: metric)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        [iconImageView, typeLabel, valueLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            typeLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            typeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            valueLabel.leadingAnchor.constraint(equalTo: typeLabel.trailingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    private func configure(with metric: HealthMetric) {
        iconImageView.image = UIImage(systemName: metric.icon)
        typeLabel.text = metric.type
        valueLabel.text = metric.displayValue
    }
}
