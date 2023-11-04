//
//  ViewController.swift
//  CLIPFinder
//
//  Created by Damian Stewart on 02.11.23.
//

import AppKit
import UniformTypeIdentifiers

class ViewController: NSViewController, NSCollectionViewDelegate, NSTokenFieldDelegate {

    @IBOutlet weak var filesCollectionView: NSCollectionView!
    @IBOutlet weak var predicateEditor: NSPredicateEditor!
    @IBOutlet weak var rootFolderTextField: NSTextField!
    @IBOutlet weak var tagsTokenField: AutoExpandingTokenField!
    
    var filesDataSource: NSCollectionViewDiffableDataSource<Int, FileInfo>? = nil
    
    var searchResultsProvider: SearchResultsProviderProtocol? = nil
    
    var selectedFiles: [FileInfo] = []
    
    //let tagsAutocompleteProvider = TagsAutocompleteProvider()
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
        
        self.tagsTokenField.delegate = self
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
    
    @IBAction func rootFolderTextFieldDidChange(_ sender: Any) {
        self.updateSearchResults()
    }
    
    func updateSearchResults() {
        Task { @MainActor in
            await self.searchResultsProvider?.setRootFolder(self.rootFolderTextField.stringValue)
        }
    }
    

    @IBAction func openRootFolderButtonPressed(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.runModal()
        guard let url = openPanel.urls.first else { return }
        self.setRootFolder(url)
    }
    
    @IBAction func iconSizeSliderChanged(_ sender: Any) {
        let slider = sender as! NSSlider
        //let size = CGFloat(50 + log(slider.floatValue) * 300)
        let size = CGFloat(50 + slider.floatValue * 300)

        let layout = (self.filesCollectionView.collectionViewLayout as? NSCollectionViewFlowLayout) ?? NSCollectionViewFlowLayout()
        layout.itemSize = CGSize(width: size, height: size)
        self.filesCollectionView.collectionViewLayout = layout
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        print("selected \(indexPaths)")
        
        let items = indexPaths.map { self.filesDataSource!.snapshot().itemIdentifiers[$0.item] }
        self.selectedFiles.append(contentsOf: items)
        print("selection: \(self.selectedFiles)")
        
        updateTags()
    }
        
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        print("deselected \(indexPaths)")

        let items = indexPaths.map { self.filesDataSource!.snapshot().itemIdentifiers[$0.item] }
        self.selectedFiles.removeAll(where: { items.contains($0) })
        print("selection: \(self.selectedFiles)")
        
        updateTags()
    }
    
    func updateTags() {
        
        let urls = self.selectedFiles.map { $0.url }
        
        let tagsPerUrl = urls.map {
            do {
                return try $0.resourceValues(forKeys: [.tagNamesKey]).tagNames ?? []
            } catch {
                print("error gettings tags for \($0): \(error)")
                return []
            }
        }
        
        let uniqueTags = tagsPerUrl.reduce([String]()) { allTags, thisTags in
            let newTags = thisTags.filter { !allTags.contains($0) }
            return allTags + newTags
        }
        let commonTags = uniqueTags.filter { uniqueTag in
            tagsPerUrl.allSatisfy { $0.contains(uniqueTag) }
        }
        
        self.tagsTokenField.objectValue = uniqueTags.map { TagInfo(tag: $0, isCommon: commonTags.contains($0)) }
    }

    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        let tagInfo = representedObject as! TagInfo
        return tagInfo.tag
    }
    
    func tokenField(_ tokenField: NSTokenField, styleForRepresentedObject representedObject: Any) -> NSTokenField.TokenStyle {
        let tagInfo = representedObject as! TagInfo
        return tagInfo.isCommon ? .rounded : .plainSquared
    }
        
    @IBAction func tagSortComboBoxChanged(_ sender: Any) {
        print("todo: handl tag sort change")
    }
}


