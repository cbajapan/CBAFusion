//
//  VirtualBackgroundViewController.swift
//  CBAFusion
//
//  Created by Cole M on 1/23/23.
//

import UIKit
import FCSDKiOS

@available(iOS 15.0, *)
class VirtualBackgroundViewController: UICollectionViewController {

    var dataSource: UICollectionViewDiffableDataSource<Sections, Backgrounds.BackgroundsViewModel>!
    var backgrounds: Backgrounds
    

    init(backgrounds: Backgrounds) {
        self.backgrounds = backgrounds
            super.init(collectionViewLayout: VirtualBackgroundViewController.createLayout())
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.allowsSelection = true
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        Task { @MainActor [weak self] in
            guard let strongSelf = self else { return }
            await strongSelf.configureHierarchy()
            await strongSelf.configureDataSource()
            await strongSelf.performQuery(with: "")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        Task { @MainActor [weak self] in
            guard let strongSelf = self else { return }
            await strongSelf.deleteSnap()
            strongSelf.backgrounds.backgroundsViewModel.removeAll()
        }
    }
    
    func performQuery(with string: String) async {
            var snapshot = NSDiffableDataSourceSnapshot<Sections, Backgrounds.BackgroundsViewModel>()
            await dataSource.apply(snapshot)
            
            let data = backgrounds.searchImages(with: string).sorted { $0.title < $1.title }
            if data.isEmpty {
                snapshot.deleteSections([.inital])
                snapshot.deleteItems(data)
                await dataSource.apply(snapshot, animatingDifferences: false)
            } else {
                snapshot.appendSections([.inital])
                snapshot.appendItems(data, toSection: .inital)
                await dataSource.apply(snapshot, animatingDifferences: false)
            }
        }
    
    func deleteSnap() async {
        var snapshot = dataSource.snapshot()
        snapshot.deleteAllItems()
        await dataSource.apply(snapshot)
    }
    
    func configureHierarchy() async {
        collectionView.register(BackgroundItemCell.self, forCellWithReuseIdentifier: BackgroundItemCell.reuseIdentifer)
        collectionView.register(BackgroundHeader.self, forSupplementaryViewOfKind: "section-header-element-kind", withReuseIdentifier: "section-header-element-kind-identifier")
    }
    
    fileprivate func setCollectionViewItem(item: BackgroundItemCell? = nil, background: Backgrounds.BackgroundsViewModel) async {
        item?.posterImage.image = background.thumbnail
    }
    
    func configureDataSource() async {
        dataSource = UICollectionViewDiffableDataSource<Sections, Backgrounds.BackgroundsViewModel>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: Any) -> UICollectionViewCell? in
            let section = Sections(rawValue: indexPath.section)!
            switch section {
            case .inital:
                if let item = collectionView.dequeueReusableCell(withReuseIdentifier: BackgroundItemCell.reuseIdentifer, for: indexPath) as? BackgroundItemCell {
                    if let background = identifier as? Backgrounds.BackgroundsViewModel {
                        Task { @MainActor [weak self] in
                            guard let strongSelf = self else { return }
                            await strongSelf.setCollectionViewItem(item: item, background: background)
                        }
                    }
                    return item
                } else {
                    fatalError("Cannot create other item")
                }
            }
        }
       await supplementaryViewProvider()
    }
    
    fileprivate func supplementaryViewProvider() async {
        dataSource.supplementaryViewProvider = { [weak self]
            (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
            guard let strongSelf = self else {return nil}
                if let supplementaryView = collectionView.dequeueReusableSupplementaryView(
                    ofKind: "section-header-element-kind",
                    withReuseIdentifier: "section-header-element-kind-identifier",
                    for: indexPath) as? BackgroundHeader {



                    if let object = strongSelf.dataSource.itemIdentifier(for: indexPath) {
                        if let section = strongSelf.dataSource.snapshot()
                            .sectionIdentifier(containingItem: object) {
                            switch section {
                            case .inital:
                                supplementaryView.label.font = .systemFont(ofSize: 14)
                                supplementaryView.label.text = "Select an Image"
                            }
                        }
                    }
                    return supplementaryView
                } else {
                    fatalError("Cannot create new supplementary")
                }
        }
    }
    
    
   static func createLayout() -> UICollectionViewCompositionalLayout {
        
        let layout = UICollectionViewCompositionalLayout {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection in
            switch sectionIndex {
            case 0:
                return CollectionViewSections.shared.backgroundSection()
            default:
                return CollectionViewSections.shared.defaultSection()
            }
        }
        return layout
        
    }
}
