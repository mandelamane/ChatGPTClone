//
//  GptStruct.swift
//  GPTTest
//
//  Created by あまねすぎい on 2023/07/18.
//

import Foundation

struct GPTRequest: Codable {
    let model: String
    let stream: Bool
    let messages: [GPTContent]
}

struct GPTContent: Codable {
    let role: String?
    let content: String
}

struct GPTResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [GPTChoice]
}

struct GPTChoice: Codable {
    let index: Int
    let delta: GPTContent
    let finish_reason: String?
}
