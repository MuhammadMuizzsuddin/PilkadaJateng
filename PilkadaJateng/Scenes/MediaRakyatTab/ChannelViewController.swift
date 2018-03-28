//
//  ChannelViewController.swift
//  PilkadaJateng
//
//  Created by PondokiOS on 3/28/18.
//  Copyright © 2018 PondokiOS. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class ChannelListViewController: UIViewController {
    @IBOutlet weak var viewOutlets: ChannelListView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _setupTableView()
        viewOutlets.createChannelButton
            .addTarget(self,
                       action: #selector(ChannelListViewController.createChannel),
                       for: .touchUpInside)
    }
    
    private let _channelService = ChannelService()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _channelService.beginListening { [unowned self] in
            self.viewOutlets.tableView.reloadData()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        _channelService.endListening()
    }
    
    private func _setupTableView() {
        let tv = viewOutlets.tableView
        tv?.dataSource = self
        tv?.delegate = self
        
        let nib = UINib(nibName: "ChannelTableViewCell", bundle: nil)
        tv?.register(nib, forCellReuseIdentifier: "ChannelCell")
    }
    
    @objc func createChannel() {
        _channelService.createNew { (ref) in
            let newChannel = ref.childByAutoId()
            let channelItem = [
                "name":"Channel - \(arc4random() % 15)"
            ]
            newChannel.setValue(channelItem)
        }
    }
}

class ChannelListView: UIView {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var createChannelButton: UIButton!
}

extension ChannelListViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Channel Diskusi")
    }
}

extension ChannelListViewController: UITableViewDelegate {
    
}

extension ChannelListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _channelService.channels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell",for: indexPath) as! ChannelTableViewCell
        cell.channelNameLabel.text = _channelService.channels[indexPath.row].name
        return cell
    }
}
