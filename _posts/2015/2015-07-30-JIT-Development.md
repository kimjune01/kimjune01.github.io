---
layout: post
title: JIT Development
---


Just in Time, JIT for short, is a manufacturing principle that enables more output/time with a given set of resources. It was developed by Toyoda in the 70s and you can read all about it here.

I went to business school and this idea was one of the most profound lessons I learned. Agile Development is simply an extension of JIT manufacturing, but most often, the principles are misinterpreted. 

The success of Dell can be attributed to their principle of sell first, make second. This was against the current convention at the time where computers were made first, then stocked in stores, then eventually sold to customers. The volatile nature of the changing value of each computer in the retail value chain made each old computer less valuable. As soon as the new models came out, the old computers would have to drop their prices and be sold for a lower price or not at all. 

Software is much more volatile than computers. If we take a make-first, sell-second approach to software, then by the time that the software is finished development, then the market will have changed, and the app will have been outdated. There must be a better way.

Books such as the Lean Startup emphasize the fact that the purpose of a startup is to validate the market. Whether there is a releasable product at the end of a startup's journey is irrelevant. Prototyping and design thinking help along the way. A startup is an experiment. Iterate. We've heard this a million times before but we keep on making the same mistakes over. What are we missing?

We are missing the years of process development that manufacturing came up with. We call these organizational innovations. If you've worked in more than one environment for developing a product, you know that there's more than one way to get things done in a team, and some are better than others. We take these mini-lessons and apply it to our future. What if there was a way to get more lessons through other peoples' experiences and learn the principles behind these mini-lessons without going through the hardship ourselves? 

We're at step one again. How do we develop software better, faster, and with less stress? Let's look deeper into some of the details of JIT, starting with the Pull Principle. Unlike the mushy business talk that books talk about, let's do some coding, and see how a software developer can adopt this principle, and how it's better.

Here is an old way of writing a View Controller that lays out a collection view, fetches some data from the server, and populates that data into the collection view. Pretty standard.

```swift
class MainViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
 	//write code here
 
  }
  
  //...
  
}
 
```

It's an empty View Controller. Normally a developer would flesh out this empty view controller by specifying what it should look like and what it does. We make this view controller conform to the delegate and datasource for the collection view. And we watch the compiler complain about how the view controller does not conform to the protocols. The naive developer fixes this issue immediately by adding stub methods.


```swift
class MainViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

  var mainCollectionView:UICollectionView!
  
  //the stub methods below...

  func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    //
    return 0;
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    //
    return 0;
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    //
    return UICollectionViewCell();
  }
  
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    //
  }  
}
 
```

Now we are not so sure about what to do next. The development process now takes multiple directions. Should we write the code from top to bottom? But we don't have a data model to reference, in order to specify the number of sections. Should we subclass a UICollectionViewCell so that we can return smoething more meaningful? Should we segue to a detail View Controller and worry about that first? We can only write one line of code at a time. If we were to follow a Ray Wenderlich guide, we would often find code snippets that are unexplained until it's used later. Sometimes we even write code that we might need 'just in case'. 

What I am proposing is that the order in which you write code matters. Instead of sitting down, planning ahead of time about which classes you will need, and which patterns to use, it is possible to write high-quality code without the up-front costs. 

Write the interface before the implementation. 

It sounds simple, but it's easy to get sucked into thinking about how to do something rather than what to do. Let's take the same example, and see how I would approach it using the pull principle. I would first understand what the need is, and go from there. Earlier, we stated the purpose of this view controller:

1. lays out a collection view
2. fetches some data from the server
3. populates that data into the collection view

So we translate this into code directly:

```swift
class MainViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
	//lay out a collection view
	//fetch some data from the server
	//populate that data into the collection view
  }
  
}
 
```

But June! You didn't write any code! You would be right. I didn't write any code, but I specified exactly what this class should do. Let's keep going.

```swift
class MainViewController: UIViewController {

  var mainCollectionView:UICollectionView!

  override func viewDidLoad() {
    super.viewDidLoad()
	layoutCollectionView() //!!
	fetchData() //!!
	populateCollectionView() //!!
  }
  
}
 
```

Whoa. But those methods don't exist yet! You're crazy! Indeed I am. This code will break, and it should. I haven't made any calls to any iOS SDK APIs or to the server. But we will, and it matters in what order we do it in.


```swift

  func layoutCollectionView() {
  
  }
  
  func fetchData() {

	//upon completion, populateCollectionView()
  }
 
```

Whew! Now the code stopped breaking. But watch me break it again --


```swift

  func layoutCollectionView() {
    let collectionView = mainCollectionView()
	collectionView.frame = view.frame
    view.addSubview(mainCollectionView())
  }
  
  func fetchData() {
	ServerCaller.getListData() { data: NSDictionary in 
	  //TODO: upon completion, populateCollectionView()
	}
	
  }
 
```

But the method mainCollectionView doesn't exist yet! And ServerCaller isn't even a class that exists! Well, I already know that. Thanks for reminding me, Mr. Compiler. It's very obvious to me on what I should be working on.

The point to this approach is twofold: it always produces human-readable code, because the names for each method is written before it is fleshed out, and until the code is finished writing, the compiler will point to where I need to be working on. As a bonus, it makes sure that all the code I write gets used. No waste.

By first understanding what I need to do, I broke down the request from the business and design people into smaller, more manageable chunks. Then I broke that down into smaller pieces and kept on specifying the code. As changes are made, refactoring needs to be done, but that's with any development process. 

Write only as much code as you need to, only when you need to. Interface before implementation. So zen.






































