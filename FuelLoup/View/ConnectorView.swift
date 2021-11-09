//
//  ConnectorView.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 12/10/2021.
//

import UIKit

final class ConnectorView: UIView {
    
    // MARK: - IB
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var typeValueLabel: UILabel!
    @IBOutlet weak var powerValueLabel: UILabel!
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("ConnectorView", owner: self, options: nil)
        addSubview(contentView)
        
        setupLayout()
    }
    
    // MARK: - Setup
    
    private func setupLayout() {
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        contentView.layer.borderWidth = 0.5
        contentView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        contentView.layer.cornerRadius = 10
    }

}
