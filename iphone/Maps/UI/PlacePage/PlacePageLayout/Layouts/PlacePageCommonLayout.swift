class PlacePageCommonLayout: NSObject, IPlacePageLayout {
  private var placePageData: PlacePageData
  private var interactor: PlacePageInteractor
  private let storyboard: UIStoryboard
  weak var presenter: PlacePagePresenterProtocol?

  lazy var viewControllers: [UIViewController] = {
    return configureViewControllers()
  }()

  var actionBar: UIViewController? {
    return actionBarViewController
  }

  var adState: AdBannerState = .unset {
    didSet {
      previewViewController.adView.state = self.adState
    }
  }

  lazy var previewViewController: PlacePagePreviewViewController = {
    let vc = storyboard.instantiateViewController(ofType: PlacePagePreviewViewController.self)
    vc.placePagePreviewData = placePageData.previewData
    vc.delegate = interactor
    return vc
  } ()
  
  lazy var catalogSingleItemViewController: CatalogSingleItemViewController = {
    let vc = storyboard.instantiateViewController(ofType: CatalogSingleItemViewController.self)
    vc.view.isHidden = true
    vc.delegate = interactor
    return vc
  } ()
  
  lazy var catalogGalleryViewController: CatalogGalleryViewController = {
    let vc = storyboard.instantiateViewController(ofType: CatalogGalleryViewController.self)
    vc.view.isHidden = true
    vc.delegate = interactor
    return vc
  } ()
  
  lazy var wikiDescriptionViewController: WikiDescriptionViewController = {
    let vc = storyboard.instantiateViewController(ofType: WikiDescriptionViewController.self)
    vc.view.isHidden = true
    vc.delegate = interactor
    return vc
  } ()
  
  lazy var bookmarkViewController: PlacePageBookmarkViewController = {
    let vc = storyboard.instantiateViewController(ofType: PlacePageBookmarkViewController.self)
    vc.view.isHidden = true
    vc.delegate = interactor
    return vc
  } ()
  
  lazy var infoViewController: PlacePageInfoViewController = {
    let vc = storyboard.instantiateViewController(ofType: PlacePageInfoViewController.self)
    vc.placePageInfoData = placePageData.infoData
    vc.delegate = interactor
    return vc
  } ()
  
  lazy var taxiViewController: TaxiViewController = {
    let vc = storyboard.instantiateViewController(ofType: TaxiViewController.self)
    vc.taxiProvider = placePageData.taxiProvider
    vc.delegate = interactor
    return vc
  } ()
  
  lazy var ratingSummaryViewController: RatingSummaryViewController = {
    let vc = storyboard.instantiateViewController(ofType: RatingSummaryViewController.self)
    vc.view.isHidden = true
    return vc
  } ()
  
  lazy var addReviewViewController: AddReviewViewController = {
    let vc = storyboard.instantiateViewController(ofType: AddReviewViewController.self)
    vc.view.isHidden = true
    vc.delegate = interactor
    return vc
  } ()
  
  lazy var reviewsViewController: PlacePageReviewsViewController = {
    let vc = storyboard.instantiateViewController(ofType: PlacePageReviewsViewController.self)
    vc.view.isHidden = true
    vc.delegate = interactor
    return vc
  } ()
  
  lazy var buttonsViewController: PlacePageButtonsViewController = {
    let vc = storyboard.instantiateViewController(ofType: PlacePageButtonsViewController.self)
    vc.buttonsData = placePageData.buttonsData!
    vc.delegate = interactor
    return vc
  } ()
  
  lazy var hotelPhotosViewController: HotelPhotosViewController = {
    let vc = storyboard.instantiateViewController(ofType: HotelPhotosViewController.self)
    vc.view.isHidden = true
    vc.delegate = interactor
    return vc
  } ()
  
  lazy var hotelDescriptionViewController: HotelDescriptionViewController = {
    let vc = storyboard.instantiateViewController(ofType: HotelDescriptionViewController.self)
    vc.view.isHidden = true
    vc.delegate = interactor
    return vc
  } ()
  
  lazy var hotelFacilitiesViewController: HotelFacilitiesViewController = {
    let vc = storyboard.instantiateViewController(ofType: HotelFacilitiesViewController.self)
    vc.view.isHidden = true
    vc.delegate = interactor
    return vc
  } ()
  
  lazy var hotelReviewsViewController: HotelReviewsViewController = {
    let vc = storyboard.instantiateViewController(ofType: HotelReviewsViewController.self)
    vc.view.isHidden = true
    vc.delegate = interactor
    return vc
  } ()
  
  lazy var actionBarViewController: ActionBarViewController = {
    let vc = storyboard.instantiateViewController(ofType: ActionBarViewController.self)
    vc.placePageData = placePageData
    vc.canAddStop = MWMRouter.canAddIntermediatePoint()
    vc.isRoutePlanning = MWMNavigationDashboardManager.shared().state != .hidden
    vc.delegate = interactor
    return vc
  } ()
  
  
  init(interactor: PlacePageInteractor, storyboard: UIStoryboard, data: PlacePageData) {
    self.interactor = interactor
    self.storyboard = storyboard
    self.placePageData = data
  }
  
  private func configureViewControllers() -> [UIViewController] {
    var viewControllers = [UIViewController]()
    viewControllers.append(previewViewController)
    if placePageData.isPromoCatalog {
      viewControllers.append(catalogSingleItemViewController)
      viewControllers.append(catalogGalleryViewController)
      placePageData.loadCatalogPromo(completion: onLoadCatalogPromo)
    }

    viewControllers.append(wikiDescriptionViewController)
    if let wikiDescriptionHtml = placePageData.wikiDescriptionHtml {
      wikiDescriptionViewController.descriptionHtml = wikiDescriptionHtml
      if placePageData.bookmarkData?.bookmarkDescription == nil && !placePageData.isPromoCatalog {
        wikiDescriptionViewController.view.isHidden = false
      }
    }

    viewControllers.append(bookmarkViewController)
    if let bookmarkData = placePageData.bookmarkData {
      bookmarkViewController.bookmarkData = bookmarkData
      bookmarkViewController.view.isHidden = false
    }

    viewControllers.append(hotelPhotosViewController)
    viewControllers.append(hotelDescriptionViewController)
    viewControllers.append(hotelFacilitiesViewController)
    viewControllers.append(hotelReviewsViewController)

    if placePageData.infoData != nil {
      viewControllers.append(infoViewController)
    }

    if placePageData.taxiProvider != .none {
      viewControllers.append(taxiViewController)
    }

    if placePageData.previewData.showUgc {
      viewControllers.append(ratingSummaryViewController)
      viewControllers.append(addReviewViewController)
      viewControllers.append(reviewsViewController)
      placePageData.loadUgc(completion: onLoadUgc)
    }

    if placePageData.previewData.hasBanner,
      let banners = placePageData.previewData.banners {
      BannersCache.cache.get(coreBanners: banners, cacheOnly: false, loadNew: true, completion: onGetBanner)
    }

    if placePageData.buttonsData != nil {
      viewControllers.append(buttonsViewController)
    }
    
    placePageData.loadOnlineData(completion: onLoadOnlineData)

    MWMLocationManager.add(observer: self)
    if let lastLocation = MWMLocationManager.lastLocation() {
      onLocationUpdate(lastLocation)
    }
    if let lastHeading = MWMLocationManager.lastHeading() {
      onHeadingUpdate(lastHeading)
    }

    return viewControllers
  }

  func calculateSteps(inScrollView scrollView: UIScrollView) -> [PlacePageState] {
    var steps: [PlacePageState] = []
    let scrollHeight = scrollView.height
    steps.append(.closed(-scrollHeight))
    guard let preview = previewViewController.view else {
      return steps
    }
    let previewFrame = scrollView.convert(preview.bounds, from: preview)
    steps.append(.preview(previewFrame.maxY - scrollHeight))
    if placePageData.isPreviewPlus {
      steps.append(.previewPlus(-scrollHeight * 0.55))
    }
    steps.append(.expanded(-scrollHeight * 0.3))
    return steps
  }
}


