Pod::Spec.new do |s|
s.name             = "Spotlight"
s.version          = "1.0.0"
s.summary          = "Opentok plugin for spotlight"
s.description      = "Plugin to be used for spotlight on ios"

s.homepage         = "https://github.com/andreaphillips/ots"
s.license          = 'MIT'
s.author           = { "andreaphillips" => "andrea@agilityfeat.com" }
s.source           = { :git => "https://github.com/andreaphillips/ots.git" }

s.platform     = :ios, '7.0'
s.requires_arc = true

s.source_files = 'Pod/Classes/**/*'
s.resource_bundles = {
'OpenTokSpotlight' => ['Pod/Assets/*.png']
}
s.dependency 'OpenTok'
s.dependency 'SocketIO'

end
