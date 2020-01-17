Pod::Spec.new do |s|
    # Pod metadata
    # ------------
    s.name = 'InstantSearchCore'
    s.module_name = 'InstantSearchCore'
    s.version = '6.4.0'
    s.license = 'Apache 2.0'
    s.summary = 'Instant Search library for Swift by Algolia'
    s.homepage = 'https://github.com/algolia/instantsearch-core-swift'
    s.author   = { 'Algolia' => 'contact@algolia.com' }
    s.source = { :git => 'https://github.com/algolia/instantsearch-core-swift.git', :tag => s.version }
    s.swift_version = '5.0'
    s.swift_versions = ['4.0', '4.2', '5.0']

    # Build settings
    # --------------
    # NOTE: Deployment targets should be kept in line with the API Client.
    s.ios.deployment_target = '8.0'
    s.osx.deployment_target = '10.10'
    s.tvos.deployment_target = '9.0'

    s.source_files = [
        'Sources/**/*.{swift}'
    ]

    # Dependencies
    # ------------
    s.dependency 'InstantSearchClient', '~> 7.0'
    s.dependency 'InstantSearchInsights', '~> 2.3'
end
