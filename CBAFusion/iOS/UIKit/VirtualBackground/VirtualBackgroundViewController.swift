//
//  VirtualBackgroundViewController.swift
//  CBAFusion
//
//  Created by Cole M on 1/23/23.
//

import UIKit
import FCSDKiOS
import Combine

@available(iOS 15, *)
class VirtualBackgroundViewController: UICollectionViewController {
    
    var dataSource: UICollectionViewDiffableDataSource<BackgroundSections, BackgroundsViewModel>!
    let backgroundObserver: BackgroundObserver
    
    init(backgroundObserver: BackgroundObserver) {
        self.backgroundObserver = backgroundObserver
        let layout = VirtualBackgroundViewController.createLayout()
        super.init(collectionViewLayout: layout)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private var cancellables = Set<AnyCancellable>()
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.allowsSelection = true
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.configureHierarchy()
        self.configureDataSource()
        
        backgroundObserver.$backgroundsViewModel
            .sink { value in
                Task { [weak self] in
                    guard let self else { return }
                    await self.performQuery(with: "")
                }
            }
            .store(in: &cancellables)
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            deleteSnap()
            cancellables.removeAll()
        }
    }
    
    @MainActor
    func performQuery(with string: String) async {
        var snapshot = NSDiffableDataSourceSnapshot<BackgroundSections, BackgroundsViewModel>()
        await dataSource.apply(snapshot)
        let data = await backgroundObserver.searchImages(with: string).sorted { $0.title < $1.title }
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
    
    @MainActor
    func deleteSnap() {
        var snapshot = dataSource.snapshot()
        snapshot.deleteAllItems()
        dataSource.apply(snapshot)
    }
    
    func configureHierarchy() {
        collectionView.register(BackgroundItemCell.self, forCellWithReuseIdentifier: BackgroundItemCell.reuseIdentifer)
        collectionView.register(BackgroundHeader.self, forSupplementaryViewOfKind: "section-header-element-kind", withReuseIdentifier: "section-header-element-kind-identifier")
    }
    
    fileprivate func setCollectionViewItem(item: BackgroundItemCell? = nil, background: BackgroundsViewModel) {
        item?.posterImage.image = background.thumbnail
    }
    
    @MainActor
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<BackgroundSections, BackgroundsViewModel>(collectionView: collectionView) { [weak self]
            (collectionView: UICollectionView, indexPath: IndexPath, model: BackgroundsViewModel) -> UICollectionViewCell? in
            guard let self else { return nil }
            let section = BackgroundSections(rawValue: indexPath.section)!
            switch section {
            case .inital:
                if let item = collectionView.dequeueReusableCell(withReuseIdentifier: BackgroundItemCell.reuseIdentifer, for: indexPath) as? BackgroundItemCell {
                    self.setCollectionViewItem(item: item, background: model)
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
        let sections = CollectionViewSections()
        return UICollectionViewCompositionalLayout(section: sections.backgroundSection())
    }
}
