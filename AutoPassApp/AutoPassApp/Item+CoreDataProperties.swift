//
//  Item+CoreDataProperties.swift
//  AutoPassApp
//
//  Created by rlbot on 2020/6/15.
//  Copyright © 2020 WL. All rights reserved.
//
//

import Foundation
import CoreData


extension Item {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
        return NSFetchRequest<Item>(entityName: "Item")
    }

    @NSManaged public var password: String?
    @NSManaged public var title: String?
    @NSManaged public var appendEnter: Bool

}
