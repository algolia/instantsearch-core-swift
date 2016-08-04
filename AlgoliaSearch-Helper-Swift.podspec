Pod::Spec.new do |s|
    # Pod metadata
    # ------------
    s.name = 'AlgoliaSearch-Helper-Swift'
    s.module_name = 'AlgoliaSearchHelper'
    s.version = '0.1'
    s.license = 'MIT'
    s.summary = 'Helper for the Swift Algolia Search API client'
    s.homepage = 'https://github.com/algolia/algoliasearch-helper-swift'
    s.author   = { 'Algolia' => 'contact@algolia.com' }
    s.source = { :git => 'https://github.com/algolia/algoliasearch-helper-swift.git', :tag => s.version }

    # Build settings
    # --------------
    # NOTE: Deployment targets should be kept in line with the API Client.
    s.ios.deployment_target = '8.0'
    s.osx.deployment_target = '10.10'
    s.tvos.deployment_target = '9.0'

    s.source_files = [
        'Sources/*.swift'
    ]

    # Dependencies
    # ------------
    # NOTE: We use subspecs to distinguish between the online and offline flavors of the API client.
    # WARNING: This works because we only support iOS. If we supported OS X (or other platforms), we would face
    # [the same problem](https://github.com/algolia/algoliasearch-client-swift/commit/1c406eed68ea051b32dc5c13f0637bacdf770187)
    # as the API client itself... :/
    #
    # WARNING: When developing, directly referencing a subspec of a development (local) pod results in an empty
    # "Sources" directory for this pod, making it unusable (bug observed with Cocoapods 1.0.1). A workaround is to
    # keep referencing the top-level pod and change the default subspec.
    #
    s.default_subspec = 'Offline'

    s.subspec 'Online' do |online|
        online.dependency 'AlgoliaSearch-Client-Swift', '~> 3.3'
    end

    s.subspec 'Offline' do |offline|
        offline.dependency 'AlgoliaSearch-Offline-Swift', '~> 3.3'
    end
end
