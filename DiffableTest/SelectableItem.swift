/*
 * Copyright (c) 2019 Stephen F. Booth <me@sbooth.org>
 * See https://github.com/sbooth/DiffableTest/blob/master/LICENSE for license information
 */

import Cocoa

class SelectableItem: NSCollectionViewItem {
	override var highlightState: NSCollectionViewItem.HighlightState {
		didSet {
			updateSelectionHighlighting()
		}
	}

	override var isSelected: Bool {
		didSet {
			updateSelectionHighlighting()
		}
	}

	private func updateSelectionHighlighting() {
		if !isViewLoaded {
			return
		}

		let showAsHighlighted = (highlightState == .forSelection) || (isSelected && highlightState != .forDeselection) || (highlightState == .asDropTarget)

		textField?.textColor = showAsHighlighted ? .selectedControlTextColor : .labelColor
		view.layer?.backgroundColor = showAsHighlighted ? NSColor.selectedControlColor.cgColor : nil
	}
}