// MARK: - PlacePageData async callbacks for loaders

extension PlacePageCommonLayout {
  func onLoadOnlineData() {
    if let bookingData = self.placePageData.hotelBooking {
      previewViewController.updateBooking(bookingData, rooms: self.placePageData.hotelRooms)
      presenter?.layoutIfNeeded()
      UIView.animate(withDuration: kDefaultAnimationDuration) {
        if !bookingData.photos.isEmpty {
          self.hotelPhotosViewController.photos = bookingData.photos
          self.hotelPhotosViewController.view.isHidden = false
        }
        self.hotelDescriptionViewController.hotelDescription = bookingData.hotelDescription
        self.hotelDescriptionViewController.view.isHidden = false
        if bookingData.facilities.count > 0 {
          self.hotelFacilitiesViewController.facilities = bookingData.facilities
          self.hotelFacilitiesViewController.view.isHidden = false
        }
        if bookingData.reviews.count > 0 {
          self.hotelReviewsViewController.reviewCount = bookingData.scoreCount
          self.hotelReviewsViewController.totalScore = bookingData.score
          self.hotelReviewsViewController.reviews = bookingData.reviews
          self.hotelReviewsViewController.view.isHidden = false
        }
        self.presenter?.layoutIfNeeded()
      }
    }
  }

