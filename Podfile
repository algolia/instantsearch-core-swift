# NOTE: This Podfile is used to draw dependencies when building the project independently (e.g. for unit tests).

use_frameworks!

def common_deps
    pod 'AlgoliaSearch-Client-Swift', :git => "https://github.com/algolia/algoliasearch-client-swift.git", :branch => "swift-4”
end

target "InstantSearchCore-iOS" do
    common_deps
end

target "InstantSearchCore-iOS-Tests" do
    common_deps
end

target "InstantSearchCore-macOS" do
    common_deps
end

target "InstantSearchCore-macOS-Tests" do
    common_deps
end

target "InstantSearchCore-tvOS" do
    common_deps
end

target "InstantSearchCore-tvOS-Tests" do
    common_deps
end

target "InstantSearchCore-watchOS" do
    common_deps
end
