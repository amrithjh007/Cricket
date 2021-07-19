//
//  CRNewsDetailViewController.swift
//  cricket
//
//  Created by Amrith J H on 15/07/21.
//

import UIKit
import Kingfisher

class CRNewsDetailViewController: UIViewController {
    @IBOutlet weak var webPublicationDateLabel: UILabel!
    @IBOutlet weak var webPublicationTitleLabel: UILabel!
    @IBOutlet weak var webUrlLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var newsImageView: UIImageView!
    @IBOutlet weak var sectionNameLabel: UILabel!
    @IBOutlet weak var contentScrollView: UIScrollView!
    
    var url : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBasicUI()
        addGestureRecogniserToLabel()
    }
    
    //MARK: Gesture recogniser for URL
    func  addGestureRecogniserToLabel() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapLabel(_ : )))
        webUrlLabel.isUserInteractionEnabled = true
        webUrlLabel.addGestureRecognizer(tap)
    }
    
    //MARK: Open URL in safari
    @objc func tapLabel(_ sender: UITapGestureRecognizer){
        if let url = url{
            let webUrl = URL(string: url)
            var request = URLRequest(url: webUrl!)
            request.addValue(Constants.apiKey, forHTTPHeaderField: "")
            self.openSafariModalWith(url: webUrl!)
        }
    }

    func configureBasicUI(){
        webUrlLabel.isUserInteractionEnabled = true
    }
    
    
    func downloadImage(url: String){
        let url = URL(string: url)
        let processor = DownsamplingImageProcessor(size: newsImageView.bounds.size)
                     |> RoundCornerImageProcessor(cornerRadius: 0)
        newsImageView.kf.indicatorType = .activity
        newsImageView.kf.setImage(
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
    
}

extension UILabel {
    //MARK: Adding line spacing for label
    func addLineSpacing(text: String){
        let attributedString = NSMutableAttributedString(string: text)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
        self.attributedText = attributedString
    }
}
