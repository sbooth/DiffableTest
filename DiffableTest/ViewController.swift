/*
 * Copyright (c) 2019 Stephen F. Booth <me@sbooth.org>
 * See https://github.com/sbooth/DiffableTest/blob/master/LICENSE for license information
 */

import Cocoa

class SearchResult: Hashable {
	let identifier = UUID()
	func hash(into hasher: inout Hasher) {
		hasher.combine(identifier)
	}
	static func ==(lhs: SearchResult, rhs: SearchResult) -> Bool {
		return lhs.identifier == rhs.identifier
	}
}

class Track: SearchResult {
	let title: String
	init(_ title: String) {
		self.title = title
	}
}

class Album: SearchResult {
	let title: String
	init(_ title: String) {
		self.title = title
	}
}

class ViewController: NSViewController {
	@IBOutlet weak var collectionView: NSCollectionView!
	private var dataSource: NSCollectionViewDiffableDataSource<String, SearchResult>!

	private enum SectionKind: Int {
		case track, album
	}

	private static let trackSection = "track"
	private static let albumSection = "album"

	private var tracks: [Track] = [
		Track("Santeria"), Track("The Great Gig in the Sky"), Track("Variations on the Kanon by Pachelbel"), Track("Why Can't This Be Love"), Track("Jeremy")
	]
	private var albums: [Album] = [
		Album("Sublime"), Album("The Dark Side of the Moon"), Album("December"), Album("5150"), Album("Ten")
	]

	override func viewDidLoad() {
		super.viewDidLoad()

		configureHierarchy()
		configureDataSource()

		clearSearchResults(animate: false)
	}

	@IBAction func performSearch(_ sender: AnyObject?) {
		guard let searchString = sender?.stringValue else {
			return
		}

		if searchString.isEmpty {
			clearSearchResults(animate: true)
			return
		}

		let lc = searchString.lowercased()
		let tracks = self.tracks.filter { $0.title.lowercased().contains(lc) }
		let albums = self.albums.filter { $0.title.lowercased().contains(lc) }

		print("Search for '\(lc)' matched \(tracks.count) tracks and \(albums.count) albums")

		var snapshot = NSDiffableDataSourceSnapshot<String, SearchResult>()

		// FIXME: What is the correct way to add sections to NSCollectionView?
		// See https://stackoverflow.com/questions/58792252/appending-sections-in-nscollectionviewdiffabledatasource

		// This seems to be the workaround: don't change the number of sections
//		snapshot.appendSections([ViewController.trackSection, ViewController.albumSection])

		if !tracks.isEmpty {
			snapshot.appendSections([ViewController.trackSection])
			snapshot.appendItems(tracks, toSection: ViewController.trackSection)
		}

		// If a second section is added when the current snapshot doesn't contain two sections
		// this will cause an exception in apply()
		if !albums.isEmpty {
			snapshot.appendSections([ViewController.albumSection])
			snapshot.appendItems(albums, toSection: ViewController.albumSection)
		}

		dataSource.apply(snapshot, animatingDifferences: true)
	}

	func clearSearchResults(animate: Bool) {
		let snapshot = NSDiffableDataSourceSnapshot<String, SearchResult>()
		// This implements the workaround; also change `let` above to `var`
//		snapshot.appendSections([ViewController.trackSection, ViewController.albumSection])
		dataSource.apply(snapshot, animatingDifferences: animate)
	}

    private func createLayout() -> NSCollectionViewLayout {
		let sectionProvider = { (sectionIndex: Int,
			layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection in

			// FIXME: How can the section identifier corresponding to `sectionIndex` be determined?
			// self.dataSource.snapshot() causes a segfault
			// Using `SectionKind` is the way Apple did it in https://developer.apple.com/documentation/uikit/views_and_controls/collection_views/using_collection_view_compositional_layouts_and_diffable_data_sources
			// However, that approach does not seem to work for this use case
			// See https://stackoverflow.com/questions/58791814/determining-section-identifier-for-nscollectionviewcompositionallayout

			let sectionKind = SectionKind(rawValue: sectionIndex)!
			switch sectionKind {
			case .track:
				let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
				let item = NSCollectionLayoutItem(layoutSize: itemSize)

				let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(32))
				let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

				let section = NSCollectionLayoutSection(group: group)

				return section
			case .album:
				let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
				let item = NSCollectionLayoutItem(layoutSize: itemSize)

				let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(59))
				let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

				let section = NSCollectionLayoutSection(group: group)

				return section
			}
		}

		return NSCollectionViewCompositionalLayout(sectionProvider: sectionProvider)
    }

	private func configureHierarchy() {
		collectionView.register(NSNib(nibNamed: "TrackItem", bundle: nil), forItemWithIdentifier: TrackItem.reuseIdentifier)
		collectionView.register(NSNib(nibNamed: "AlbumItem", bundle: nil), forItemWithIdentifier: AlbumItem.reuseIdentifier)

		collectionView.collectionViewLayout = createLayout()
	}

	private func configureDataSource() {
		dataSource = NSCollectionViewDiffableDataSource<String, SearchResult>(collectionView: collectionView) { (collectionView: NSCollectionView, indexPath: IndexPath, identifier: Any) in

			// FIXME: How can the section identifier corresponding to `sectionIndex` be determined?
			// In this case the type of `identifier` is a workaround, but that is not a solution
			// for cases where the data source item identifier type is more generic, e.g. UUID

			let section = SectionKind(rawValue: indexPath.section)!
			switch section {
			case .track:
				let item = collectionView.makeItem(withIdentifier: TrackItem.reuseIdentifier, for: indexPath) as! TrackItem
				// This will fail when the search results contain only albums
				let track = identifier as! Track
				item.textField?.stringValue = track.title
				return item
			case .album:
				let item = collectionView.makeItem(withIdentifier: AlbumItem.reuseIdentifier, for: indexPath) as! AlbumItem
				let album = identifier as! Album
				item.textField?.stringValue = album.title
				return item
			}
		}
	}
}
