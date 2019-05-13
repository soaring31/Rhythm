//
//  LyricsTableViewController.swift
//  LyricsUI
//
//  Created by Jonny Kuang on 5/13/19.
//  Copyright © 2019 Jonny Kuang. All rights reserved.
//

public class LyricsTableViewController: UITableViewController {

    public var lyrics: Lyrics? {
        didSet {
            tableView.reloadData()
            if tableView.numberOfRows(inSection: 0) > 0 {
                tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .middle)
            }
        }
    }
    
    public var showsLyricsTranslationIfAvailable = true {
        didSet {
            tableView.reloadData()
        }
    }
    
    public init() {
        super.init(style: .plain)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 56
        tableView.rowHeight = UITableView.automaticDimension
        
        configureObservers()
    }

    
    // MARK: - UITableViewDataSource

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lyrics?.lines.count ?? 0
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let lyricsLine = lyrics!.lines[indexPath.row]
        let lyricsLineContent = lyricsLine.content.trimmingCharacters(in: .whitespacesAndNewlines)
        let translation = !showsLyricsTranslationIfAvailable ? "" : (lyricsLine.attachments.translation()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        
        let requiresDetailLabel = showsLyricsTranslationIfAvailable && !translation.isEmpty
        let cellStyle: UITableViewCell.CellStyle = requiresDetailLabel ? .subtitle : .default
        let cellIdentifier = "\(cellStyle.rawValue)"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? LyricsTableViewCell(style: cellStyle, reuseIdentifier: cellIdentifier)
        cell.textLabel?.text = lyricsLineContent
        cell.detailTextLabel?.text = translation
        
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    
    // MARK: - Auto Scroll
    
    private var isDeferredScrollingScheduled = false
    
    private func scrollToActiveContentIfNeeded() {
        if !isDeferredScrollingScheduled {
            scrollToSelectedRowWhenIdle()
        }
    }
    
    private func scrollToSelectedRowWhenIdle() {
        if Date().timeIntervalSince(lastInteractionDate) > type(of: self).idleDuration {
            if let indexPath = tableView.indexPathForSelectedRow {
                tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            }
            isDeferredScrollingScheduled = false
        } else {
            isDeferredScrollingScheduled = true
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                self?.scrollToSelectedRowWhenIdle()
            }
        }
    }
    
    private static let idleDuration: TimeInterval = 3
    private var lastInteractionDate = Date.distantPast
    
    public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isDragging {
            lastInteractionDate = Date()
        }
    }
    
    // forbidden user interaction initiated selection.
    public override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
}


class LyricsTableViewCell : UITableViewCell {
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        let textColor = selected ? tintColor! : .darkText
        textLabel?.textColor = textColor
        detailTextLabel?.textColor = textColor
    }
}


private extension LyricsTableViewController {
    
    func configureObservers() {
        let playerController = SystemPlayerLyricsController.shared
        playerController.nowPlayingUpdateHandler = { [weak self] nowPlaying in
            DispatchQueue.main.async {
                if let nowPlaying = nowPlaying {
                    self?.lyrics = nowPlaying.lyrics
                    self?.title = nowPlaying.item.title
                } else {
                    self?.lyrics = nil
                    self?.title = "Not Playing"
                }
            }
        }
        playerController.lyricsLineUpdateHandler = { [weak self] line in
            DispatchQueue.main.async {
                self?.moveFocus(to: line)
            }
        }
        playerController.nowPlayingUpdateHandler?(playerController.nowPlaying)
    }
    
    func moveFocus(to line: LyricsLine) {
        guard let lyrics = lyrics,
            let index = lyrics.lines.firstIndex(where: { $0.position == line.position }) else { return }
        
        let indexPath = IndexPath(row: index, section: 0)
        guard indexPath != tableView.indexPathForSelectedRow else { return }
        
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        self.scrollToSelectedRowWhenIdle()
    }
}