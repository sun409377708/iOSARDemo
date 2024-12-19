import UIKit
import PDFKit
import TesseractOCR

class TesseractViewController: UIViewController {
    
    private let pdfView: PDFView = {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePage
        view.backgroundColor = .systemBackground
        return view
    }()
    
    private let resultTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.font = .systemFont(ofSize: 14)
        textView.backgroundColor = UIColor.systemGray6
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return textView
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
    
    private var pdfURL: URL
    private var tesseract: G8Tesseract?
    
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
        setupTesseract()
        loadPDF()
        startProcessing()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Tesseract OCR"
        
        // 添加返回按钮
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        backButton.tintColor = .systemBlue
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        
        [pdfView, resultTextView, progressView, statusLabel, activityIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            
            resultTextView.topAnchor.constraint(equalTo: pdfView.bottomAnchor, constant: 16),
            resultTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            resultTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            resultTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            progressView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            statusLabel.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -20)
        ])
        
        activityIndicator.startAnimating()
        progressView.progress = 0
    }
    
    private func setupTesseract() {
        tesseract = G8Tesseract(language: "chi_sim+eng")
        tesseract?.delegate = self
        tesseract?.engineMode = .tesseractCubeCombined
        tesseract?.pageSegmentationMode = .auto
    }
    
    private func loadPDF() {
        if let document = PDFDocument(url: pdfURL) {
            pdfView.document = document
        }
    }
    
    private func startProcessing() {
        guard let document = PDFDocument(url: pdfURL) else {
            showError("无法打开PDF文件")
            return
        }
        
        let pageCount = document.pageCount
        var processedPages = 0
        var allText = ""
        
        let queue = DispatchQueue(label: "com.tesseract.process", attributes: .concurrent)
        let group = DispatchGroup()
        
        for pageIndex in 0..<pageCount {
            group.enter()
            queue.async { [weak self] in
                guard let self = self else { return }
                
                if let pdfPage = document.page(at: pageIndex) {
                    let pageRect = pdfPage.bounds(for: .mediaBox)
                    let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                    let image = renderer.image { context in
                        UIColor.white.set()
                        context.fill(pageRect)
                        pdfPage.draw(with: .mediaBox, to: context.cgContext)
                    }
                    
                    if let tesseract = self.tesseract {
                        tesseract.image = image
                        tesseract.recognize()
                        
                        if let text = tesseract.recognizedText {
                            allText += "第 \(pageIndex + 1) 页:\n\(text)\n\n"
                        }
                    }
                    
                    DispatchQueue.main.async {
                        processedPages += 1
                        let progress = Float(processedPages) / Float(pageCount)
                        self.updateProgress(progress, pageNumber: pageIndex + 1, total: pageCount)
                        
                        if processedPages == pageCount {
                            self.showResults(allText)
                        }
                    }
                }
                group.leave()
            }
        }
    }
    
    private func updateProgress(_ progress: Float, pageNumber: Int, total: Int) {
        progressView.progress = progress
        statusLabel.text = "正在处理第 \(pageNumber) 页 (共 \(total) 页)"
    }
    
    private func showResults(_ text: String) {
        activityIndicator.stopAnimating()
        progressView.isHidden = true
        statusLabel.isHidden = true
        
        // 使用正则表达式提取健康数据
        let healthData = extractHealthData(from: text)
        
        // 创建健康指标
        let metrics = healthData.map { text -> HealthMetric in
            // 使用正则表达式提取数值和单位
            let components = text.components(separatedBy: CharacterSet(charactersIn: "：: "))
            let type = components.first ?? ""
            let valueAndUnit = components.last ?? ""
            
            // 分离数值和单位
            let valueComponents = valueAndUnit.components(separatedBy: CharacterSet.letters)
            let value = valueComponents.first?.trimmingCharacters(in: .whitespaces) ?? ""
            let unit = valueAndUnit.replacingOccurrences(of: value, with: "").trimmingCharacters(in: .whitespaces)
            
            return HealthMetric(
                type: type,
                value: value,
                unit: unit,
                reference: "",
                originalText: text
            )
        }
        
        // 保存分析结果
        if !metrics.isEmpty {
            let report = HealthReport(metrics: metrics, source: .scan)
            HealthReportManager.shared.saveReport(report)
        }
        
        resultTextView.text = healthData.isEmpty ? "未找到健康数据" : healthData.joined(separator: "\n")
    }
    
    private func extractHealthData(from text: String) -> [String] {
        var results: [String] = []
        
        // 定义健康数据的正则表达式模式
        let patterns = [
            "血压\\s*[：:]*\\s*(\\d{2,3}[/\\\\]\\d{2,3})\\s*mmHg",
            "心率\\s*[：:]*\\s*(\\d{2,3})\\s*次/分",
            "血糖\\s*[：:]*\\s*(\\d+\\.?\\d*)\\s*mmol/L",
            "体温\\s*[：:]*\\s*(\\d+\\.?\\d*)\\s*[°℃]C?",
            "血氧\\s*[：:]*\\s*(\\d{2,3})\\s*%",
            "体重\\s*[：:]*\\s*(\\d+\\.?\\d*)\\s*kg",
            "身高\\s*[：:]*\\s*(\\d+\\.?\\d*)\\s*cm"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(text.startIndex..., in: text)
                let matches = regex.matches(in: text, options: [], range: range)
                
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        results.append(String(text[range]))
                    }
                }
            }
        }
        
        return results
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - G8TesseractDelegate
extension TesseractViewController: G8TesseractDelegate {
    func progressImageRecognition(for tesseract: G8Tesseract) {
        let progress = tesseract.progress / 100
        DispatchQueue.main.async { [weak self] in
            self?.progressView.progress = Float(progress)
        }
    }
    
    func shouldCancelImageRecognition(for tesseract: G8Tesseract) -> Bool {
        return false
    }
}
