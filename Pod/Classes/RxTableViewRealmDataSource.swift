//
//  RxRealm extensions
//
//  Copyright (c) 2016 RxSwiftCommunity. All rights reserved.
//
   
import Foundation
import RealmSwift
import RxSwift
import RxCocoa
import RxRealm

public typealias TableCellFactory<E: Object> = (RxTableViewRealmDataSource<E>, UITableView, IndexPath, E) -> UITableViewCell
public typealias TableCellConfig<E: Object, CellType: UITableViewCell> = (CellType, IndexPath, E) -> Void

public class RxTableViewRealmDataSource<E: Object>: NSObject, UITableViewDataSource {

    private var items: AnyRealmCollection<E>?

    // MARK: - Configuration

    public var tableView: UITableView?
    public var animated = true
    public var rowAnimations = (
        insert: UITableViewRowAnimation.automatic,
        update: UITableViewRowAnimation.automatic,
        delete: UITableViewRowAnimation.automatic)

    public var headerTitle: String?
    public var footerTitle: String?

    // MARK: - Init
    public let cellIdentifier: String
    public let cellFactory: TableCellFactory<E>

    public init(cellIdentifier: String, cellFactory: @escaping TableCellFactory<E>) {
        self.cellIdentifier = cellIdentifier
        self.cellFactory = cellFactory
    }

    public init<CellType>(cellIdentifier: String, cellType: CellType.Type, cellConfig: @escaping TableCellConfig<E, CellType>) where CellType: UITableViewCell {
        self.cellIdentifier = cellIdentifier
        self.cellFactory = {ds, tv, ip, model in
            let cell = tv.dequeueReusableCell(withIdentifier: cellIdentifier, for: ip) as! CellType
            cellConfig(cell, ip, model)
            return cell
        }
    }

    // MARK: - UITableViewDataSource protocol
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cellFactory(self, tableView, indexPath, items![indexPath.row] as! E)
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headerTitle
    }

    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return footerTitle
    }

    // MARK: - Applying changeset to the table view
    private let fromRow = {(row: Int) in return IndexPath(row: row, section: 0)}

    func applyChanges(items: AnyRealmCollection<E>, changes: RealmChangeset?) {
        if self.items == nil {
            self.items = items
        }

        guard let tableView = tableView else {
            fatalError("You have to bind a table view to the data source.")
        }

        guard animated else {
            tableView.reloadData()
            return
        }

        guard let changes = changes else {
            tableView.reloadData()
            return
        }

        let lastItemCount = tableView.numberOfRows(inSection: 0)
        guard items.count == lastItemCount + changes.inserted.count - changes.deleted.count else {
            tableView.reloadData()
            return
        }

        tableView.beginUpdates()
        tableView.deleteRows(at: changes.deleted.map(fromRow), with: rowAnimations.delete)
        tableView.insertRows(at: changes.inserted.map(fromRow), with: rowAnimations.insert)
        tableView.reloadRows(at: changes.updated.map(fromRow), with: rowAnimations.update)
        tableView.endUpdates()
    }
}
