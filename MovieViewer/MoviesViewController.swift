//
//  MoviesViewController.swift
//  MovieViewer
//
//  Created by Malik Browne on 1/10/16.
//  Copyright © 2016 Malik Browne. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var networkErrorView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var endpoint: String!
    
    var filteredData: [NSDictionary]?
    var movies: [NSDictionary]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.titleTextAttributes = [
                NSFontAttributeName: UIFont.boldSystemFontOfSize(22),
                NSForegroundColorAttributeName: UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
            ]
            navigationBar.barTintColor = UIColor(red: 204.0/255.0, green: 225.0/255.0, blue: 232.0/255.0, alpha: 0.8)
        }
        
        self.tableView.contentInset = UIEdgeInsetsMake(0,0,0,0);
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        
        let topBar = UIView(frame: UIApplication.sharedApplication().statusBarFrame)
        topBar.backgroundColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        view.addSubview(topBar)
        
        // Initialize a UIRefreshControl
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refreshControlAction:", forControlEvents: UIControlEvents.ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: 0)
        
        
                if Reachability.isConnectedToNetwork() == true
                {
                    
                    UIView.animateWithDuration(0.15, animations: {
                        self.networkErrorView.alpha = 0
                        
                        let tableViewWidth = self.tableView.frame.width
                        self.tableView.frame = CGRectMake(0, 0, tableViewWidth, 582)
                    })
                    fetchStories()
                }
        
                else if Reachability.isConnectedToNetwork() == false
                {
                    self.networkErrorView.transform = CGAffineTransformMakeTranslation(0.0, 34.0)
                    self.tableView.contentInset = UIEdgeInsetsMake(0,0,0,0);
                    UIView.animateWithDuration(0.15, animations: {
                        self.networkErrorView.alpha = 1
                    })
                }
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        filteredData = searchText.isEmpty ? movies : movies!.filter({(dataString: NSDictionary) -> Bool in
            return (dataString["title"] as! String).rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
        })
        self.tableView.reloadData()
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
                            MBProgressHUD.hideHUDForView(self.view, animated: true)
                            NSLog("response: \(responseDictionary)")
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                            self.filteredData = self.movies
                            self.tableView.reloadData()
                    }
                }
        });
        task.resume()
    }
    
    func refreshControlAction(refreshControl: UIRefreshControl)
    {
        if Reachability.isConnectedToNetwork() == true {
            UIView.animateWithDuration(0.15, animations: {
                self.networkErrorView.alpha = 0
                let tableViewWidth = self.tableView.frame.width
                self.tableView.frame = CGRectMake(0, 0, tableViewWidth, 582)
                self.networkErrorView.transform = CGAffineTransformMakeTranslation(0.0, -34.0)
            })
            
        fetchStories()
        self.tableView.reloadData()
        refreshControl.endRefreshing()
            
        }
        
        else if Reachability.isConnectedToNetwork() == false {
            self.tableView.reloadData()
            refreshControl.endRefreshing()
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let filteredData = filteredData {
            return filteredData.count
        }
        else {
            return 0
        }
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        
        let movie = filteredData![indexPath.row]
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        
        let baseUrl = "http://image.tmdb.org/t/p/w500"
        if let posterPath = movie["poster_path"] as? String {
            let imageUrl = NSURL(string: baseUrl + posterPath)
            cell.posterView.setImageWithURL(imageUrl!)
        }
        
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        cell.selectionStyle = .Blue
            
        return cell
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPathForCell(cell)
        let movie = movies![indexPath!.row]
        
        let detailViewController = segue.destinationViewController as! DetailViewController
        detailViewController.movie = movie
        
        
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }

    
}
