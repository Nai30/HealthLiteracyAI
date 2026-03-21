//
//  APIConfig.swift
//  HealthLiteracyAI
//
//  Created by Naima Marseille on 3/19/26.
//


import Foundation

struct APIConfig {
    static var geminiKey: String {
        // 1. Find the file path for Secrets.plist
        guard let filePath = Bundle.main.path(forResource: "secrets", ofType: "plist") else {
            print("Error: Could not find Secrets.plist")
            return ""
        }
        
        // 2. Load the file into a dictionary
        let plist = NSDictionary(contentsOfFile: filePath)
        
        // 3. Grab the value for the key "API" (make sure this matches exactly!)
        guard let value = plist?.object(forKey: "API") as? String else {
            print("Error: Could not find key 'API' in secrets.plist")
            return ""
        }
        
        return value
    }
}
