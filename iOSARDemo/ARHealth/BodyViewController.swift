import UIKit
import SceneKit

class BodyViewController: UIViewController {
    
    // MARK: - Properties
    private var sceneView: SCNView!
    private var cameraNode: SCNNode!
    private var bodyNode: SCNNode!
    private var dataView: UIView!
    private var annotations: [SCNNode] = []  // 存储标注节点
    private var lastHighlightedNode: SCNNode?  // 跟踪上一个高亮的节点
    private var originalMaterials: [SCNNode: [SCNMaterial]] = [:] // 存储原始材质
    
    // 存储分类后的数据
    private var generalExams: [HealthMetric] = []   // 一般检查
    private var bloodRoutine: [HealthMetric] = []   // 血常规
    private var urineRoutine: [HealthMetric] = []   // 尿常规
    
    private enum DataType: Int {
        case general = 0
        case blood
        case urine
    }
    
    
    private let gridView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        
        // 添加网格渐变
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(hex: "#00F5FF").withAlphaComponent(0.1).cgColor,
            UIColor(hex: "#00F5FF").withAlphaComponent(0.05).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        view.layer.addSublayer(gradientLayer)
        
        // 添加网格线
        let gridLayer = CAShapeLayer()
        let path = UIBezierPath()
        let spacing: CGFloat = 40
        for x in stride(from: 0, through: UIScreen.main.bounds.width, by: spacing) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: UIScreen.main.bounds.height))
        }
        for y in stride(from: 0, through: UIScreen.main.bounds.height, by: spacing) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: UIScreen.main.bounds.width, y: y))
        }
        gridLayer.path = path.cgPath
        gridLayer.strokeColor = UIColor(hex: "#00F5FF").withAlphaComponent(0.1).cgColor
        gridLayer.lineWidth = 0.5
        view.layer.addSublayer(gridLayer)
        
        return view
    }()
    
    private let segmentedControl: UISegmentedControl = {
        let items = ["常规项", "血常规", "尿常规"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.backgroundColor = UIColor(hex: "#00F5FF").withAlphaComponent(0.1)
        control.selectedSegmentTintColor = UIColor(hex: "#00F5FF").withAlphaComponent(0.3)
        
        // 设置文字颜色
        let normalTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(hex: "#00F5FF").withAlphaComponent(0.6)]
        let selectedTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(hex: "#00F5FF")]
        control.setTitleTextAttributes(normalTextAttributes, for: .normal)
        control.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        
        return control
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupScene()
        setupSegmentedControl()
        setupDataView()
        setupGestureRecognizers()
        loadLatestReport()
        updateDataDisplay(for: .general)
        
        // 添加数据更新通知监听
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleReportUpdate),
            name: .healthReportUpdated,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleReportUpdate() {
        loadLatestReport()
        updateDataDisplay(for: DataType(rawValue: segmentedControl.selectedSegmentIndex) ?? .general)
    }
    
    // MARK: - Data Loading
    private func loadLatestReport() {
        // 清空现有数据
        generalExams.removeAll()
        bloodRoutine.removeAll()
        urineRoutine.removeAll()
        
        // 从 HealthReportManager 获取最新报告
        if let report = HealthReportManager.shared.getAllReports().first {
            // 分类数据
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
    }
    
    // MARK: - Setup UI
    private func setupBackground() {
        
        // 添加网格视图
        view.addSubview(gridView)
        gridView.frame = view.bounds
        
        // 更新网格渐变
        if let gradientLayer = gridView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = view.bounds
        }
    }
    
    private func setupSegmentedControl() {
        view.addSubview(segmentedControl)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            segmentedControl.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    @objc private func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        guard let dataType = DataType(rawValue: sender.selectedSegmentIndex) else { return }
        updateDataDisplay(for: dataType)
    }
    
    private func setupDataView() {
        // 添加 scrollView
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 6), // 向左移动10点
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        // 添加 stackView 到 scrollView
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    private func updateDataDisplay(for type: DataType) {
        // 移除现有的视图
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 根据类型选择数据
        let metrics: [HealthMetric]
        switch type {
        case .general:
            metrics = generalExams
        case .blood:
            metrics = bloodRoutine
        case .urine:
            metrics = urineRoutine
        }
        
        // 添加数据卡片
        for metric in metrics {
            let card = HealthDataCard(title: metric.type)
            card.configure(with: metric)
            stackView.addArrangedSubview(card)
            
            // 设置卡片的高度约束为自适应
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        }
    }
    
    // MARK: - Scene Setup
    private func setupScene() {
        sceneView = SCNView(frame: view.bounds)
        
        // 添加背景图片
        let backgroundImageView = UIImageView(frame: view.bounds)
        backgroundImageView.image = UIImage(named: "background2")
        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
        
        // 添加半透明遮罩层，增加深度感
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        view.addSubview(overlayView)
        view.sendSubviewToBack(overlayView)
        
        // 创建渐变背景层
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 0.1, green: 0.12, blue: 0.15, alpha: 0.7).cgColor,  // 半透明深蓝灰色
            UIColor(red: 0.15, green: 0.18, blue: 0.22, alpha: 0.7).cgColor  // 半透明稍浅的蓝灰色
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        
        // 将渐变层添加到视图最底层
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // 设置场景视图背景为透明
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = false

        // 设置场景
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.allowsCameraControl = true

        // 设置相机
        let camera = SCNCamera()
        camera.zNear = 0.1
        camera.zFar = 100
        camera.fieldOfView = 60

        cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
        scene.rootNode.addChildNode(cameraNode)

        // 添加到视图层级
        view.addSubview(sceneView)

        loadUSDZModel()
        setupAdvancedRendering()
    }

    private func setupGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
    }

    @objc private func handleTap(_ gestureRecognize: UITapGestureRecognizer) {
        let location = gestureRecognize.location(in: sceneView)
        
        // 进行命中测试
        let hitResults = sceneView.hitTest(location, options: [
            .searchMode: SCNHitTestSearchMode.closest.rawValue,
            .ignoreHiddenNodes: true
        ])
        
        if let firstHit = hitResults.first {
            // 获取点击的节点
            let node = firstHit.node
            
            // 如果点击了新的节点，恢复上一个高亮节点的材质
            if let lastNode = lastHighlightedNode, lastNode != node {
                restoreOriginalMaterial(for: lastNode)
            }
            
            // 如果点击的是同一个节点，取消高亮
            if lastHighlightedNode == node {
                restoreOriginalMaterial(for: node)
                lastHighlightedNode = nil
            } else {
                // 高亮新节点
                highlightNode(node)
                lastHighlightedNode = node
            }
            
            // 打印节点信息
            if let name = node.name {
                print("Tapped node: \(name)")
            }
        }
    }
    
    private func highlightNode(_ node: SCNNode) {
        // 保存原始材质
        if originalMaterials[node] == nil {
            originalMaterials[node] = node.geometry?.materials ?? []
        }
        
        // 创建高亮材质
        let highlightMaterial = SCNMaterial()
        highlightMaterial.diffuse.contents = UIColor.red.withAlphaComponent(0.7)
        highlightMaterial.transparency = 0.7
        
        // 应用高亮材质
        node.geometry?.materials = [highlightMaterial]
        
        // 添加高亮动画
        let pulseAction = SCNAction.sequence([
            SCNAction.scale(to: 1.05, duration: 0.1),
            SCNAction.scale(to: 1.0, duration: 0.1)
        ])
        node.runAction(pulseAction)
    }
    
    private func restoreOriginalMaterial(for node: SCNNode) {
        // 恢复原始材质
        if let originalMaterial = originalMaterials[node] {
            node.geometry?.materials = originalMaterial
            originalMaterials.removeValue(forKey: node)
        }
    }

    private func loadUSDZModel() {
        guard let modelURL = Bundle.main.url(forResource: "ball_girl", withExtension: "usdz") else {
            print("")
            return
        }

        do {
            let scene = try SCNScene(url: modelURL, options: [
                .preserveOriginalTopology: true,
                .checkConsistency: true
            ])

            let modelNode = SCNNode()

            // 将所有子节点添加到新的根节点
            for child in scene.rootNode.childNodes {
                modelNode.addChildNode(child)
            }

            bodyNode = modelNode

            // 设置模型比例和位置
            modelNode.scale = SCNVector3(0.0125, 0.0125, 0.0125)
            modelNode.position = SCNVector3(x: -0.4, y: -1.0, z: 0)  // 将模型移到左侧

            // 添加到场景中
            sceneView.scene?.rootNode.addChildNode(modelNode)

            // 添加缓慢旋转动画
            let rotationAnimation = CABasicAnimation(keyPath: "rotation")
            rotationAnimation.toValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: Float.pi * 2))
            rotationAnimation.duration = 20
            rotationAnimation.repeatCount = .infinity
            modelNode.addAnimation(rotationAnimation, forKey: "rotation")

            // 设置环境光照
            sceneView.scene?.lightingEnvironment.intensity = 1.0
        } catch {
            print(" 加载模型失败: \(error)")
        }
    }

    private func setupAdvancedRendering() {
        // 
        sceneView.antialiasingMode = .multisampling4X
        sceneView.isJitteringEnabled = true

        // PBR 
        sceneView.scene?.lightingEnvironment.contents = UIColor.white
        sceneView.scene?.lightingEnvironment.intensity = 1.0
    }
}
