import UIKit
import UniformTypeIdentifiers

class HomeViewController: UIViewController, UIDocumentPickerDelegate {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "AR健康报告"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = """
        欢迎使用AR健康报告分析工具！

        本应用提供以下功能：

        1. PDF导入模式
        • 支持导入手机中的PDF格式健康报告
        • 自动识别所有页面的健康数据
        • 通过AR技术展示分析结果

        2. 3D人体模型
        • 展示3D人体模型
        • 通过AR技术展示健康数据
        • 支持模型旋转和交互
        """
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let pdfButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Vision分析", for: .normal)
        button.setImage(UIImage(systemName: "doc.text"), for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        return button
    }()
    
    private let tesseractButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Tesseract分析", for: .normal)
        button.setImage(UIImage(systemName: "doc.text.magnifyingglass"), for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        return button
    }()
    
    private let historyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("历史报告", for: .normal)
        button.setImage(UIImage(systemName: "clock.arrow.circlepath"), for: .normal)
        button.backgroundColor = .systemIndigo
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        return button
    }()
    
    private let bodyModelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("3D人体模型", for: .normal)
        button.setImage(UIImage(systemName: "figure.stand"), for: .normal)
        button.backgroundColor = .systemPurple
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        navigationController?.navigationBar.isHidden = true
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        [titleLabel, descriptionLabel, pdfButton, tesseractButton, historyButton, bodyModelButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            pdfButton.bottomAnchor.constraint(equalTo: tesseractButton.topAnchor, constant: -16),
            pdfButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            pdfButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            pdfButton.heightAnchor.constraint(equalToConstant: 50),
            
            tesseractButton.bottomAnchor.constraint(equalTo: historyButton.topAnchor, constant: -16),
            tesseractButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tesseractButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tesseractButton.heightAnchor.constraint(equalToConstant: 50),
            
            historyButton.bottomAnchor.constraint(equalTo: bodyModelButton.topAnchor, constant: -16),
            historyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            historyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            historyButton.heightAnchor.constraint(equalToConstant: 50),
            
            bodyModelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            bodyModelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bodyModelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bodyModelButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        pdfButton.addTarget(self, action: #selector(pdfButtonTapped), for: .touchUpInside)
        tesseractButton.addTarget(self, action: #selector(tesseractButtonTapped), for: .touchUpInside)
        historyButton.addTarget(self, action: #selector(historyButtonTapped), for: .touchUpInside)
        bodyModelButton.addTarget(self, action: #selector(bodyModelButtonTapped), for: .touchUpInside)
    }
    
    @objc private func pdfButtonTapped() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
    
    @objc private func tesseractButtonTapped() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
    
    @objc private func historyButtonTapped() {
        let historyVC = HistoryReportsViewController()
        let navController = UINavigationController(rootViewController: historyVC)
        present(navController, animated: true)
    }
    
    @objc private func bodyModelButtonTapped() {
        let bodyVC = BodyViewController()
        navigationController?.pushViewController(bodyVC, animated: true)
    }
    
    // MARK: - UIDocumentPickerDelegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        // 根据按钮点击来源决定使用哪个视图控制器
        if controller.presentingViewController?.presentedViewController is TesseractViewController {
            let tesseractVC = TesseractViewController(pdfURL: url)
            let navController = UINavigationController(rootViewController: tesseractVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        } else {
            let pdfVC = PDFProcessViewController(pdfURL: url)
            let navController = UINavigationController(rootViewController: pdfVC)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: true)
        }
    }
}
