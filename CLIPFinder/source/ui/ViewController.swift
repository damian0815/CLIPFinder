//
//  ViewController.swift
//  CLIPFinder
//
//  Created by Damian Stewart on 02.11.23.
//

import AppKit
import UniformTypeIdentifiers

class PredicateEditorController: NSObject, NSRuleEditorDelegate {
 
    let predicateEditor: NSPredicateEditor
    let addPredicateButton: NSButton
    let undoManagerProvider: () -> UndoManager
    
    var topLevelPredicate: NSPredicate? { self.predicateEditor.predicate }
    var lastKnownPredicate: NSPredicate? = nil
    var topLevelPredicateObservation: NSKeyValueObservation?

    init(predicateEditor: NSPredicateEditor, addPredicateButton: NSButton, undoManagerProvider: @escaping () -> UndoManager) {
        self.predicateEditor = predicateEditor
        self.addPredicateButton = addPredicateButton
        self.undoManagerProvider = undoManagerProvider
        
        super.init()

        self.lastKnownPredicate = self.predicateEditor.objectValue as? NSPredicate
        self.predicateEditor.delegate = self
    }
    
    // MARK: NSRuleEditorDelegate

    func ruleEditorRowsDidChange(_ notification: Notification) {
        
        let newPredicate = self.topLevelPredicate
        if newPredicate != self.lastKnownPredicate {
            //print("storing undo to \(self.lastKnownPredicate?.predicateFormat), userInfo: \(notification.userInfo)")
            registerPredicateEditUndo(oldPredicate: self.lastKnownPredicate?.copy() as? NSPredicate)
        }
        self.lastKnownPredicate = newPredicate?.copy() as? NSPredicate
        if newPredicate == nil {
            self.addPredicateButton.image = NSImage(systemSymbolName: "plus", accessibilityDescription: "Add Search Predicates")
        } else {
            self.addPredicateButton.image = NSImage(systemSymbolName: "minus", accessibilityDescription: "Remove Search Predicates")
        }
    }
    
    func registerPredicateEditUndo(oldPredicate: NSPredicate?) {
        self.undoManagerProvider().registerUndo(withTarget: self.predicateEditor, handler: { predicateEditor in
            predicateEditor.objectValue = oldPredicate
            self.lastKnownPredicate = oldPredicate?.copy() as? NSPredicate
        })
    }
    
    func ruleEditor(_ editor: NSRuleEditor, numberOfChildrenForCriterion criterion: Any?, with rowType: NSRuleEditor.RowType) -> Int {
        // not called with NSPredicateEditor
        return 0
    }
    
    func ruleEditor(_ editor: NSRuleEditor, child index: Int, forCriterion criterion: Any?, with rowType: NSRuleEditor.RowType) -> Any {
        // not called with NSPredicateEditor
        return 0
    }
    
    func ruleEditor(_ editor: NSRuleEditor, displayValueForCriterion criterion: Any, inRow row: Int) -> Any {
        // not called with NSPredicateEditor
        return 0
    }
    
    
    func addPredicateButtonPressed(_ sender: Any) {
        if self.topLevelPredicate == nil {
            self.predicateEditor.addRow(self)
            //self.predicateEditor.objectValue = NSPredicate(format: "tag CONTAINS \"\"", argumentArray: nil)
            self.lastKnownPredicate = self.predicateEditor.objectValue as? NSPredicate
        } else {
            self.predicateEditor.objectValue = nil
            self.lastKnownPredicate = nil
        }
    }

    
}


class ViewController: NSViewController, NSCollectionViewDelegate, NSTokenFieldDelegate {
    
    @IBOutlet weak var filesCollectionView: NSCollectionView!

    @IBOutlet weak var predicateEditor: NSPredicateEditor!
    @IBOutlet weak var addPredicateButton: NSButton!
    var predicateEditorController: PredicateEditorController!

    @IBOutlet weak var rootFolderTextField: NSTextField!
    @IBOutlet weak var tagsTokenField: AutoExpandingTokenField!
    @IBOutlet weak var sortOrderComboBox: NSComboBox!
    
    var tagsTokenFieldController: TagsTokenFieldController!
    
    var filesDataSource: NSCollectionViewDiffableDataSource<Int, FileInfo>? = nil
    
    var searchResultsProvider: SearchResultsProviderProtocol? = nil
    
    var selectedFiles: [FileInfo] = []

    //let tagsAutocompleteProvider = TagsAutocompleteProvider()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateIconSizes(iconSizePercent: 0.5)
        
