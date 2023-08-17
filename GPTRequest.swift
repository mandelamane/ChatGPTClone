//
//  GptRequest.swift
//  GPTTest
//
//  Created by あまねすぎい on 2023/07/18.
//

import Foundation

func request(chatContents: [GPTContent], gpt_type: String) async throws -> URLSession.AsyncBytes{
    let apiKey: String = OPENAI_ACCESS["apiKey"] ?? ""
    let orgId: String = OPENAI_ACCESS["orgId"] ?? ""
    
    guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
        throw NSError(domain: "URL error", code: -1)
    }
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.allHTTPHeaderFields = ["Authorization" : "Bearer \(apiKey)",
                               "OpenAI-Organization" : orgId,
                               "Content-Type" : "application/json"]
    
    urlRequest.httpBody = try? JSONEncoder().encode(GPTRequest(model: gpt_type, stream: true, messages: chatContents))

    
    guard let (stream, _) = try? await URLSession.shared.bytes(for: urlRequest) else {
        throw NSError(domain: "URLSession error", code: -1)
    }
    
    return stream
}
