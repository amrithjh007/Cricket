//
//  UIViewController+SafariServices.swift
//  cricket
//
//  Created by Amrith J H on 16/07/21.
//

import Foundation
import SafariServices

extension UIViewController {
    func openSafariModalWith(url: URL, readerView: Bool? = true) {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.modalPresentationStyle = .overFullScreen
        present(vc, animated: true)
    }
}
