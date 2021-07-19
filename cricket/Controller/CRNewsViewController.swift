//
//  CRNewsViewController.swift
//  cricket
//
//  Created by Amrith J H on 15/07/21.
//

import UIKit
import CoreData

class CRNewsViewController: UIViewController {
    @IBOutlet weak var topicLabel: UILabel!
    @IBOutlet weak var newsTableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var topicLabelTopConstraint: NSLayoutConstraint!
    
    private var reachability: Reachability!
    lazy var page: Int = 1
    lazy var totalSize = 0
    
    var resultArray : [Result1] = []
    var people: [NSManagedObject] = []
    let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
    var saveComplete : Bool = false {
        didSet{
            retrieveData()
            newsTableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        registerTableViewCell()
        checkForNetworkConnection()
        observeReachability()
    }
    
    func observeReachability(){
        do {
            reachability = try Reachability()
        } catch {}
        
        NotificationCenter.default.addObserver(self, selector:#selector(self.reachabilityChanged), name: NSNotification.Name.reachabilityChanged, object: nil)
        do {
            try self.reachability.startNotifier()
        }
        catch(let error) {
            print("Error occured while starting reachability notifications : \(error.localizedDescription)")
        }
    }
    
    @objc func reachabilityChanged(note: Notification) {
        let reachability = note.object as! Reachability
        switch reachability.connection {
        case .cellular, .wifi:
            self.searchButton.isHidden = false
            self.searchTextField.isHidden = false
            self.noDataLabel.isHidden = true
            self.topicLabelTopConstraint.constant = 30
            break
            
        case .unavailable:
            self.searchButton.isHidden = true
            self.searchTextField.resignFirstResponder()
            self.searchTextField.isHidden = true
            self.retrieveData()
            self.noDataLabel.isHidden = true
            self.topicLabelTopConstraint.constant = 0
            self.newsTableView.reloadData()
            self.newsTableView.isHidden = false
            if self.people.count != 0{
                self.topicLabel.isHidden = false
                self.topicLabel.text = UserDefaults.standard.string(forKey: "UserEnteredSearchText")?.uppercased()
            } else {
                self.noDataLabel.isHidden = false
                self.noDataLabel.text = Constants.noOfflineData
            }
            break
        }
    }
    
    func configureUI(){
        //Hide Topic label
        self.topicLabel.isHidden = true
        
        //Nodata label
        self.noDataLabel.textAlignment = .center
        self.noDataLabel.numberOfLines = 0
        self.view.addSubview(self.noDataLabel)
        self.noDataLabel.isHidden = true
        let maxSize = CGSize(width: 300, height: 300)
        self.noDataLabel.frame = CGRect(origin: noDataLabel.frame.origin, size: maxSize)
        self.noDataLabel.center = self.view.center
        
        
        //VC title
        self.title = Constants.navigationTitle
        
        //Navigation barItem title
        let backItem = UIBarButtonItem()
        backItem.title = Constants.back
        navigationItem.backBarButtonItem = backItem
        
        //Update Textfield UI
        searchTextField.layer.cornerRadius = 15.0
        searchTextField.layer.borderWidth = 1.0
        searchTextField.layer.borderColor = UIColor.black.cgColor
        
        //UIButton UI
        // searchButton.backgroundColor = UIColor(red: 171/255, green: 178/255, blue: 186/255, alpha: 1.0)
        // Shadow Color and Radius
        searchButton.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        searchButton.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        searchButton.layer.shadowOpacity = 1.0
        searchButton.layer.shadowRadius = 0.0
        searchButton.layer.masksToBounds = false
        searchButton.layer.cornerRadius = 4.0
    }
    
    func checkForNetworkConnection() {
        if !Reachability.isConnectedToNetwork() {
            searchButton.isHidden = true
            searchTextField.isHidden = true
            self.retrieveData()
            newsTableView.reloadData()
            self.newsTableView.isHidden = false
        } else {
            searchButton.isHidden = false
            searchTextField.isHidden = false
        }
    }
    
    
    //MARK: Register tableView Cell
    func registerTableViewCell(){
        newsTableView.registerCell(CRNewsTableViewCell.self)
    }
    
    //MARK: API call to fetch data
    func fetchData(searchText: String, page: Int){
        
        
        
        let defaultSession = URLSession(configuration: .default)
        var dataTask: URLSessionDataTask?
        dataTask?.cancel()
        
        if var urlComponents = URLComponents(string: Constants.apiUrl) {
            urlComponents.query = "page=\(page)&page-size=10&q=\(searchText.lowercased())&api-key=\(Constants.apiKey)"
            
            guard  let url = urlComponents.url else {
                return
            }
            dataTask = defaultSession.dataTask(with: url) { data, response, error in
                if error != nil {
                    self.handleError()
                    return
                }
                
                if let data = data {
                    do{
                        let jsonDecoder = JSONDecoder()
                        let responseModel = try jsonDecoder.decode(CRNewsModel.self, from: data)
                        self.resultArray = responseModel.response.results
                        self.totalSize = responseModel.response.total
                        DispatchQueue.main.async {
                            self.updateTableView(valueArr: self.resultArray)
                        }
                    } catch {
                        self.handleError()
                    }
                }
            }
            dataTask?.resume()
        }
    }
    
    func handleError(){
        DispatchQueue.main.async {
            self.noDataLabel.isHidden = true
        }
    }
    
    
    //MARK: Handle Table view UI
    func updateTableView(valueArr: [Result1]){
        if valueArr.count == 0{
            self.newsTableView.isHidden = true
            self.noDataLabel.isHidden = false
            self.topicLabel.isHidden = true
            self.noDataLabel.text = Constants.noData
        } else {
            saveData(valueArr: valueArr)
            self.topicLabel.isHidden = false
            self.newsTableView.isHidden = false
            self.noDataLabel.isHidden = true
            self.newsTableView.reloadData()
            
            
        }
    }
    
    func saveData(valueArr: [Result1]){
        self.save(valueArr: valueArr)
    }
    
    //MARK: Search text action
    @IBAction func searchAction(_ sender: Any) {
        noDataLabel.isHidden = true
        searchTextField.resignFirstResponder()
        deleteEntityItems()
        if let searchText = self.searchTextField.text{
            if searchText == "" {
                self.newsTableView.isHidden = true
                self.noDataLabel.isHidden = false
                self.topicLabel.isHidden = true
                self.noDataLabel.text = Constants.provideSearchText
            } else {
                UserDefaults.standard.setValue(searchText, forKey: "UserEnteredSearchText")
                fetchData(searchText: searchText, page: 1)
                self.topicLabel.text = searchText.uppercased()
                self.topicLabel.isHidden = false
            }
        } else {
            self.noDataLabel.isHidden = false
            self.newsTableView.isHidden = true
            self.topicLabel.isHidden = true
            self.noDataLabel.text = Constants.provideSearchText
        }
    }
}


extension CRNewsViewController : UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    //MARK: TableView DataSource and Delegate methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.people.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if UIDevice.current.orientation.isLandscape {
            return 100
        } else  if UIDevice.current.orientation.isPortrait {
            return 140
        }
        return 140
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let person = people[indexPath.row]
        self.newsTableView.isHidden = false
        let cell = tableView.dequeueReusableCell(withIdentifier: "CRNewsTableViewCell") as! CRNewsTableViewCell
        