        self.filesCollectionView.register(
            NSNib(nibNamed: "FileCollectionViewItem", bundle: Bundle.main),
            forItemWithIdentifier: FileCollectionViewItem.identifier)
        
        // Do any additional setup after loading the view.
        
        self.filesDataSource = NSCollectionViewDiffableDataSource<Int, FileInfo>(collectionView: self.filesCollectionView, itemProvider: { cv, indexPath, fileInfo in
            let item = cv.makeItem(withIdentifier: FileCollectionViewItem.identifier, for: indexPath) as! FileCollectionViewItem
            item.populate(with: fileInfo)
            
            return item
        })
        self.filesDataSource!.apply(NSDiffableDataSourceSnapshot())
        
        //self.rootFolderTextField.delegate = self.rootFolderAutocompleteProvider
        let searchResultsProvider = BaseSearchResultsProvider { fileInfos in
            var snapshot = NSDiffableDataSourceSnapshot<Int, FileInfo>()
            snapshot.appendSections([0])
            snapshot.appendItems(fileInfos)
            await MainActor.run {
                self.filesDataSource!.apply(snapshot)
            }
        }
        self.searchResultsProvider = searchResultsProvider
        
        self.sortOrderComboBox.selectItem(at: 1)
        self.tagsTokenFieldController = TagsTokenFieldController(tagsTokenField: self.tagsTokenField)
        self.tagsTokenFieldController.sortOrder = .ByFrequency
        self.tagsTokenField.delegate = self.tagsTokenFieldController
        
        self.predicateEditorController = PredicateEditorController(predicateEditor: self.predicateEditor, addPredicateButton: self.addPredicateButton, undoManagerProvider: { return self.undoManager! })
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func setRootFolder(_ url: URL) {
        self.rootFolderTextField.stringValue = url.path(percentEncoded: false)
        self.updateSearchResults()
    }
    
    func updateSearchResults() {
        Task { @MainActor in
            await self.searchResultsProvider?.setRootFolder(self.rootFolderTextField.stringValue)
        }
    }
    
    // MARK: UI activity responses
    
    @IBAction func rootFolderTextFieldDidChange(_ sender: Any) {
        self.updateSearchResults()
    }
    
    @IBAction func tagSortComboBoxChanged(_ sender: Any) {
        print("todo: handle tag sort change")
        let tagSortComboBox = sender as! NSComboBox
        let sortOrderString = tagSortComboBox.stringValue
        switch sortOrderString {
        case "Alphabetical":
            self.tagsTokenFieldController.sortOrder = .Alphabetical
        case "Original":
            self.tagsTokenFieldController.sortOrder = .Original
        case "By frequency":
            self.tagsTokenFieldController.sortOrder = .ByFrequency
        default:
            assert(false, "Missing case")
        }
    }
    
    
    @IBAction func openRootFolderButtonPressed(_ sender: Any) {
        self.showOpenFolderDialog()
    }
    
    func showOpenFolderDialog() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.runModal()
        guard let url = openPanel.urls.first else { return }
        self.setRootFolder(url)
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
    }
    
    @IBAction func iconSizeSliderChanged(_ sender: Any) {
        let slider = sender as! NSSlider
        self.updateIconSizes(iconSizePercent: slider.floatValue)
    }
    
    func updateIconSizes(iconSizePercent: Float) {
        let size = CGFloat(120 + iconSizePercent * 800)

        let layout = (self.filesCollectionView.collectionViewLayout as? NSCollectionViewFlowLayout) ?? NSCollectionViewFlowLayout()
        layout.itemSize = CGSize(width: size, height: size)
        self.filesCollectionView.collectionViewLayout = layout
    }
    
    @IBAction func addPredicateButtonPressed(_ sender: Any) {
        self.predicateEditorController.addPredicateButtonPressed(sender)
    }
    
    // MARK: collection view delegate
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        print("selected \(indexPaths)")
        
        let items = indexPaths.map { self.filesDataSource!.snapshot().itemIdentifiers[$0.item] }
        self.selectedFiles.append(contentsOf: items)
        print("selection: \(self.selectedFiles)")
        
        self.tagsTokenFieldController.updateTags(forSelectedFiles: self.selectedFiles)
    }
        
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        print("deselected \(indexPaths)")

        let items = indexPaths.map { self.filesDataSource!.snapshot().itemIdentifiers[$0.item] }
        self.selectedFiles.removeAll(where: { items.contains($0) })
        print("selection: \(self.selectedFiles)")
        
        self.tagsTokenFieldController.updateTags(forSelectedFiles: self.selectedFiles)
    }
    


}


