import UIKit
import PDFKit
import Vision

class PDFProcessViewController: UIViewController {
    
    private let pdfView: PDFView = {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePage
        view.backgroundColor = .systemBackground
        return view
    }()
    
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .systemBlue
        progress.trackTintColor = .systemGray5
        return progress
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .label
        label.font = .systemFont(ofSize: 16)
        label.text = "正在处理PDF..."
        return label
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let completeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("查看详情", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.isHidden = true
        return button
    }()
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        table.backgroundColor = .systemBackground
        table.isHidden = true
        return table
    }()
    
    private var pdfURL: URL
    private var extractedData: [HealthData] = []
    private var debugLog: String = ""
    private var recognizedLines: [[RecognizedTableRow]] = []
    private var currentReport: HealthReport?
    
    struct RecognizedTableRow {
        var item: String
        var value: String
        var unit: String
        var reference: String
        var boundingBox: CGRect
        var pageNumber: Int
    }
    
    struct HealthData {
        var type: String
        var value: String
        var unit: String
        var pageNumber: Int
        var reference: String
        var hint: String?
        var originalText: String
    }
    
    init(pdfURL: URL) {
        self.pdfURL = pdfURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPDF()
        startProcessing()
        
        // 设置导航栏
        title = "PDF 处理"
        navigationController?.navigationBar.isHidden = false
        
        // 添加返回按钮
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        backButton.tintColor = .systemBlue
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        [pdfView, tableView, progressView, statusLabel, activityIndicator, completeButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            
            tableView.topAnchor.constraint(equalTo: pdfView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: completeButton.topAnchor, constant: -20),
            
            progressView.topAnchor.constraint(equalTo: pdfView.bottomAnchor, constant: 20),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            statusLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            
            completeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            completeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            completeButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -20),
            completeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        completeButton.addTarget(self, action: #selector(completeButtonTapped), for: .touchUpInside)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        activityIndicator.startAnimating()
    }
    
    private func setupPDF() {
        if let document = PDFDocument(url: pdfURL) {
            pdfView.document = document
        }
    }
    
    private func startProcessing() {
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            showError("无法打开PDF文件")
            return
        }
        
        let pageCount = pdfDocument.pageCount
        var processedPages = 0
        recognizedLines = Array(repeating: [], count: pageCount)
        
        let queue = DispatchQueue(label: "com.pdf.process", attributes: .concurrent)
        let group = DispatchGroup()
        let serialQueue = DispatchQueue(label: "com.pdf.serial")
        
        for pageIndex in 0..<pageCount {
            group.enter()
            queue.async { [weak self] in
                guard let self = self else { return }
                
                if let pdfPage = pdfDocument.page(at: pageIndex) {
                    let pageRect = pdfPage.bounds(for: .mediaBox)
                    let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                    let image = renderer.image { context in
                        UIColor.white.set()
                        context.fill(pageRect)
                        context.cgContext.translateBy(x: 0, y: pageRect.size.height)
                        context.cgContext.scaleBy(x: 1.0, y: -1.0)
                        pdfPage.draw(with: .mediaBox, to: context.cgContext)
                    }
                    
                    if let ciImage = CIImage(image: image) {
                        self.processPage(ciImage, pageRect: pageRect, pageNumber: pageIndex) { rows in
                            serialQueue.async {
                                self.recognizedLines[pageIndex] = rows
                            }
                            
                            DispatchQueue.main.async {
                                processedPages += 1
                                let progress = Float(processedPages) / Float(pageCount)
                                self.updateProgress(progress, pageNumber: pageIndex + 1, total: pageCount)
                                
                                if processedPages == pageCount {
                                    self.analyzeTableData()
                                }
                            }
                            group.leave()
                        }
                    } else {
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
        }
    }
    
    private func processPage(_ image: CIImage, pageRect: CGRect, pageNumber: Int, completion: @escaping ([RecognizedTableRow]) -> Void) {
        var rows: [RecognizedTableRow] = []
        
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else {
                completion([])
                return
            }
            
            let sortedObservations = observations.sorted { first, second in
                first.boundingBox.origin.y > second.boundingBox.origin.y
            }
            
            var currentRow: RecognizedTableRow?
            var lastY: CGFloat = -1
            
            for observation in sortedObservations {
                guard let text = observation.topCandidates(1).first?.string else { continue }
                
                let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if normalizedText.isEmpty { continue }
                
                let boundingBox = VNImageRectForNormalizedRect(observation.boundingBox, Int(pageRect.width), Int(pageRect.height))
                
                if lastY == -1 || abs(boundingBox.origin.y - lastY) > 20 {
                    if let row = currentRow {
                        rows.append(row)
                    }
                    currentRow = RecognizedTableRow(item: "", value: "", unit: "", reference: "", boundingBox: boundingBox, pageNumber: pageNumber)
                    lastY = boundingBox.origin.y
                }
                
                let x = boundingBox.origin.x
                if x < pageRect.width * 0.3 {
                    currentRow?.item = normalizedText
                } else if x < pageRect.width * 0.5 {
                    currentRow?.value = normalizedText
                } else if x < pageRect.width * 0.6 {
                    currentRow?.unit = normalizedText
                } else {
                    currentRow?.reference = normalizedText
                }
            }
            
            if let row = currentRow {
                rows.append(row)
            }
            
            DispatchQueue.main.async {
                self.debugLog += "Page \(pageNumber + 1) Rows:\n"
                for row in rows {
                    self.debugLog += "项目: \(row.item), 值: \(row.value), 单位: \(row.unit), 参考: \(row.reference)\n"
                }
                self.debugLog += "---\n"
                print(self.debugLog)
            }
            
            completion(rows)
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hans", "en-US"]
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        try? handler.perform([request])
    }
    
    private func analyzeTableData() {
        var allText = ""
        
        // 收集所有文本
        for (_, rows) in recognizedLines.enumerated() {
            for row in rows {
                allText += "\(row.item): \(row.value) \(row.unit)\n"
                if !row.reference.isEmpty {
                    allText += "参考值: \(row.reference)\n"
                }
            }
        }
        
        // 解析一般检查结果
        let examResults = GeneralExamResult.parse(from: allText)
        
        // 解析血常规结果
        let bloodResults = BloodRoutineResult.parse(from: allText)
        
        // 解析尿常规结果
        let urineResults = UrineRoutineResult.parse(from: allText)
        
        // 将所有结果转换为 HealthMetric
        var healthMetrics: [HealthMetric] = []
        
        // 添加一般检查结果
        healthMetrics += examResults.map { result in
            HealthMetric(
                type: result.item.rawValue,
                value: result.value,
                unit: result.unit,
                reference: result.referenceRange,
                originalText: "\(result.item.rawValue): \(result.value) \(result.unit)",
                category: .general
            )
        }
        
        // 添加血常规结果
        healthMetrics += bloodResults.map { result in
            var originalText = "\(result.item.rawValue)(\(result.abbreviation)): \(result.value) \(result.unit)"
            if let hint = result.hint {
                originalText += " (\(hint))"
            }
            return HealthMetric(
                type: "\(result.item.rawValue)(\(result.abbreviation))",
                value: result.value,
                unit: result.unit,
                reference: result.referenceRange,
                originalText: originalText,
                category: .blood
            )
        }
        
        // 添加尿常规结果
        healthMetrics += urineResults.map { result in
            let abbreviation = result.item.abbreviation
            let displayType = abbreviation.isEmpty ? result.item.rawValue : "\(result.item.rawValue)(\(abbreviation))"
            return HealthMetric(
                type: displayType,
                value: result.value,
                unit: result.unit,
                reference: result.referenceRange,
                originalText: "\(displayType): \(result.value) \(result.unit)",
                abbreviation: abbreviation,
                hint: result.hint,
                category: .urine
            )
        }
        
        // 保存分析结果
        let report = HealthReport(metrics: healthMetrics, source: .pdf)
        HealthReportManager.shared.saveReport(report)
        
        // 更新UI
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicator.stopAnimating()
            self?.progressView.isHidden = true
            self?.statusLabel.isHidden = true
            self?.tableView.isHidden = false
            
            // 将结果转换为显示用的 HealthData
            self?.extractedData = healthMetrics.map { metric in
                HealthData(
                    type: metric.type,
                    value: metric.value,
                    unit: metric.unit,
                    pageNumber: 0,
                    reference: metric.reference,
                    hint: metric.hint,
                    originalText: metric.originalText
                )
            }
            
            self?.tableView.reloadData()
            self?.processingCompleted(with: report)
        }
    }
    
    private func extractNumericValue(from text: String) -> String? {
        let pattern = "\\d+(\\.\\d+)?"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(text.startIndex..., in: text)
        
        if let match = regex?.firstMatch(in: text, options: [], range: range),
           let range = Range(match.range, in: text) {
            return String(text[range])
        }
        
        return nil
    }
    
    private func updateProgress(_ progress: Float, pageNumber: Int, total: Int) {
        progressView.progress = progress
        statusLabel.text = "正在处理第 \(pageNumber)/\(total) 页..."
    }
    
    private func processingCompleted(with report: HealthReport) {
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicator.stopAnimating()
            self?.progressView.isHidden = true
            self?.statusLabel.text = "处理完成"
            self?.currentReport = report
            self?.completeButton.isHidden = false
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    @objc private func completeButtonTapped() {
        guard let report = currentReport else { return }
        let detailVC = ReportDetailViewController(report: report)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension PDFProcessViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return extractedData.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "识别到的健康数据"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let data = extractedData[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = data.type
        content.secondaryText = "\(data.value) \(data.unit)"
        if !data.reference.isEmpty {
            content.secondaryText! += "\n参考范围: \(data.reference)"
        }
        if let hint = data.hint {
            content.secondaryText! += "\n\(hint)"
        }
        content.secondaryTextProperties.numberOfLines = 0
        cell.contentConfiguration = content
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let data = extractedData[indexPath.row]
        if let document = pdfView.document,
           let page = document.page(at: data.pageNumber) {
            pdfView.go(to: page)
        }
    }
}
