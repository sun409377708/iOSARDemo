import UIKit
import SceneKit

class BodyViewController: UIViewController {

    private var sceneView: SCNView!
    private var bodyNode: SCNNode?
    private var dataView: UIView!
    private var annotations: [SCNNode] = []  // 存储标注节点
    private var lastHighlightedNode: SCNNode?  // 跟踪上一个高亮的节点
    private var originalMaterials: [SCNNode: [SCNMaterial]] = [:] // 存储原始材质

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupDataView()
        setupGestureRecognizers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 更新渐变层frame
        if let gradientLayer = view.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = view.bounds
        }
        
        // 更新数据视图中的渐变层
        if let gradientView = dataView.subviews.last {
            if let gradientLayer = gradientView.layer.sublayers?.first as? CAGradientLayer {
                gradientLayer.frame = gradientView.bounds
            }
        }
    }

    // MARK: - Setup

    private func setupScene() {
        sceneView = SCNView(frame: view.bounds)
        
        // 创建渐变背景层
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 0.1, green: 0.12, blue: 0.15, alpha: 1.0).cgColor,  // 深蓝灰色
            UIColor(red: 0.15, green: 0.18, blue: 0.22, alpha: 1.0).cgColor  // 稍浅的蓝灰色
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

        let cameraNode = SCNNode()
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
            print("❌ 模型文件未找到")
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
            modelNode.position = SCNVector3(x: -0.5, y: -1.0, z: 0)  // 将模型移到左侧

            // 添加到场景中
            sceneView.scene?.rootNode.addChildNode(modelNode)

            // 缓慢旋转动画
            let rotation = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 15))
            modelNode.runAction(rotation)

            // 设置环境光照
            sceneView.scene?.lightingEnvironment.intensity = 1.0
        } catch {
            print("❌ 加载模型失败: \(error)")
        }
    }

    private func setupDataView() {
        // 创建单个数据视图
        dataView = createDataView()
        view.addSubview(dataView)
        
        // 设置约束
        dataView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            dataView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            dataView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            dataView.widthAnchor.constraint(equalToConstant: 200)
        ])
        
        // 添加所有数据
        addHealthDataToView()
    }
    
    private func createDataView() -> UIView {
        let containerView = UIView()
        
        // 创建模糊效果
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(blurView)
        
        // 添加渐变层
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(white: 1.0, alpha: 0.1).cgColor,
            UIColor(white: 1.0, alpha: 0.05).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)
        
        // 创建一个用于渐变的视图
        let gradientView = UIView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.layer.addSublayer(gradientLayer)
        containerView.addSubview(gradientView)
        
        // 设置圆角和阴影
        containerView.layer.cornerRadius = 15
        containerView.layer.masksToBounds = false
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.3
        
        // 约束设置
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: containerView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            gradientView.topAnchor.constraint(equalTo: containerView.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // 确保渐变层大小随视图改变
        containerView.layer.masksToBounds = true
        
        return containerView
    }
    
    private func addHealthDataToView() {
        // 合并所有数据，添加一些异常值测试
        let healthData: [(title: String, value: Float, maxValue: Float, icon: String)] = [
            ("心率", 120, 200, "❤️"),     // 偏高
            ("血压", 85, 200, "🫀"),      // 偏低
            ("血糖", 6.8, 10, "🔴"),      // 偏高
            ("体温", 38.5, 45, "🌡️"),    // 偏高
            ("血氧", 93, 100, "💨"),      // 偏低
            ("压力", 45, 100, "🧠")       // 正常
        ]
        
        // 创建垂直堆叠视图
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加所有数据项
        for (title, value, maxValue, icon) in healthData {
            let itemView = createDataItemView(icon: icon, title: title, value: value, maxValue: maxValue)
            stackView.addArrangedSubview(itemView)
        }
        
        dataView.addSubview(stackView)
        
        // 设置堆叠视图约束
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: dataView.topAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: dataView.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: dataView.trailingAnchor, constant: -10),
            stackView.bottomAnchor.constraint(equalTo: dataView.bottomAnchor, constant: -10)
        ])
    }
    
    // 健康状态枚举
    private enum HealthStatus {
        case normal
        case high
        case low
        
        var color: UIColor {
            switch self {
            case .normal: return UIColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0) // 柔和的绿色
            case .high: return UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0)   // 柔和的红色
            case .low: return UIColor(red: 0.3, green: 0.7, blue: 0.9, alpha: 1.0)    // 柔和的蓝色
            }
        }
        
        var description: String {
            switch self {
            case .normal: return "正常"
            case .high: return "偏高"
            case .low: return "偏低"
            }
        }
    }
    
    private func getHealthStatus(for title: String, value: Float) -> HealthStatus {
        switch title {
        case "心率":
            if value < 60 { return .low }
            if value > 100 { return .high }
        case "血压":
            if value < 90 { return .low }
            if value > 140 { return .high }
        case "血糖":
            if value < 4.0 { return .low }
            if value > 6.1 { return .high }
        case "体温":
            if value < 36.0 { return .low }
            if value > 37.2 { return .high }
        case "血氧":
            if value < 95 { return .low }
        case "压力":
            if value > 80 { return .high }
        default:
            break
        }
        return .normal
    }
    
    private func createDataItemView(icon: String, title: String, value: Float, maxValue: Float) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 图标标签
        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = .systemFont(ofSize: 20)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 标题标签
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)  // 调整字体粗细
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 1  // 确保单行显示
        titleLabel.adjustsFontSizeToFitWidth = true  // 自动调整字体大小
        titleLabel.minimumScaleFactor = 0.8  // 最小缩放比例
        
        // 数值标签
        let valueLabel = UILabel()
        valueLabel.textColor = .white
        valueLabel.font = .systemFont(ofSize: 14, weight: .medium)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)  // 确保数值标签不被压缩
        
        // 状态标签
        let statusLabel = UILabel()
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 进度条背景
        let progressBackground = UIView()
        progressBackground.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        progressBackground.layer.cornerRadius = 3
        progressBackground.translatesAutoresizingMaskIntoConstraints = false
        
        // 给进度条背景添加内发光效果
        progressBackground.layer.shadowColor = UIColor.white.cgColor
        progressBackground.layer.shadowOffset = .zero
        progressBackground.layer.shadowRadius = 1
        progressBackground.layer.shadowOpacity = 0.1
        
        // 进度条
        let progressView = UIView()
        progressView.layer.cornerRadius = 3
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        // 给进度条添加发光效果
        progressView.layer.shadowColor = UIColor.white.cgColor
        progressView.layer.shadowOffset = .zero
        progressView.layer.shadowRadius = 2
        progressView.layer.shadowOpacity = 0.3
        
        // 获取健康状态
        let status = getHealthStatus(for: title, value: value)
        progressView.backgroundColor = status.color
        statusLabel.text = status.description
        statusLabel.textColor = status.color
        
        // 设置数值文本
        let formattedValue = String(format: "%.1f", value)
        valueLabel.text = formattedValue
        
        // 添加子视图
        containerView.addSubview(iconLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(valueLabel)
        containerView.addSubview(statusLabel)
        containerView.addSubview(progressBackground)
        progressBackground.addSubview(progressView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 70),  // 增加容器高度
            
            iconLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 30),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),  // 增加顶部间距
            titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 80),  // 限制标题宽度
            
            valueLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            valueLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            valueLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -8),
            
            statusLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),  // 增加间距
            
            progressBackground.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            progressBackground.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            progressBackground.heightAnchor.constraint(equalToConstant: 6),
            progressBackground.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            progressBackground.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8)  // 增加间距
        ])
        
        // 进度条宽度约束
        let progressWidth = progressView.widthAnchor.constraint(equalTo: progressBackground.widthAnchor, multiplier: CGFloat(value / maxValue))
        progressWidth.isActive = true
        
        // 添加进度条其他约束
        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: progressBackground.leadingAnchor),
            progressView.topAnchor.constraint(equalTo: progressBackground.topAnchor),
            progressView.bottomAnchor.constraint(equalTo: progressBackground.bottomAnchor)
        ])
        
        // 添加动画效果
        progressView.transform = CGAffineTransform(scaleX: 0, y: 1)
        UIView.animate(withDuration: 2.0,  // 延长动画时间
                      delay: 0,
                      usingSpringWithDamping: 0.7,
                      initialSpringVelocity: 0.3,
                      options: .curveEaseOut,
                      animations: {
            progressView.transform = .identity
        })
        
        // 数值变化动画
        let initialValue: Float = 0
        animateValue(label: valueLabel, from: initialValue, to: value, duration: 2.0)  // 延长动画时间
        
        return containerView
    }
    
    private func animateValue(label: UILabel, from: Float, to: Float, duration: TimeInterval) {
        let steps: Int = 20
        let stepDuration = duration / TimeInterval(steps)
        let stepValue = (to - from) / Float(steps)
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(i) * stepDuration) {
                let currentValue = from + stepValue * Float(i)
                label.text = String(format: "%.1f", currentValue)
            }
        }
    }

    private func setupAdvancedRendering() {
        // 基础渲染设置
        sceneView.antialiasingMode = .multisampling4X
        sceneView.isJitteringEnabled = true

        // 使用 PBR 渲染
        sceneView.scene?.lightingEnvironment.contents = UIColor.white
        sceneView.scene?.lightingEnvironment.intensity = 1.0
    }
}
