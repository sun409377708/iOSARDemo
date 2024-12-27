import UIKit
import SceneKit

class NewViewController: UIViewController {
    
    private var sceneView: SCNView!
    private var cameraNode: SCNNode!
    private var modelNode: SCNNode!
    private var lastHighlightedNode: SCNNode?  // 跟踪上一个高亮的节点
    private var originalMaterials: [SCNNode: [SCNMaterial]] = [:] // 存储原始材质
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
    }
    
    private func setupScene() {
        // 创建场景视图
        sceneView = SCNView(frame: view.bounds)
        
        // 设置背景
        let backgroundImageView = UIImageView(frame: view.bounds)
        backgroundImageView.image = UIImage(named: "background2")
        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
        
        // 添加半透明遮罩层
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        view.addSubview(overlayView)
        view.sendSubviewToBack(overlayView)
        
        // 创建渐变背景层
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 0.1, green: 0.12, blue: 0.15, alpha: 0.7).cgColor,
            UIColor(red: 0.15, green: 0.18, blue: 0.22, alpha: 0.7).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // 设置场景视图
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = true
        
        // 创建场景
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
        
        // 添加环境光
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 100
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        scene.rootNode.addChildNode(ambientLightNode)
        
        // 添加方向光
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.intensity = 1000
        let directionalLightNode = SCNNode()
        directionalLightNode.light = directionalLight
        directionalLightNode.position = SCNVector3(x: 5, y: 5, z: 5)
        scene.rootNode.addChildNode(directionalLightNode)
        
        // 添加到视图
        view.addSubview(sceneView)
        
        // 添加点击手势识别器
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        // 加载模型
        loadModel()
    }
    
    private func loadModel() {
        guard let modelURL = Bundle.main.url(forResource: "ren", withExtension: "usdz") else {
            print("无法找到模型文件")
            return
        }
        
        do {
            let scene = try SCNScene(url: modelURL, options: [
                .preserveOriginalTopology: true,
                .checkConsistency: true
            ])
            
            // 获取模型的根节点
            if let modelNode = scene.rootNode.childNodes.first {
                self.modelNode = modelNode
                
                // 调整模型的位置和旋转
                modelNode.position = SCNVector3(0, -0.8, 0)
                modelNode.scale = SCNVector3(0.0125, 0.0125, 0.0125)
                
                // 添加到场景
                sceneView.scene?.rootNode.addChildNode(modelNode)
                
                // 添加缓慢旋转动画
                let rotationAnimation = CABasicAnimation(keyPath: "rotation")
                rotationAnimation.toValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: Float.pi * 2))
                rotationAnimation.duration = 20
                rotationAnimation.repeatCount = .infinity
                modelNode.addAnimation(rotationAnimation, forKey: "rotation")
                
                // 打印节点结构
                print("根节点名称: \(modelNode.name ?? "unnamed")")
                printNodeHierarchy(modelNode, level: 0)
            }
        } catch {
            print("加载模型失败: \(error.localizedDescription)")
        }
    }
    
    private func printNodeHierarchy(_ node: SCNNode, level: Int) {
        let indent = String(repeating: "  ", count: level)
        print("\(indent)节点: \(node.name ?? "unnamed")")
        print("\(indent)几何体: \(node.geometry?.description ?? "无")")
        print("\(indent)子节点数量: \(node.childNodes.count)")
        
        // 打印材质信息
        if let materials = node.geometry?.materials {
            print("\(indent)材质数量: \(materials.count)")
            for (index, material) in materials.enumerated() {
                print("\(indent)  材质\(index): \(material.name ?? "unnamed")")
            }
        }
        
        // 递归打印子节点
        for childNode in node.childNodes {
            printNodeHierarchy(childNode, level: level + 1)
        }
    }
    
    @objc private func handleTap(_ gestureRecognize: UITapGestureRecognizer) {
        let location = gestureRecognize.location(in: sceneView)
        
        // 进行命中测试，设置为可以检测到内部节点
        let hitResults = sceneView.hitTest(location, options: [
            .searchMode: SCNHitTestSearchMode.all.rawValue,  // 改为 .all 来检测所有节点
            .ignoreHiddenNodes: false,  // 不忽略隐藏节点
            .boundingBoxOnly: false,
            .ignoreChildNodes: false,  // 不忽略子节点
            .sortResults: true  // 按距离排序
        ])
        
        // 遍历所有命中的结果，找到第一个不是 Body 的器官
        for hitResult in hitResults {
            var targetNode = hitResult.node
            print("检测到节点: \(targetNode.name ?? "unnamed")")
            
            // 如果点击的是几何体节点，获取其父节点
            if targetNode.name?.hasSuffix("_geometry") ?? false {
                targetNode = targetNode.parent ?? targetNode
            }
            
            // 跳过 Body 节点
            if targetNode.name == "Body" {
                continue
            }
            
            // 如果点击的不是根节点，且有几何体子节点
            if targetNode != modelNode,
               let geometryNode = targetNode.childNodes.first(where: { $0.name?.hasSuffix("_geometry") ?? false }) {
                print("选中的器官: \(targetNode.name ?? "unnamed")")
                
                // 恢复之前高亮的节点
                if let lastNode = lastHighlightedNode,
                   let lastGeometryNode = lastNode.childNodes.first(where: { $0.name?.hasSuffix("_geometry") ?? false }),
                   lastNode != targetNode {
                    restoreOriginalMaterial(for: lastGeometryNode)
                }
                
                // 如果点击的是同一个节点，取消高亮
                if lastHighlightedNode == targetNode {
                    restoreOriginalMaterial(for: geometryNode)
                    lastHighlightedNode = nil
                } else {
                    // 高亮新节点
                    highlightNode(geometryNode)
                    lastHighlightedNode = targetNode
                }
                
                // 找到合适的节点后退出循环
                break
            }
        }
    }
    
    private func highlightNode(_ node: SCNNode) {
        guard let geometry = node.geometry else { return }
        
        // 保存原始材质
        if originalMaterials[node] == nil {
            originalMaterials[node] = geometry.materials
            
            // 为每个材质创建高亮版本
            let highlightMaterials = geometry.materials.map { originalMaterial -> SCNMaterial in
                let highlightMaterial = SCNMaterial()
                
                // 设置为明亮的红色
                let brightRed = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
                highlightMaterial.diffuse.contents = brightRed
                highlightMaterial.specular.contents = UIColor.white
                
                // 增强发光效果
                highlightMaterial.emission.contents = brightRed
                highlightMaterial.emission.intensity = 2.0
                
                // 设置材质属性
                highlightMaterial.transparency = 1.0
                highlightMaterial.lightingModel = .physicallyBased
                highlightMaterial.metalness.contents = 0.8
                highlightMaterial.roughness.contents = 0.2
                
                // 增加环境光遮蔽
                highlightMaterial.ambientOcclusion.intensity = 0.5
                
                return highlightMaterial
            }
            
            // 应用高亮材质
            geometry.materials = highlightMaterials
            
            // 添加轻微的放大动画
            let pulseAction = SCNAction.sequence([
                SCNAction.scale(to: 1.03, duration: 0.1),
                SCNAction.scale(to: 1.0, duration: 0.1)
            ])
            node.runAction(pulseAction)
        }
    }
    
    private func restoreOriginalMaterial(for node: SCNNode) {
        if let originalMaterial = originalMaterials[node] {
            // 恢复原始材质
            node.geometry?.materials = originalMaterial
            originalMaterials.removeValue(forKey: node)
            
            // 添加轻微的缩小动画
            let pulseAction = SCNAction.sequence([
                SCNAction.scale(to: 0.98, duration: 0.1),
                SCNAction.scale(to: 1.0, duration: 0.1)
            ])
            node.runAction(pulseAction)
        }
    }
}
