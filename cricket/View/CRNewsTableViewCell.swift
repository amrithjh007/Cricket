//
//  CRNewsTableViewCell.swift
//  cricket
//
//  Created by Amrith J H on 15/07/21.
//

import UIKit
import Kingfisher

class CRNewsTableViewCell: UITableViewCell {
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var shadowView: UIView!
    
    var isCellDisplayed: Bool = false
    var setupShadowDone: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupShadow()
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 3, left: 0, bottom: 3, right: 0))
        contentView.layer.cornerRadius = 10
    }
    
    func setupShadow(){
        if setupShadowDone { return }
        shadowView.layer.cornerRadius = 8
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 3)
        shadowView.layer.shadowRadius = 3
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 8, height: 8)).cgPath
        shadowView.layer.shouldRasterize = true
        shadowView.layer.rasterizationScale = UIScreen.main.scale
        setupShadowDone = true
        shadowView.backgroundColor = .clear
    }
    
    func configure(result: Result1){
        
        let originalDate = result.webPublicationDate
        var newDate = ""
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ"
        let convertStringToDate = dateformatter.date(from: originalDate)
        dateformatter.dateFormat = "dd MMMM, yyyy HH:mm"
        newDate = dateformatter.string(from: convertStringToDate!)
        
        self.dateLabel.text = "\(newDate)"
        self.titleLabel.text = result.webTitle
    }
    
    func downloadImage(url: String){
        let url = URL(string: url)
        let processor = DownsamplingImageProcessor(size: cellImageView.bounds.size)
                     |> RoundCornerImageProcessor(cornerRadius: 0)
        cellImageView.kf.indicatorType = .activity
        cellImageView.kf.setImage(
            with: url,
            placeholder: UIImage(named: "placeholderImage"),
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(1)),
                .cacheOriginalImage
            ])
        {
            result in
            switch result {
            case .success(let value):
                print("Task done for: \(value.source.url?.absoluteString ?? "")")
            case .failure(let error):
                print("Job failed: \(error.localizedDescription)")
            }
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
