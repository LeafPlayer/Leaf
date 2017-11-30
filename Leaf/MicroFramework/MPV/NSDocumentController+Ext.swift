//
//  NSDocumentController+Ext.swift
//  Leaf
//
//  Created by lincolnlaw on 2017/11/28.
//  Copyright © 2017年 lincolnlaw. All rights reserved.
//

import Cocoa
extension NSDocumentController {
    public func removeRecentDocumentURL(_ url: URL) {
        let copy = recentDocumentURLs.reversed()
        clearRecentDocuments(nil)
        for item in copy {
            guard item != url else { continue }
            noteNewRecentDocumentURL(item)
        }
    }
}
