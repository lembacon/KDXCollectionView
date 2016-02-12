Pod::Spec.new do |s|
s.name = 'KDXCollectionView'
s.version = '0.1.1'
s.license = { :type => 'MIT', :file => 'LICENSE' }
s.summary = 'A better collection view for Mac.'
s.homepage = 'https://github.com/lembacon/KDXCollectionView'
s.author = { 'Chongyu Zhu' => 'lembacon@gmail.com' }
s.source = { :git => 'https://github.com/tsfischer/KDXCollectionView.git' }
s.source_files = 'src/*.{h,c,m}'
s.requires_arc = false

s.osx.deployment_target = '10.6'
s.osx.framework = 'Cocoa'
end