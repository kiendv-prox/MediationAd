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

    # Dependency with version pinning
    s.dependency 'AppLovinSDK', '13.3.1'
    s.dependency 'AppLovinMediationGoogleAdapter', '12.7.0.0'
    s.dependency 'AppLovinMediationUnityAdsAdapter', '4.15.1.0'
    s.dependency 'AppLovinMediationByteDanceAdapter', '7.4.0.7.0'
    s.dependency 'AppLovinMediationFyberAdapter', '8.3.7.0'
    s.dependency 'AppLovinMediationInMobiAdapter', '10.8.3.1'
    s.dependency 'AppLovinMediationIronSourceAdapter', '8.10.0.0.0'
    s.dependency 'AppLovinMediationVungleAdapter', '7.5.1.4'
    s.dependency 'AppLovinMediationMintegralAdapter', '7.7.8.0.0'
    s.dependency 'AppLovinMediationFacebookAdapter', '6.20.0.0'
    s.dependency 'AppLovinMediationYandexAdapter', '7.14.1.0'
    s.dependency 'FirebaseRemoteConfig', '11.15.0'
    s.dependency 'FirebaseABTesting', '11.15.0'
    s.dependency 'FirebaseAnalytics', '11.15.0'
    s.dependency 'FirebaseCrashlytics', '11.15.0'
    s.dependency 'AppsFlyerFramework', '6.17.0'
    s.dependency 'PurchaseConnector', '6.17.0'
    s.dependency 'AppsFlyer-AdRevenue', '6.9.1'
    s.dependency 'SwiftJWT', '3.6.200'

end
