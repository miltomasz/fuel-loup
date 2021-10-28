//
//  ConnectorView.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 12/10/2021.
//

import UIKit

@IBDesignable
class ConnectorView: UIView {
    
    @IBInspectable var borderWidth: CGFloat = 0 {
            didSet {
                layer.borderWidth = borderWidth
            }
        }
    
    @IBInspectable var borderColor: UIColor? {
            didSet {
                layer.borderColor = borderColor?.cgColor
            }
        }
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
            didSet {
                layer.cornerRadius = cornerRadius
                layer.masksToBounds = cornerRadius > 0
            }
        }
    
    // MARK: - IB
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var typeValueLabel: UILabel!
    @IBOutlet weak var powerValueLabel: UILabel!
    
    // MARK: Initialization
    
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
        
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
//        contentView.layer.borderWidth = 0.5
//        contentView.layer.borderColor = UIColor.black.cgColor
//        contentView.layer.cornerRadius = 10
    }       

}
