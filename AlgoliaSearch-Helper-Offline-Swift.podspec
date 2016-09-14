Pod::Spec.new do |s|
    # Pod metadata
    # ------------
    s.name = 'AlgoliaSearch-Helper-Offline-Swift'
    s.module_name = 'AlgoliaSearchHelper'
    s.version = '0.2'
    s.license = 'MIT'
    s.summary = 'Helper for the Swift Algolia Search API client'
    s.homepage = 'https://github.com/algolia/algoliasearch-helper-swift'
    s.author   = { 'Algolia' => 'contact@algolia.com' }
    s.source = { :git => 'https://github.com/algolia/algoliasearch-helper-swift.git', :tag => s.version }

    # Build settings
    # --------------
    # NOTE: Deployment targets should be kept in line with the API Client.
    s.ios.deployment_target = '8.0'

    s.source_files = [
        'Sources/*.swift'
    ]

    # Dependencies
    # ------------
    s.dependency 'AlgoliaSearch-Offline-Swift', '~> 4.0'
end
