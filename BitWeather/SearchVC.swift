//
//  SearchVC.swift
//  BitWeather
//
//  Created by Oleksandr on 2019-01-21.
//  Copyright © 2019 Oleksandr. All rights reserved.
//


import Foundation
import UIKit
import CoreLocation

class SearchVC: UIViewController, UISearchBarDelegate {
    
    
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var tableView: UITableView!
    
    
    var placeMarkDict = [String:CLPlacemark]()
    
    let geoCoder = CLGeocoder()
   // var searchController = UISearchController(searchResultsController: nil)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       // searchController.searchResultsUpdater = self
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.becomeFirstResponder()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        searchBar.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        //searchBar.barTintColor = #colorLiteral(red: 0.2842133646, green: 0.4490221262, blue: 0.61857301, alpha: 1)
        searchBar.backgroundColor = nil
       // searchBar.searchBarStyle = .minimal
        searchBar.showsScopeBar = false
        
        //storyboard (return button) overrides this(ios 11.x)
        searchBar.returnKeyType = .done
        
        
        //TODO #IF_IOS9*
        let scopeBarContainer: UIView? = searchBar.subviews.first?.subviews.first
        if let _ = scopeBarContainer?.subviews.first(where: { $0.isKind(of: UISegmentedControl.self) } ) {
            scopeBarContainer?.isHidden = true
        }
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
           // textField.backgroundColor = #colorLiteral(red: 0.2723602057, green: 0.3726737499, blue: 0.61857301, alpha: 1)
            if let iconImageView = textField.leftView as? UIImageView {
                iconImageView.image = iconImageView.image?.withRenderingMode(.alwaysTemplate)
                iconImageView.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            }
            if let placeHolder = textField.value(forKey: "placeholderLabel") as? UILabel {
                placeHolder.textColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
            }
            
        }
        
    }
    
    @IBAction func onTapCloseSearch(_ sender: Any) {
        
        if geoCoder.isGeocoding {
            geoCoder.cancelGeocode()
        }
        AppShared.needsRefresh = false
        self.dismiss(animated: true, completion: nil)
        
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText.count<1 {
            placeMarkDict.removeAll()
            tableView.reloadData()
        }else if searchText.count<3 {
            //don't geocode less then 3 chars
            return
        }else{
            if geoCoder.isGeocoding {
                geoCoder.cancelGeocode()
            }
//            print("\n .. searchBarText to geocode: ", searchText)
           
            geoCoder.geocodeAddressString(searchText) {placemarks, error in
                guard let placemarks = placemarks, error == nil, placemarks.count>0
                    else {
                        //print("placemark not found")
                        return
                }
                let pMark = placemarks[0]
//                print("pMark:  \(pMark)")
                guard let locality = pMark.locality, let area = pMark.administrativeArea, let country = pMark.country, locality.count > 2 else {
                    return
                }
                
                if locality.prefix(3).lowercased() != searchText.prefix(3).lowercased()
                    && area.prefix(3).lowercased() != searchText.prefix(3).lowercased(){
//                    print(locality.prefix(3).lowercased(), " :(!=): ", searchText.prefix(3).lowercased())
                    return
                }
                
                // key pString like: 'Montreal, Qc, Canada'
                let pString = locality + ", " + area + ", " + country
                self.placeMarkDict.updateValue(pMark, forKey: pString)
                self.tableView.reloadData()
            }
        }
    }
    
    //search Button title  can be .done and .cancel as well
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        //print("--searchBarSearchButtonClicked")
    }
    

    
//CLASS END
}

extension SearchVC: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return placeMarkDict.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        cell?.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        cell?.textLabel?.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        // Reverse order to feed the table: most recent up. Limiting to 5 most recent.
        cell?.textLabel?.text = Array(placeMarkDict.keys)[placeMarkDict.count - 1 - indexPath.row]
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let placeMark = Array(placeMarkDict.values)[placeMarkDict.count - 1 - indexPath.row]
        
        if let location = placeMark.location as CLLocation?{
            AppShared.location = location
            AppShared.isGpsLocation = false
            AppShared.needsGpsLocationWeather = false
            AppShared.needsRefresh = true
            
        }else{
        }
        
        if let zone = placeMark.timeZone as TimeZone? {
            AppShared.timeZone = zone
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
}
