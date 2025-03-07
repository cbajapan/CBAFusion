//
//  CollectionViewSections.swift
//  CBAFusion
//
//  Created by Cole M on 1/23/23.
//

import UIKit


enum BackgroundSections: Int, CaseIterable {
    case inital
}

enum ConferenceCallSections: Int, CaseIterable {
    case inital
}

@MainActor
class CollectionViewSections: NSObject {
    
    override init() {}
    
    private func makeBackgroundDecorationItem() -> NSCollectionLayoutDecorationItem {
        let backgroundItem = NSCollectionLayoutDecorationItem.background(elementKind: "background")
        return backgroundItem
    }
    
    func backgroundSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15)
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(225),
                                               heightDimension: .absolute(180))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let sectionIndex = NSCollectionLayoutSection(group: group)
        sectionIndex.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
        sectionIndex.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
        
        return sectionIndex
    }
    
    func defaultSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 5)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.25),
                                               heightDimension: .fractionalHeight(1))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let sectionIndex = NSCollectionLayoutSection(group: group)
        sectionIndex.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        sectionIndex.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
        
        return sectionIndex
    }
    
    func fullScreenItem() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)),
            subitems: [item]
        )
        return NSCollectionLayoutSection(group: group)
    }

    func conferenceViewSection(itemCount: Int, aspectRatio: CGFloat) -> NSCollectionLayoutSection {
        // Get the screen size
        let screenSize = UIScreen.main.bounds.size
        
        // Calculate the available width for the items
        let availableWidth = screenSize.width
        
        // Calculate the width for each item based on the aspect ratio
        // itemWidth = availableWidth / numberOfColumns
        // itemHeight = itemWidth / aspectRatio
        // We will calculate the number of columns based on the available width and the aspect ratio
        let numberOfColumns = Int(availableWidth / (availableWidth / CGFloat(itemCount) * aspectRatio))
        
        // Calculate the width for each item
        let itemWidth = availableWidth / CGFloat(numberOfColumns)
        let itemHeight = itemWidth / aspectRatio
        
        // Create the item size with the calculated width and height
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(itemWidth), heightDimension: .absolute(itemHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15)
        
        // Create the group size, ensuring it respects the overall layout
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(itemHeight)),
            subitems: [item]
        )
        
        // Create the section with the group
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 15 // Adjust spacing between groups if needed
        
        return section
    }
}
