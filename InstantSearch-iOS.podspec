Pod::Spec.new do |s|
    # Pod metadata
    # ------------
    s.name = 'InstantSearch-iOS'
    s.module_name = 'InstantSearch'
    s.version = '0.1'
    s.license = 'MIT'
    s.summary = 'Instant Search library for iOS, using the Algolia Search API'
    s.homepage = 'https://github.com/algolia/instantsearch-ios'
    s.author   = { 'Algolia' => 'contact@algolia.com' }
    s.source = { :git => 'https://github.com/algolia/instantsearch-ios.git', :tag => s.version }

    # Build settings
    # --------------
    s.ios.deployment_target = '8.0'
    s.source_files = [
        'Sources/*.swift'
    ]

    # Dependencies
    # ------------
    # NOTE: We use subspecs to distinguish between the online and offline flavors of the API client.
    # WARNING: This works because we only support iOS. If we supported OS X (or other platforms), we would face
    # [the same problem](https://github.com/algolia/algoliasearch-client-swift/commit/1c406eed68ea051b32dc5c13f0637bacdf770187)
    # as the API client itself... :/
    s.default_subspec = 'Online'

    s.subspec 'Online' do |online|
        online.dependency 'AlgoliaSearch-Client-Swift', '~> 3.3'
    end

    s.subspec 'Offline' do |offline|
        offline.dependency 'AlgoliaSearch-Offline-Swift', '~> 3.3'
    end
end
