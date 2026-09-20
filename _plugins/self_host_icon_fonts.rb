# jekyll-3rd-party-libraries (third_party_libraries.download: true) fetches the
# icon CSS files but not the webfonts they reference via relative url(../fonts/...),
# so the icons would 404 once the CDN links are gone. This fetches those fonts too.
require 'fileutils'
require 'open-uri'

Jekyll::Hooks.register :site, :after_init do |site|
  libs = site.config['third_party_libraries'] || {}
  next unless libs['download']

  npm_packages = {
    'fontawesome' => '@fortawesome/fontawesome-free',
    'academicons' => 'academicons',
    'scholar-icons' => 'scholar-icons'
  }

  npm_packages.each do |key, package|
    version = libs.dig(key, 'version')
    css_dir = File.join(site.source, 'assets', 'libs', key)
    Dir.glob(File.join(css_dir, '*.css')).each do |css_file|
      File.read(css_file, encoding: 'UTF-8').scan(/url\(\s*['"]?\.\.\/([^)'"?#]+)/).flatten.uniq.each do |rel|
        dest = File.join(site.source, 'assets', 'libs', rel)
        next if File.file?(dest)

        url = "https://cdn.jsdelivr.net/npm/#{package}@#{version}/#{rel}"
        Jekyll.logger.info 'SelfHostFonts:', "Downloading #{url}"
        FileUtils.mkdir_p(File.dirname(dest))
        URI(url).open('rb') { |remote| File.binwrite(dest, remote.read) }
      end
    end
  end
end
