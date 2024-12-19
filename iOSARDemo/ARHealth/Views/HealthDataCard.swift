import UIKit

class HealthDataCard: UIView {
    
    // MARK: - Properties
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(hex: "#00F5FF").withAlphaComponent(0.3).cgColor
        
        // 添加内部阴影
        let innerShadow = CALayer()
        innerShadow.frame = view.bounds
        innerShadow.backgroundColor = UIColor.clear.cgColor
        innerShadow.shadowColor = UIColor(hex: "#00F5FF").cgColor
        innerShadow.shadowOffset = CGSize(width: 0, height: 1)
        innerShadow.shadowOpacity = 0.2
        innerShadow.shadowRadius = 4
        innerShadow.cornerRadius = 16
        view.layer.addSublayer(innerShadow)
        
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(hex: "#00F5FF")
        return label
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()
    
    private let glowLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(hex: "#00F5FF").withAlphaComponent(0.2).cgColor,
            UIColor(hex: "#00F5FF").withAlphaComponent(0.05).cgColor
        ]
        layer.locations = [0.0, 1.0]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        layer.cornerRadius = 16
        return layer
    }()
    
    // MARK: - Initialization
    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupUI()
        setupAnimations()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .clear
        layer.shadowColor = UIColor(hex: "#00F5FF").cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.2
        
        // Add glow effect
        layer.insertSublayer(glowLayer, at: 0)
        
        // Setup container view with flexible height
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 1),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1)
        ])
        
        // Setup title label
        containerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12)
        ])
        
        // Setup stack view with flexible height
        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
        
        // Add gesture recognizer for touch interaction
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        glowLayer.frame = bounds
        updateShadowPath()
    }
    
    private func updateShadowPath() {
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 16).cgPath
        layer.shadowColor = UIColor(hex: "#00F5FF").cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = .zero
        layer.shadowRadius = 8
    }
    
    // MARK: - Animations
    private func setupAnimations() {
        // Initial state
        alpha = 0
        transform = CGAffineTransform(translationX: 50, y: 0)
        
        // Animate in
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.alpha = 1
            self.transform = .identity
        }
        
        // Add floating animation
        addFloatingAnimation()
    }
    
    private func addFloatingAnimation() {
        let animation = CABasicAnimation(keyPath: "transform.translation.y")
        animation.fromValue = 0
        animation.toValue = -5
        animation.duration = 1.5
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        layer.add(animation, forKey: "floating")
    }
    
    // MARK: - Touch Handling
    @objc private func handleTap() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5) {
            self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.transform = .identity
            }
        }
    }
    
    // MARK: - Public Methods
    func addMetric(_ metric: HealthMetric) {
        let metricView = MetricItemView(metric: metric)
        stackView.addArrangedSubview(metricView)
    }
    
    func clearMetrics() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
    
    func configure(with metric: HealthMetric) {
        titleLabel.text = metric.type
        
        // 移除现有的视图
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 创建新的度量视图
        let metricView = MetricItemView(metric: metric)
        stackView.addArrangedSubview(metricView)
        
        // 确保视图能够自适应高度
        metricView.setContentHuggingPriority(.required, for: .vertical)
        metricView.setContentCompressionResistancePriority(.required, for: .vertical)
        
        // 更新卡片颜色
        glowLayer.colors = [
            UIColor(hex: metric.color).cgColor,
            UIColor(hex: metric.color).withAlphaComponent(0.6).cgColor
        ]
    }
}

// MARK: - MetricItemView
private class MetricItemView: UIView {
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()
    
    private let headerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor(hex: "#00F5FF").withAlphaComponent(0.9)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.numberOfLines = 0
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .right
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()
    
    private let referenceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11)
        label.textColor = UIColor(hex: "#00F5FF").withAlphaComponent(0.6)
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
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
        // 添加主要的垂直堆栈视图
        addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加水平堆栈视图到主堆栈视图
        contentStackView.addArrangedSubview(headerStackView)
        
        // 添加标题和值到水平堆栈视图
        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(valueLabel)
        
        // 添加参考值标签到主堆栈视图
        if let text = referenceLabel.text, !text.isEmpty {
            contentStackView.addArrangedSubview(referenceLabel)
        }
        
        // 设置约束
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // 设置内容压缩优先级
        contentStackView.setContentHuggingPriority(.required, for: .vertical)
        contentStackView.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    func configure(with metric: HealthMetric) {
        titleLabel.text = metric.type
        
        // 格式化值和单位
        let valueText = "\(metric.value) \(metric.unit)"
        let attributedValue = NSMutableAttributedString(string: valueText)
        
        // 为单位设置较小的字体
        if let unitRange = valueText.range(of: metric.unit) {
            let nsRange = NSRange(unitRange, in: valueText)
            attributedValue.addAttribute(.font, value: UIFont.systemFont(ofSize: 16, weight: .medium), range: nsRange)
        }
        
        valueLabel.attributedText = attributedValue
        
        if !metric.reference.isEmpty {
            referenceLabel.text = "参考范围: \(metric.reference)"
            referenceLabel.isHidden = false
            contentStackView.addArrangedSubview(referenceLabel)
        } else {
            referenceLabel.isHidden = true
            referenceLabel.removeFromSuperview()
        }
        
        // 根据内容调整布局
        setNeedsLayout()
        layoutIfNeeded()
        
        // 检查是否需要缩小字体
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 检查标题是否需要缩小字体
            if self.titleLabel.frame.height > 40 {
                self.titleLabel.font = .systemFont(ofSize: 11, weight: .medium)
            }
            
            // 检查值是否需要缩小字体
            if self.valueLabel.frame.width > self.frame.width * 0.4 {
                if let text = self.valueLabel.attributedText?.string {
                    let newAttributedValue = NSMutableAttributedString(string: text)
                    if let unitRange = text.range(of: metric.unit) {
                        let nsRange = NSRange(unitRange, in: text)
                        newAttributedValue.addAttribute(.font, value: UIFont.systemFont(ofSize: 13, weight: .medium), range: nsRange)
                        newAttributedValue.addAttribute(.font, value: UIFont.systemFont(ofSize: 20, weight: .bold), range: NSRange(location: 0, length: nsRange.location))
                    }
                    self.valueLabel.attributedText = newAttributedValue
                }
            }
            
            // 检查参考值是否需要缩小字体
            if !metric.reference.isEmpty && self.referenceLabel.frame.height > 30 {
                self.referenceLabel.font = .systemFont(ofSize: 9)
            }
        }
        
        // Set value label color based on hint
        switch metric.hint {
        case "偏高":
            valueLabel.textColor = UIColor(hex: "#FF4B4B")
        case "偏低":
            valueLabel.textColor = UIColor(hex: "#4A90E2")
        default:
            valueLabel.textColor = UIColor(hex: "#4CAF50")
        }
    }
}