  func onLoadUgc() {
    if let ugcData =  self.placePageData.ugcData {
      previewViewController.updateUgc(ugcData)

      if !ugcData.isTotalRatingEmpty {
        ratingSummaryViewController.ugcData = ugcData
        ratingSummaryViewController.view.isHidden = false
      }
      if ugcData.isUpdateEmpty {
        addReviewViewController.view.isHidden = false
      }
      if !ugcData.isEmpty {
        reviewsViewController.ugcData = ugcData
        reviewsViewController.view.isHidden = false
      }
      presenter?.updatePreviewOffset()
    }
  }

  func onLoadCatalogPromo() {
    guard let catalogPromo = self.placePageData.catalogPromo else {
      if self.placePageData.wikiDescriptionHtml != nil {
        wikiDescriptionViewController.view.isHidden = false
      }
      return
    }
    if catalogPromo.promoItems.count == 1 {
      catalogSingleItemViewController.promoItem = catalogPromo.promoItems.first!
      catalogSingleItemViewController.view.isHidden = false
    } else {
      catalogGalleryViewController.promoData = catalogPromo
      catalogGalleryViewController.view.isHidden = false
      if self.placePageData.wikiDescriptionHtml != nil {
        wikiDescriptionViewController.view.isHidden = false
      }
    }
  }

  func onGetBanner(banner: MWMBanner, loadNew: Bool) -> Void {
    previewViewController.updateBanner(banner)
    presenter?.updatePreviewOffset()
  }
}

// MARK: - MWMLocationObserver

extension PlacePageCommonLayout: MWMLocationObserver {
  func onHeadingUpdate(_ heading: CLHeading) {
    if heading.trueHeading < 0 {
      return
    }

    let rad = heading.trueHeading * Double.pi / 180
    previewViewController.updateHeading(CGFloat(rad))
  }

  func onLocationUpdate(_ location: CLLocation) {
    let ppLocation = CLLocation(latitude: placePageData.locationCoordinate.latitude,
                                longitude: placePageData.locationCoordinate.longitude)
    let distance = location.distance(from: ppLocation)
    let distanceFormatter = MKDistanceFormatter()
    distanceFormatter.unitStyle = .abbreviated
    let formattedDistance = distanceFormatter.string(fromDistance: distance)
    previewViewController.updateDistance(formattedDistance)
  }

  func onLocationError(_ locationError: MWMLocationStatus) {

  }
}
