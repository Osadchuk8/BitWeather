//
//  CitySearchVC.swift
//  SimplyWeather
//
//  Created by Oleksandr on 2018-06-09.
//  Copyright © 2018 Oleksandr. All rights reserved.
//

import UIKit
import MapKit

class CitySearchVC: UITableViewController {
    
    let searchGeoCoder = CLGeocoder()
    var matchingItems: [CLPlacemark] = []
    var resultStrings:[String] = [String]()
    //cant be init before actual assignemnt, BAD ACCESS: possible memory problem in CLPlacemark class
    var choosenPlacemark:CLPlacemark?
    
    
    
    //search controller results to be handled by this VC
    var searchController:UISearchController = UISearchController(searchResultsController: nil)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("*CitySearchVC viewDidLoad()")
        
        //
        searchController.searchResultsUpdater = self
        if #available(iOS 9.1, *) {
            searchController.obscuresBackgroundDuringPresentation = false
        } else {
            // Fallback on earlier versions
        }
        searchController.searchBar.placeholder = "City Name"
       //recommended option for handling searchController dismiss, but DOES NOT work, calling <searchController.isActive=false> instead
        //definesPresentationContext = true
        self.tableView.tableHeaderView = searchController.searchBar
        
        // Do any additional setup after loading the view.
    }
    override func viewDidDisappear(_ animated: Bool) {
        if self.searchController.isActive {
            self.searchController.isActive = false
        }
        self.searchController.dismiss(animated: true, completion: nil)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultStrings.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = resultStrings[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //
        self.searchController.isActive = false
        //self.searchController.dismiss(animated: true, completion: nil)
        
        let weatherVC = storyboard?.instantiateViewController(withIdentifier: "weather_vc") as! WeatherVC
        weatherVC.isCustomLocation = true
        
        //get location from choosen placemark
        if let location = choosenPlacemark?.location as CLLocation?{
            weatherVC.customLocation = location
        }else{
            weatherVC.isCustomLocation = false
        }
        
        self.present(weatherVC, animated: true, completion: nil)

        
    }

   
}

extension CitySearchVC: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let searchBarText = searchController.searchBar.text else {
            return
        }
       
        if searchGeoCoder.isGeocoding {
            searchGeoCoder.cancelGeocode()
        }
        
        searchGeoCoder.geocodeAddressString(searchBarText) {placemarks, error in
            guard let placemarks = placemarks, error == nil, placemarks.count>0 else {
                print("nothing found")
                return
            }
            self.resultStrings.removeAll()
            self.resultStrings.append(contentsOf: placemarks.map{
                [$0.locality, $0.administrativeArea, $0.country].flatMap{$0}.joined(separator: ", ")
            }
            )
            debugPrint("placemarks:", placemarks)
            self.choosenPlacemark = placemarks[0]
            print(self.choosenPlacemark)
        }
     
//        let mkSearchRec = MKLocalSearchRequest()
//        mkSearchRec.naturalLanguageQuery=searchBarText
//        
//        let mkSearch = MKLocalSearch.init(request: mkSearchRec)
//        mkSearch.start { (response, error) in
//            guard let arr = response?.mapItems, error == nil, (response?.mapItems.count)! > 0 else {
//                print("MKLocalSearch: Nothing found")
//                return
//            }
//            
//            var arrLocality = [String]()
//            for  item in arr {
//                if let locality = item.placemark.locality{
//                    arrLocality.append(locality)
//
          //  }
            
          //  print("MKLocalSearch array, locality:", arrLocality)
   //     }
        
         self.tableView.reloadData()
    }
    
}
