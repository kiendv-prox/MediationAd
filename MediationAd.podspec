Pod::Spec.new do |s|
    s.name             = 'MediationAd'
    s.version          = '1.0.0'
    s.summary          = 'A lightweight Swift package for ad mediation with multiple ad networks.'
    s.description      = <<-DESC
        MediationAd provides a unified interface to manage ad mediation across multiple ad networks,
        including AppLovin MAX (13.3.1), Google AdMob, Meta Audience Network, and Unity Ads.
        It simplifies ad integration using a modular Swift-based structure.
    DESC
    s.homepage         = 'https://github.com/kiendv-prox/MediationAd'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'KienDV' => 'kiendv@proxglobal.com' }
    s.source           = {
        :git => 'https://github.com/kiendv-prox/MediationAd.git',
        :tag => s.version.to_s
    }
    
    s.ios.deployment_target = '13.0'
    s.static_framework = true
    s.source_files     = 'MediationAd/**/*.{swift,h}'
    
    s.pod_target_xcconfig = {
        'OTHER_LDFLAGS' => '-ObjC'
    }
    
    s.user_target_xcconfig = {
        'OTHER_LDFLAGS' => '-ObjC'
    }

    # Dependency with version pinning
    s.dependency 'AppLovinSDK', '13.3.1'
        
    # Dependency AppLovin Adapter
    s.dependency 'AppLovinMediationGoogleAdapter'
    s.dependency 'AppLovinMediationUnityAdsAdapter'
    s.dependency 'AppLovinMediationByteDanceAdapter'
    s.dependency 'AppLovinMediationFyberAdapter'
    s.dependency 'AppLovinMediationInMobiAdapter'
    s.dependency 'AppLovinMediationIronSourceAdapter'
    s.dependency 'AppLovinMediationVungleAdapter'
    s.dependency 'AppLovinMediationMintegralAdapter'
    s.dependency 'AppLovinMediationFacebookAdapter'
    s.dependency 'AppLovinMediationYandexAdapter'
    
    # Dependency Suppport AppLovin Adapter
#   s.dependency 'FBAudienceNetwork'
#   s.dependency 'Ads-Global'
#   s.dependency 'Fyber_Marketplace_SDK'
#    s.dependency 'Google-Mobile-Ads-SDK', '12.7.0'
#    s.dependency 'InMobiSDK'
#    s.dependency 'IronSourceSDK'
#    s.dependency 'MintegralAdSDK'
#    s.dependency 'MintegralAdSDK/BidSplashAd'
#    s.dependency 'UnityAds'
#    s.dependency 'VungleAds'
    
    #Dependency Support AppLovinMediationYandexAdapter
#    s.dependency 'AppMetricaAdSupport'
#    s.dependency 'AppMetricaCore'
#    s.dependency 'AppMetricaCoreExtension'
#    s.dependency 'AppMetricaCoreUtils'
#    s.dependency 'AppMetricaCrashes'
#    s.dependency 'AppMetricaEncodingUtils'
#    s.dependency 'AppMetricaFMDB'
#    s.dependency 'AppMetricaHostState'
#    s.dependency 'AppMetricaIdentifiers'
#    s.dependency 'AppMetricaKeychain'
#    s.dependency 'AppMetricaLibraryAdapter'
#    s.dependency 'AppMetricaLog'
#    s.dependency 'AppMetricaLogSwift'
#    s.dependency 'AppMetricaNetwork'
#    s.dependency 'AppMetricaPlatform'
#    s.dependency 'AppMetricaProtobuf'
#    s.dependency 'AppMetricaProtobufUtils'
#    s.dependency 'AppMetricaStorageUtils'
#    s.dependency 'AppMetricaSynchronization'
#    s.dependency 'BlueCryptor'
#    s.dependency 'BlueECC'
#    s.dependency 'BlueRSA'
#    s.dependency 'DivKit'
#    s.dependency 'DivKitBinaryCompatibilityFacade'
#    s.dependency 'DivKit_LayoutKit'
#    s.dependency 'DivKit_LayoutKitInterface'
#    s.dependency 'DivKit_Serialization'
    
#    s.dependency 'Google-Mobile-Ads-SDK', '12.7.0'
#    s.dependency 'GoogleMobileAdsMediationAppLovin'
#    s.dependency 'GoogleMobileAdsMediationVungle'
#    s.dependency 'GoogleMobileAdsMediationFacebook'
#    s.dependency 'GoogleMobileAdsMediationMintegral'
#    s.dependency 'GoogleMobileAdsMediationPangle'

#    s.dependency 'GoogleUtilities'
#    s.dependency 'FirebaseCore', '11.15.0'
#    s.dependency 'FirebaseRemoteConfig', '11.15.0'
#    s.dependency 'FirebaseABTesting', '11.15.0'
#    s.dependency 'FirebaseAnalytics', '11.15.0'
#    s.dependency 'FirebaseCrashlytics', '11.15.0'
#    s.dependency 'FirebaseMessaging', '11.15.0'
    
#    s.dependency 'AppsFlyer-AdRevenue', '6.14.3'
#    s.dependency 'AppsFlyerFramework', '6.14.3'
#    s.dependency 'PurchaseConnector', '6.14.3'
#    s.dependency 'SwiftJWT', '3.6.200'

end
