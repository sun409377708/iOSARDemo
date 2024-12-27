import UIKit
import SceneKit

class NewViewController: UIViewController {
    
    private var sceneView: SCNView!
    private var cameraNode: SCNNode!
    private var modelNode: SCNNode!
    private var lastHighlightedNode: SCNNode?  // 跟踪上一个高亮的节点
    private var originalMaterials: [SCNNode: [SCNMaterial]] = [:] // 存储原始材质
    private var clonedNode: SCNNode? // 存储复制出来的器官节点
    
    // 添加一个属性来存储初始相机位置
    private var initialCameraPosition: SCNVector3?
    private var initialCameraForward: SCNVector3?
    
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
                addRotationAnimation(to: modelNode)
                
                // 打印节点结构
                print("根节点名称: \(modelNode.name ?? "unnamed")")
                printNodeHierarchy(modelNode, level: 0)
                
                // 保存初始相机位置和方向
                initialCameraPosition = sceneView.pointOfView?.position
                initialCameraForward = sceneView.pointOfView?.worldFront
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
            .searchMode: SCNHitTestSearchMode.all.rawValue,  // 检测所有节点
            .ignoreHiddenNodes: false,  // 不忽略隐藏节点
            .boundingBoxOnly: false,    // 使用精确的几何体检测
            .ignoreChildNodes: false,   // 不忽略子节点
            .sortResults: true          // 按距离排序
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
                
                // 停止人体模型的旋转动画
                modelNode.removeAnimation(forKey: "rotation")
                
                // 如果点击的是同一个节点，取消高亮
                if lastHighlightedNode == targetNode {
                    restoreOriginalMaterial(for: geometryNode)
                    lastHighlightedNode = nil
                    // 移除克隆的节点
                    clonedNode?.removeFromParentNode()
                    clonedNode = nil
                    
                    // 恢复人体模型的旋转动画
                    addRotationAnimation(to: modelNode)
                } else {
                    // 恢复之前高亮的节点
                    if let lastNode = lastHighlightedNode,
                       let lastGeometryNode = lastNode.childNodes.first(where: { $0.name?.hasSuffix("_geometry") ?? false }),
                       lastNode != targetNode {
                        restoreOriginalMaterial(for: lastGeometryNode)
                        // 移除之前克隆的节点
                        clonedNode?.removeFromParentNode()
                        clonedNode = nil
                    }
                    
                    // 先创建克隆体
                    cloneAndShowOrgan(targetNode)
                    
                    // 延迟一帧再执行高亮，避免动画影响克隆体位置
                    DispatchQueue.main.async {
                        // 高亮新节点
                        self.highlightNode(geometryNode)
                        self.lastHighlightedNode = targetNode
                    }
                }
                
                // 找到合适的节点后退出循环
                break
            }
        }
    }
    
    // 添加新的辅助方法来添加旋转动画
    private func addRotationAnimation(to node: SCNNode) {
        let rotationAnimation = CABasicAnimation(keyPath: "rotation")
        rotationAnimation.toValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: Float.pi * 2))
        rotationAnimation.duration = 15
        rotationAnimation.repeatCount = .infinity
        node.addAnimation(rotationAnimation, forKey: "rotation")
    }
    
    private func cloneAndShowOrgan(_ organNode: SCNNode) {
        // 移除之前的克隆节点（如果有）
        clonedNode?.removeFromParentNode()
        
        // 获取原始几何体节点
        guard let originalGeometryNode = organNode.childNodes.first(where: { $0.name?.hasSuffix("_geometry") ?? false }),
              let originalGeometry = originalGeometryNode.geometry else {
            return
        }
        
        // 创建几何体的副本
        let clonedGeometry = originalGeometry.copy() as! SCNGeometry
        clonedGeometry.materials = originalGeometry.materials.map { $0.copy() as! SCNMaterial }
        
        // 创建新的节点
        let clonedOrgan = SCNNode(geometry: clonedGeometry)
        clonedOrgan.name = organNode.name
        
        // 设置固定的位置（相对于场景原点）
        let fixedPosition = SCNVector3(0, -0.8, 1.0)  // x: 中心, y: 降低位置, z: 向前
        clonedOrgan.position = fixedPosition
        
        // 设置克隆节点的朝向（面向相机）
        clonedOrgan.constraints = [SCNBillboardConstraint()]
        
        // 设置克隆节点的缩放
        clonedOrgan.scale = SCNVector3(0.0125, 0.0125, 0.0125)
        
        // 添加旋转动画
        let rotationAnimation = CABasicAnimation(keyPath: "rotation")
        rotationAnimation.toValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: Float.pi * 2))
        rotationAnimation.duration = 10
        rotationAnimation.repeatCount = .infinity
        clonedOrgan.addAnimation(rotationAnimation, forKey: "rotation")
        
        // 存储克隆的节点
        clonedNode = clonedOrgan
        
        // 直接添加到场景的根节点
        sceneView.scene?.rootNode.addChildNode(clonedOrgan)
        
        // 添加淡入动画
        clonedOrgan.opacity = 0
        clonedOrgan.runAction(SCNAction.fadeIn(duration: 0.3))
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
