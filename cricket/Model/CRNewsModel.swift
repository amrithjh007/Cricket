//
//  CRNewsModel.swift
//  cricket
//
//  Created by Amrith J H on 16/07/21.
//

import Foundation

// MARK: - CRNewsModel
struct CRNewsModel: Codable {
    let response: Response1
}

// MARK: - Response
struct Response1: Codable {
    let status, userTier: String
    let total, startIndex, pageSize, currentPage: Int
    let pages: Int
    let orderBy: String
    let results: [Result1]
}

// MARK: - Result
struct Result1: Codable {
    let id: String
    let type: TypeEnum
    let sectionId: String
    let sectionName: String
    let webPublicationDate: String
    let webTitle: String
    let webUrl, apiUrl: String
    let isHosted: Bool
    let pillarId: PillarID
    let pillarName: PillarName

    enum CodingKeys: String, CodingKey {
        case id, type
        case sectionId
        case sectionName, webPublicationDate, webTitle
        case webUrl
        case apiUrl
        case isHosted
        case pillarId
        case pillarName
    }
}

enum PillarID: String, Codable {
    case pillarNews = "pillar/news"
    case pillarSport = "pillar/sport"
    case pillarOpinion = "pillar/opinion"
    case pillarArts = "pillar/arts"
    case pillarLifeStyle = "pillar/lifestyle"
}

enum PillarName: String, Codable {
    case news = "News"
    case sport = "Sport"
    case opinion = "Opinion"
    case arts = "Arts"
    case lifeStyle = "Lifestyle"
}

enum TypeEnum: String, Codable {
    case article = "article"
    case liveblog = "liveblog"
}
