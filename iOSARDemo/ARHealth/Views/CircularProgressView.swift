import UIKit

class CircularProgressView: UIView {
    private let progressLayer = CAShapeLayer()
    private let backgroundLayer = CAShapeLayer()
    private let rangeLayer = CAShapeLayer()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = UIColor(hex: "#00F5FF")
        return label
    }()
    
    private let unitLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = UIColor(hex: "#00F5FF").withAlphaComponent(0.7)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // 添加标签
        addSubview(valueLabel)
        addSubview(unitLabel)
        
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            valueLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -10),
            
            unitLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            unitLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 4)
        ])
        
        // 设置层
        layer.addSublayer(backgroundLayer)
        layer.addSublayer(rangeLayer)
        layer.addSublayer(progressLayer)
        
        backgroundLayer.fillColor = nil
        backgroundLayer.strokeColor = UIColor(white: 0.2, alpha: 1.0).cgColor
        backgroundLayer.lineWidth = 6
        
        rangeLayer.fillColor = nil
        rangeLayer.strokeColor = UIColor(hex: "#00F5FF").withAlphaComponent(0.2).cgColor
        rangeLayer.lineWidth = 6
        
        progressLayer.fillColor = nil
        progressLayer.strokeColor = UIColor(hex: "#00F5FF").cgColor
        progressLayer.lineWidth = 6
        progressLayer.lineCap = .round
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - progressLayer.lineWidth / 2
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi
        
        let circularPath = UIBezierPath(arcCenter: center,
                                      radius: radius,
                                      startAngle: startAngle,
                                      endAngle: endAngle,
                                      clockwise: true)
        
        backgroundLayer.path = circularPath.cgPath
        rangeLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath
    }
    
    func setProgress(_ value: CGFloat, range: ClosedRange<CGFloat>, unit: String) {
        // 计算进度
        let minValue = range.lowerBound
        let maxValue = range.upperBound
        let progress = (value - minValue) / (maxValue - minValue)
        
        // 设置进度动画
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = progress
        animation.duration = 1.0
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        progressLayer.strokeEnd = progress
        progressLayer.add(animation, forKey: "progressAnimation")
        
        // 设置范围层的开始和结束
        let rangeStart = 0.0
        let rangeEnd = 1.0
        rangeLayer.strokeStart = rangeStart
        rangeLayer.strokeEnd = rangeEnd
        
        // 更新标签
        valueLabel.text = String(format: "%.1f", value)
        unitLabel.text = unit
        
        // 设置颜色
        if value < minValue {
            progressLayer.strokeColor = UIColor.systemRed.cgColor
        } else if value > maxValue {
            progressLayer.strokeColor = UIColor.systemRed.cgColor
        } else {
            progressLayer.strokeColor = UIColor(hex: "#00F5FF").cgColor
        }
    }
}