        if let title = person.value(forKeyPath: "title") as? String,
           let date = person.value(forKeyPath: "date") as? String {
            cell.titleLabel.text = title
            cell.bodyLabel.text = title
            cell.dateLabel.text = self.configureDate(date: date)
        }
        cell.selectionStyle = .none
        cell.layer.cornerRadius = 10
        cell.layer.masksToBounds = true
        cell.isCellDisplayed = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let person = people[indexPath.row]
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let resultViewController = storyBoard.instantiateViewController(withIdentifier: "detail") as! CRNewsDetailViewController
        self.navigationController?.pushViewController(resultViewController, animated: true)
        
        DispatchQueue.main.async {
            
            if let title = person.value(forKeyPath: "title") as? String,
               let date = person.value(forKeyPath: "date") as? String,
               let url = person.value(forKeyPath: "apiUrl") as? String,
               let sectionName = person.value(forKeyPath: "sectionName") as? String,
               let text = UserDefaults.standard.string(forKey: "UserEnteredSearchText") {
                
                resultViewController.webPublicationTitleLabel.text = title
                resultViewController.webPublicationDateLabel.text = "Date: \(self.configureDate(date: date))"
                resultViewController.bodyLabel.addLineSpacing(text: Constants.bodyText)
                resultViewController.webUrlLabel.text = url
                resultViewController.sectionNameLabel.text = "Section: \(sectionName)"
                resultViewController.url = url
                resultViewController.newsImageView.image = UIImage(named: "8192")
                resultViewController.title = text.firstUppercased
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CRNewsTableViewCell") as! CRNewsTableViewCell
        cell.transform = CGAffineTransform(translationX: 0, y: tableView.bounds.size.height)
        var delayCounter = 0
        UIView.animate(withDuration: 1.6, delay: 0.08 * Double(delayCounter),usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            cell.transform = CGAffineTransform.identity
        }, completion: nil)
        delayCounter += 1
    }
    
    
    func configureDate(date: String) -> String{
        let originalDate = date
        var newDate = ""
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ"
        let convertStringToDate = dateformatter.date(from: originalDate)
        dateformatter.dateFormat = "dd MMMM, yyyy HH:mm"
        newDate = dateformatter.string(from: convertStringToDate!)
        return newDate
    }
    
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !Reachability.isConnectedToNetwork() { return }
        
