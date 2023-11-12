//
//  ViewController.swift
//  CLIPFinder
//
//  Created by Damian Stewart on 02.11.23.
//

import AppKit
import UniformTypeIdentifiers



class ViewController: NSViewController, NSCollectionViewDelegate, NSTokenFieldDelegate, NSSplitViewDelegate, PredicateEditorControllerDelegate {
    
    
    @IBOutlet weak var filesCollectionView: NSCollectionView!

    @IBOutlet weak var predicateEditorScrollView: NSScrollView!
    @IBOutlet weak var predicateEditor: NSPredicateEditor!
    @IBOutlet weak var addPredicateButton: NSButton!
    var predicateEditorController: PredicateEditorController!
    @IBOutlet weak var mainHorizontalSplitView: NSSplitView!
    
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
        
        self.predicateEditorController = PredicateEditorController(predicateEditor: self.predicateEditor, addPredicateButton: self.addPredicateButton)
        self.predicateEditorController.delegate = self
        self.mainHorizontalSplitView.delegate = self
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
    

    func predicateEditorRulesDidChange(_ controller: PredicateEditorController) {
        if self.predicateEditor.numberOfRows == 0 {
            self.predicateEditorScrollView.animator().isHidden = true
        } else {
            self.predicateEditorScrollView.animator().isHidden = false
        }
    }
    
    //MARK: NSSplitView delegate
    
    func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
        return self.predicateEditor.numberOfRows == 0
    }
    
    
    
    /*
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        print("proposed position: \(proposedMinimumPosition)")
        return proposedMinimumPosition
    }*/
    
}


