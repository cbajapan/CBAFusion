//
//  CollectionViewSections.swift
//  CBAFusion
//
//  Created by Cole M on 1/23/23.
//

import UIKit


enum Sections: Int, CaseIterable {
    case inital
}


class CollectionViewSections: NSObject {
    
    private override init() {}
    
    static let shared = CollectionViewSections()
    
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
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                heightDimension: .absolute(40))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: "section-header-element-kind",
            alignment: .topLeading)
        
        let sectionIndex = NSCollectionLayoutSection(group: group)
        sectionHeader.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 0)
        sectionIndex.boundarySupplementaryItems = [sectionHeader]
        
        
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
}
