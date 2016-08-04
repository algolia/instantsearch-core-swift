# NOTE: This Podfile is used to draw dependencies when building the project independently (e.g. for unit tests).

use_frameworks!

def common_deps
    pod 'AlgoliaSearch-Client-Swift', :path => '~/devt/workspace/clients-master/algoliasearch-client-swift'
end

target "AlgoliaSearchHelper-iOS" do
    common_deps
end

target "AlgoliaSearchHelper-macOS" do
    common_deps
end

target "AlgoliaSearchHelper-tvOS" do
    common_deps
end
