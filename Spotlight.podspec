Pod::Spec.new do |s|
s.name             = "Spotlight"
s.version          = "1.0.0"
s.summary          = "Opentok plugin for spotlight"
s.description      = "Plugin to be used for spotlight on ios"

s.homepage         = "https://github.com/andreaphillips/ots"
s.license          = 'MIT'
s.author           = { "opentok" => "andrea@agilityfeat.com" }
s.source           = { :git => "https://github.com/opentok/spotlight-ios" }

s.platform     = :ios, '8.0'
s.requires_arc = true
s.source_files = 'Pod/Classes/**/*'
s.resource_bundles = {
'Bundle' => ['Pod/Assets/**/**/*']
}

s.dependency 'OpenTok'
s.dependency 'SIOSocket', '~> 0.2.0'

end
