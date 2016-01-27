//
//  CollectionViewController.swift
//  MovieViewer
//
//  Created by Malik Browne on 1/26/16.
//  Copyright © 2016 Malik Browne. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class CollectionViewController: UIViewController, UISearchBarDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var networkErrorView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var endpoint: String!
    var movies: [NSDictionary]?
    var filteredData: [NSDictionary]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.titleTextAttributes = [
                NSFontAttributeName: UIFont.boldSystemFontOfSize(22),
                NSForegroundColorAttributeName: UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
            ]
            navigationBar.barTintColor = UIColor(red: 204.0/255.0, green: 225.0/255.0, blue: 232.0/255.0, alpha: 0.8)
        }
        collectionView.backgroundColor = UIColor(red: 204.0/255.0, green: 225.0/255.0, blue: 232.0/255.0, alpha: 0.8)
        self.collectionView.alwaysBounceVertical = true;
        collectionView.dataSource = self
        searchBar.delegate = self
        // Do any additional setup after loading the view.
        
        // Initialize a UIRefreshControl
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refreshControlAction:", forControlEvents: UIControlEvents.ValueChanged)
        collectionView.insertSubview(refreshControl, atIndex: 0)

        fetchStories()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
    filteredData = searchText.isEmpty ? movies : movies!.filter({(dataString: NSDictionary) -> Bool in
    return (dataString["title"] as! String).rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
    })
    self.collectionView.reloadData()
    }
    
    func fetchStories()
    {
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string:"https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = NSURLRequest(URL: url!)
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue()
        )
        
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                            if error == nil {
                            self.networkErrorView.alpha = 0
                            NSLog("response: \(responseDictionary)")
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                            self.filteredData = self.movies
                            self.collectionView.reloadData()
                            }
                            
                            else {
                                self.searchBar.alpha = 0
                                let collectionViewWidth = self.collectionView.frame.width
                                self.collectionView.frame = CGRectMake(0, 0, collectionViewWidth, 582)
                            }
                    }
                }
                MBProgressHUD.hideHUDForView(self.view, animated: true)
        });
        task.resume()
    }
    
    func refreshControlAction(refreshControl: UIRefreshControl)
    {
            fetchStories()
            self.collectionView.reloadData()
            refreshControl.endRefreshing()
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
            
            let cell = sender as! UICollectionViewCell
            let indexPath = collectionView.indexPathForCell(cell)
            let movie = filteredData![indexPath!.row]
            
            let detailViewController = segue.destinationViewController as! DetailViewController
            detailViewController.movie = movie

        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        
        return true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
    }
    
}

extension CollectionViewController: UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let filteredData = filteredData {
            return filteredData.count
        }
        else
        {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PosterCell", forIndexPath: indexPath) as! PosterViewCell
        
        let movie = filteredData![indexPath.row]
        
        let lowBaseUrl = "https://image.tmdb.org/t/p/w45"
        let highBaseUrl = "https://image.tmdb.org/t/p/original"
        if let posterPath = movie["poster_path"] as? String {
            
            let smallImageUrl = NSURL(string: lowBaseUrl + posterPath)
            let largeImageUrl = NSURL(string: highBaseUrl + posterPath)
            
            let smallImageRequest = NSURLRequest(URL: smallImageUrl!)
            let largeImageRequest = NSURLRequest(URL: largeImageUrl!)
            let myImageView = cell.posterView
            
            myImageView.setImageWithURLRequest(
                smallImageRequest,
                placeholderImage: nil,
                success: { (smallImageRequest, smallImageResponse, smallImage) -> Void in
                    
                    // smallImageResponse will be nil if the smallImage is already available
                    // in cache (might want to do something smarter in that case).
                    myImageView.alpha = 0.0
                    myImageView.image = smallImage;
                    
                    UIView.animateWithDuration(0.3, animations: { () -> Void in
                        
                        myImageView.alpha = 1.0
                        
                        }, completion: { (sucess) -> Void in
                            
                            // The AFNetworking ImageView Category only allows one request to be sent at a time
                            // per ImageView. This code must be in the completion block.
                            myImageView.setImageWithURLRequest(
                                largeImageRequest,
                                placeholderImage: smallImage,
                                success: { (largeImageRequest, largeImageResponse, largeImage) -> Void in
                                    
                                    myImageView.image = largeImage;
                                    
                                },
                                failure: { (request, response, error) -> Void in
                                    // do something for the failure condition of the large image request
                                    // possibly setting the ImageView's image to a default image
                            })
                    })
                },
                failure: { (request, response, error) -> Void in
                    // do something for the failure condition
                    // possibly try to get the large image
            })
            
        }

        return cell
    }
}