        if totalSize/10 < page {
            return
        }
        
        page = page + 1
        if let text = UserDefaults.standard.string(forKey: "UserEnteredSearchText") {
            fetchData(searchText: text, page: page)
        }
    }
}


extension UITableView {
    
    func registerCell<T: UITableViewCell>(_: T.Type) {
        let nib = UINib(nibName: T.nibName, bundle: nil)
        register(nib, forCellReuseIdentifier: T.reuseIdentifier)
    }
    
    func dequeueReusableCell<T: UITableViewCell>(forIndexPath indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath as IndexPath)
                as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }
        return cell
    }
}

extension UITableViewCell: ReusableView { }
extension UITableViewCell: NibLoadableView { }
extension NibLoadableView where Self: UIView {
    static var nibName: String {
        return String(describing: self)
    }
}
extension ReusableView where Self: UIView {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

protocol NibLoadableView: AnyObject {}
protocol ReusableView: AnyObject {}

extension CRNewsViewController {
    
    //MARK: Save data to SQLlite
    func save(valueArr: [Result1]) {
        
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            
            let managedContext = appDelegate.persistentContainer.viewContext
            
            for i in 0..<valueArr.count {
                let person = NSEntityDescription.insertNewObject(forEntityName: "Cricket", into: managedContext)
                person.setValue(valueArr[i].webUrl, forKey: "apiUrl")
                person.setValue(valueArr[i].webTitle, forKey: "title")
                person.setValue(valueArr[i].sectionName, forKey: "sectionName")
                person.setValue(valueArr[i].webPublicationDate, forKey: "date")
                self.people.append(person)
            }
            
            do {
                try managedContext.save()
                self.saveComplete = true
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }
    
    //MARK: Retrieve data from SQLlite
    func retrieveData(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Cricket")
        do {
            people = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    
    func deleteEntityItems(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Cricket")
        let managedContext = appDelegate.persistentContainer.viewContext
        fetchRequest.includesPropertyValues = false
        
        do {
            let items = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
            
            for item in items {
                managedContext.delete(item)
            }
            
            // Save Changes
            try managedContext.save()
            
        } catch {
            print("Delete and Save failed")
        }
    }
}

extension StringProtocol {
    var firstUppercased: String { return prefix(1).uppercased() + dropFirst() }
    var firstCapitalized: String { return prefix(1).capitalized + dropFirst() }
}

extension UITableView {
    
    func reloadWithAnimation() {
        self.reloadData()
        let tableViewHeight = self.bounds.size.height
        let cells = self.visibleCells
        var delayCounter = 0
        for cell in cells {
            cell.transform = CGAffineTransform(translationX: 0, y: tableViewHeight)
        }
        for cell in cells {
            UIView.animate(withDuration: 1.6, delay: 0.08 * Double(delayCounter),usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                cell.transform = CGAffineTransform.identity
            }, completion: nil)
            delayCounter += 1
        }
    }
}



