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
    
    /// The data source for the collection view, managing the display of background images.
    @MainActor
    var dataSource: UICollectionViewDiffableDataSource<BackgroundSections, BackgroundsViewModel>!
    
    /// The observer for managing background images.
    @MainActor
    let backgroundObserver: BackgroundObserver
    
    /// Initializes a new instance of `VirtualBackgroundViewController`.
    ///
    /// - Parameter backgroundObserver: An instance of `BackgroundObserver` to manage background images.
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
    
    /// A set to hold cancellable Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    @MainActor
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.allowsSelection = true
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.configureHierarchy()
        self.configureDataSource()
        
        // Observe changes to the backgroundsViewModel in the background observer.
        backgroundObserver.$backgroundsViewModel
            .sink { value in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    await self.performQuery(with: "")
                }
            }
            .store(in: &cancellables)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.deleteSnap()
            self.cancellables.removeAll()
        }
    }
    
    /// Performs a search query to filter background images based on the provided string.
    ///
    /// - Parameter string: The search string to filter the background images.
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
    
    /// Deletes all items from the current snapshot of the data source.
    @MainActor
    func deleteSnap() {
        var snapshot = dataSource.snapshot()
        snapshot.deleteAllItems()
        dataSource.apply(snapshot)
    }
    
    /// Configures the collection view hierarchy by registering cell and header classes.
    @MainActor
    func configureHierarchy() {
        collectionView.register(BackgroundItemCell.self, forCellWithReuseIdentifier: BackgroundItemCell.reuseIdentifier)
        collectionView.register(BackgroundHeader.self, forSupplementaryViewOfKind: "section-header-element-kind", withReuseIdentifier: "section-header-element-kind-identifier")
    }
    
    /// Sets the properties of a collection view item.
    ///
    /// - Parameters:
    ///   - item: The `BackgroundItemCell` to configure.
    ///   - background: The `BackgroundsViewModel` containing the background image data.
    @MainActor
    fileprivate func setCollectionViewItem(item: BackgroundItemCell? = nil, background: BackgroundsViewModel) {
        item?.posterImage.image = background.thumbnail
        item?.posterImage.image?.title = background.title
    }
    
    /// Configures the data source for the collection view.
    @MainActor
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<BackgroundSections, BackgroundsViewModel>(collectionView: collectionView) { @MainActor [weak self] (collectionView: UICollectionView, indexPath: IndexPath, model: BackgroundsViewModel) -> UICollectionViewCell? in
            guard let self = self else { return nil }
            let section = BackgroundSections(rawValue: indexPath.section)!
            switch section {
            case .inital:
                if let item = collectionView.dequeueReusableCell(withReuseIdentifier: BackgroundItemCell.reuseIdentifier, for: indexPath) as? BackgroundItemCell {
                    self.setCollectionViewItem(item: item, background: model)
                    return item
                } else {
                    fatalError("Cannot create other item")
                }
            }
        }
        supplementaryViewProvider()
    }
    
    /// Provides supplementary views for the collection view.
    @MainActor
    fileprivate func supplementaryViewProvider() {
        dataSource.supplementaryViewProvider = { @MainActor [weak self] (collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
            guard let strongSelf = self else { return nil }
            if let supplementaryView = collectionView.dequeueReusableSupplementaryView(
                ofKind: "section-header-element-kind",
                withReuseIdentifier: "section-header-element-kind-identifier",
                for: indexPath) as? BackgroundHeader {
                
                if let object = strongSelf.dataSource.itemIdentifier(for: indexPath) {
                    if let section = strongSelf.dataSource.snapshot().sectionIdentifier(containingItem: object) {
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
    
    /// Creates and returns a compositional layout for the collection view.
    ///
    /// - Returns: A `UICollectionViewCompositionalLayout` for the collection view.
    @MainActor
    static func createLayout() -> UICollectionViewCompositionalLayout {
        let sections = CollectionViewSections()
        return UICollectionViewCompositionalLayout(section: sections.backgroundSection())
    }
}
