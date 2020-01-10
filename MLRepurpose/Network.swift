//
//  Network.swift
//  MLRepurpose
//
//  Created by Jackson Ho on 1/8/20.
//  Copyright © 2020 Jackson Ho. All rights reserved.
//

import Foundation
import LinkPresentation
import SwiftSoup

struct ResultModel: Codable {
    let title: String
    let link: String
}

class NetworkManager {
    
    func searchApi(item_name: String, completion: @escaping (Result<[ResultModel], Error>) -> Void) {
        
        let headers = [
            "x-rapidapi-host": "google-search3.p.rapidapi.com",
            "x-rapidapi-key": API_KEY
        ]
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "google-search3.p.rapidapi.com"
        components.path = "/api/v1/search"
        components.queryItems = [
            URLQueryItem(name: "max_results", value: "30"),
            URLQueryItem(name: "q", value: "repurpose " + item_name)
        ]
        
        let request = NSMutableURLRequest(url: components.url!,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let data = data {
                do {
                    let resultData = try JSONDecoder().decode([ResultModel].self, from: data)
                    completion(.success(resultData))
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.success([]))
            }
        })
        dataTask.resume()
    }
}

