//
//  Bundle+Ext.swift
//  Leaf
//
//  Created by lincolnlaw on 2017/11/2.
//  Copyright © 2017年 lincolnlaw. All rights reserved.
//

import Foundation
public extension Bundle {
    var appName: String {
        if let displayName = infoDictionary?["CFBundleDisplayName"] as? String { return displayName }
        return infoDictionary?["CFBundleName"] as? String ?? ""
    }
    
    var versionBuild: String {
        guard let version = infoDictionary?["CFBundleShortVersionString"] as? String, let build = infoDictionary?["CFBundleVersion"] as? String else { return ""}
        return "\(version) Build \(build)"
    }
}
