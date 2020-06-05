Pod::Spec.new do |spec|
    spec.name = 'InstantSearchCore'
    spec.module_name = 'InstantSearchCore'
    spec.version = '7.0.0-beta.1'
    spec.summary = 'Instant Search library for Swift by Algolia'
    spec.homepage = 'https://github.com/algolia/instantsearch-core-swift'
    spec.license = 'Apache 2.0'
    spec.author   = { 'Algolia' => 'contact@algolia.com' }
    spec.documentation_url = "https://www.algolia.com/doc/guides/building-search-ui/getting-started/ios/"
    spec.platforms = { :ios => "8.0", :osx => "10.10", :watchos => "2.0" }
    spec.swift_version = "5.1"
    spec.source = { :git => 'https://github.com/algolia/instantsearch-core-swift.git', :tag => spec.version }
    spec.source_files = "Sources/InstantSEarchCore/**/*.{swift}"
    spec.dependency 'AlgoliaSearchClientSwift', '~> 8.0'
    spec.dependency 'InstantSearchInsights', '~> 2.3'
    spec.dependency 'Logging'
end
