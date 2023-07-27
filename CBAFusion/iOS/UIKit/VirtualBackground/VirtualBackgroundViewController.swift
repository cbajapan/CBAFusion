//
//  VirtualBackgroundViewController.swift
//  CBAFusion
//
//  Created by Cole M on 1/23/23.
//

import UIKit
import FCSDKiOS

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
        configureHierarchy()
        configureDataSource()
        performQuery(with: "")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        deleteSnap() { [weak self] in
            self?.backgrounds.backgroundsViewModel.removeAll()
        }
    }
    
    func performQuery(with string: String) {
        var snapshot = NSDiffableDataSourceSnapshot<Sections, Backgrounds.BackgroundsViewModel>()
        dataSource.apply(snapshot) { [weak self] in
            guard let self else { return }
            let data = backgrounds.searchImages(with: string).sorted { $0.title < $1.title }
            if data.isEmpty {
                snapshot.deleteSections([.inital])
                snapshot.deleteItems(data)
                dataSource.apply(snapshot, animatingDifferences: false)
            } else {
                snapshot.appendSections([.inital])
                snapshot.appendItems(data, toSection: .inital)
                dataSource.apply(snapshot, animatingDifferences: false)
            }
        }
    }
    
    func deleteSnap(completion: (() -> Void)?) {
        var snapshot = dataSource.snapshot()
        snapshot.deleteAllItems()
        dataSource.apply(snapshot, completion: completion)
    }
    
    func configureHierarchy() {
        collectionView.register(BackgroundItemCell.self, forCellWithReuseIdentifier: BackgroundItemCell.reuseIdentifer)
        collectionView.register(BackgroundHeader.self, forSupplementaryViewOfKind: "section-header-element-kind", withReuseIdentifier: "section-header-element-kind-identifier")
    }
    
    fileprivate func setCollectionViewItem(item: BackgroundItemCell? = nil, background: Backgrounds.BackgroundsViewModel) async {
        item?.posterImage.image = background.thumbnail
    }
    
    func configureDataSource() {
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
       supplementaryViewProvider()
    }
    
    fileprivate func supplementaryViewProvider() {
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
