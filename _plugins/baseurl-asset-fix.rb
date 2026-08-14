#!/usr/bin/env ruby
#
# Posts/pages/collections always reference images and videos with a plain
# root-relative path (e.g. src="/assets/img/brassagem-XXVI/rotulo.png"),
# because that's what makes them show up in a plain markdown preview (VS
# Code resolves a leading-slash path against the workspace root) without
# needing to run Jekyll at all.
#
# Jekyll's own `relative_url` filter would fix the baseurl for the sites
# built with `--baseurl`, but only for paths that go through Liquid — raw
# HTML `src`/`href` attributes never get touched by it. This hook patches
# the final rendered output instead, so every page gets the right prefix
# in both `jekyll serve` (baseurl from _config.yml) and the GitHub Actions
# production build (baseurl injected via `--baseurl`), with zero manual
# editing in the markdown source, ever.

module Cervejaria
  module BaseurlAssetFix
    ASSET_ATTR_REGEX = /(src|href)="(\/assets\/[^"]*)"/

    def self.rewrite(content, baseurl)
      return content if baseurl.nil? || baseurl.empty?

      content.gsub(ASSET_ATTR_REGEX) do
        attr = Regexp.last_match(1)
        path = Regexp.last_match(2)
        %(#{attr}="#{baseurl}#{path}")
      end
    end
  end
end

Jekyll::Hooks.register [:pages, :documents], :post_render do |item|
  baseurl = item.site.config['baseurl']
  item.output = Cervejaria::BaseurlAssetFix.rewrite(item.output, baseurl)
end
