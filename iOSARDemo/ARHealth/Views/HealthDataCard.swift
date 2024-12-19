import UIKit

class HealthDataCard: UIView {
    
    // MARK: - Properties
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.1, alpha: 0.7)
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
        
        // 添加内部阴影
        let innerShadow = CALayer()
        innerShadow.frame = view.bounds
        innerShadow.backgroundColor = UIColor.clear.cgColor
        innerShadow.shadowColor = UIColor.white.cgColor
        innerShadow.shadowOffset = CGSize(width: 0, height: 1)
        innerShadow.shadowOpacity = 0.1
        innerShadow.shadowRadius = 3
        innerShadow.cornerRadius = 12
        view.layer.addSublayer(innerShadow)
        
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.9)
        return label
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()
    
    private let glowLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        layer.cornerRadius = 12
        layer.opacity = 0.5
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
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.3
        
        // Add glow effect
        layer.insertSublayer(glowLayer, at: 0)
        
        // Setup container view
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
        
        // Setup stack view
        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
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
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 12).cgPath
        layer.shadowColor = UIColor(hex: "#4A90E2").cgColor
        layer.shadowOpacity = 0.5
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
        
        // 创建并添加指标项
        let itemView = MetricItemView(metric: metric)
        stackView.addArrangedSubview(itemView)
        
        // 更新卡片颜色
        glowLayer.colors = [
            UIColor(hex: metric.color).cgColor,
            UIColor(hex: metric.color).withAlphaComponent(0.6).cgColor
        ]
    }
}

// MARK: - MetricItemView
private class MetricItemView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.9)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textAlignment = .right
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()
    
    private let referenceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11)
        label.textColor = .white.withAlphaComponent(0.6)
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
        // Add labels
        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(referenceLabel)
        
        // Setup constraints
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        referenceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: valueLabel.leadingAnchor, constant: -8),
            
            valueLabel.topAnchor.constraint(equalTo: topAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            referenceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            referenceLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            referenceLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            referenceLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func configure(with metric: HealthMetric) {
        titleLabel.text = metric.type
        valueLabel.text = "\(metric.value) \(metric.unit)"
        if !metric.reference.isEmpty {
            referenceLabel.text = "参考范围: \(metric.reference)"
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
