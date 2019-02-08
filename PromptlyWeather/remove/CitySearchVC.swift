//
//  CitySearchVC.swift
//  PromptlyWeather
//
//  Created by Oleksandr on 2018-06-09.
//  Copyright © 2018 Oleksandr. All rights reserved.
//

import UIKit
import MapKit

class CitySearchVC: UITableViewController {
    
    let searchGeoCoder = CLGeocoder()
    var StringPlaceArr = [[String:CLPlacemark]]()
    var matchingDict = [String:CLPlacemark]()
    //cant be init before actual assignemnt, BAD ACCESS: possible memory problem in CLPlacemark class
    var choosenPlacemark:CLPlacemark?
    
    //search controller results to be handled by this VC
    var searchController:UISearchController = UISearchController(searchResultsController: nil)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("*CitySearchVC viewDidLoad()")
        
        //
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        if #available(iOS 9.1, *) {
            searchController.obscuresBackgroundDuringPresentation = false
        } else {
            // Fallback on earlier versions
        }
        searchController.searchBar.placeholder = "City Name"
       
        //recommended option for handling searchController dismiss, but DOES NOT work, calling <searchController.isActive=false> instead
        definesPresentationContext = true
        self.tableView.tableHeaderView = searchController.searchBar
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reused")
        self.tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let sb = searchController.searchBar
        sb.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        sb.barTintColor = #colorLiteral(red: 0.2842133646, green: 0.4490221262, blue: 0.61857301, alpha: 1)
        sb.backgroundColor = nil
        //sb.searchBarStyle = .minimal
    
        if let textField = sb.value(forKey: "searchField") as? UITextField {
            textField.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            textField.backgroundColor = #colorLiteral(red: 0.2723602057, green: 0.3726737499, blue: 0.61857301, alpha: 1)
            if let iconImageView = textField.leftView as? UIImageView {
                iconImageView.image = iconImageView.image?.withRenderingMode(.alwaysTemplate)
                iconImageView.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            }
            if let placeHolder = textField.value(forKey: "placeholderLabel") as? UILabel {
                placeHolder.textColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
            }
            
        }
        

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if self.searchController.isActive {
            self.searchController.isActive = false
        }
        self.searchController.dismiss(animated: true, completion: nil)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return StringPlaceArr.count
        return matchingDict.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reused")
        cell?.backgroundColor = #colorLiteral(red: 0.2842133646, green: 0.4490221262, blue: 0.61857301, alpha: 1)
        cell?.textLabel?.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        // Reverse order to feed the table: most recent up. Limiting to 5 most recent.
        cell?.textLabel?.text = Array(matchingDict.keys)[matchingDict.count - 1 - indexPath.row]
            
            //(StringPlaceArr[(StringPlaceArr.count-1)-indexPath.row]).keys.first
            
            //resultStrings[ (resultStrings.count - 1) -  indexPath.row]
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //
        self.searchController.isActive = false
        //self.searchController.dismiss(animated: true, completion: nil)
        
        let weatherVC = storyboard?.instantiateViewController(withIdentifier: "weather_vc") as! WeatherVC
      //  weatherVC.isCustomLocation = true
        
        //get location from choosen placemark
        
        let placeMark = Array(matchingDict.values)[matchingDict.count - 1 - indexPath.row]
        
        if let location = placeMark.location as CLLocation?{
      //      weatherVC.customLocation = location
        }else{
      //      weatherVC.isCustomLocation = false
        }
        
        self.present(weatherVC, animated: true, completion: nil)

        
    }

   
}

extension CitySearchVC: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let searchBarText = searchController.searchBar.text, searchBarText.count>2  else { return }
        if searchGeoCoder.isGeocoding {
            searchGeoCoder.cancelGeocode()
        }
        print(".. searchBarText: ", searchBarText)
        searchGeoCoder.geocodeAddressString(searchBarText) {placemarks, error in
            guard let placemarks = placemarks, error == nil, placemarks.count>0
                else {
                    print("placemark not found")
                    return
            }
            let pMark = placemarks[0]
            
            guard let locality = pMark.locality, let area = pMark.administrativeArea, let country = pMark.country, locality.count > 2, area.count > 1 else {
                return
            }
            
            let pString = locality + ", " + area + ", " + country
            self.StringPlaceArr.append([pString:pMark])
            self.matchingDict.updateValue(pMark, forKey: pString)
            
            //self.matchingPlacemarks.append(placemarks[0])
            
        }
        
        self.tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("... searchBarCancelButtonClicked")
        if self.searchGeoCoder.isGeocoding{
            self.searchGeoCoder.cancelGeocode()
        }
        self.searchController.isActive = false
        let vc = storyboard?.instantiateViewController(withIdentifier: "weather_vc") as! WeatherVC
       // vc.isCustomLocation = false
        self.present(vc, animated: true, completion: nil)
    }
    
        
    
    
}
