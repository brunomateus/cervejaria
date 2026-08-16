#!/usr/bin/env ruby
#
# Posts/pages/collections reference images and videos with a path that has to
# resolve in two very different places: the VS Code markdown preview (no Jekyll
# involved) and the built site (served from `/` locally and from `/cervejaria`
# on GitHub Pages). Two spellings are therefore allowed in the source:
#
#   /assets/img/brassagem-XXVI/rotulo.png      root-relative
#   ../assets/img/brassagem-XXVI/rotulo.png    relative to the markdown file
#
# This plugin runs in two stages so both end up identical in the output:
#
# 1. `pre_render` collapses the relative spelling into the root-relative one.
#    It must happen before rendering because the Chirpy theme's
#    `_includes/refactor-content.html` blindly prepends `site.baseurl` to every
#    `<img src>`, which would turn `../assets/…` into `/cervejaria../assets/…`.
#
# 2. `post_render` prepends the baseurl to whatever root-relative asset paths
#    the theme did not touch — `<a href>`, `<video src>`, `<source src>`, and
#    anything else outside an `<img>` tag. Jekyll's own `relative_url` filter
#    can't help here: raw HTML attributes never go through Liquid.
#
# Net effect: the markdown source never mentions `/cervejaria`, and both
# `jekyll serve` (baseurl from _config.yml) and the GitHub Actions production
# build (`--baseurl` injected) come out with working links.

module Cervejaria
  module BaseurlAssetFix
    # `src="../assets/…"`, `src="./assets/…"`, `](../assets/…)`, plus any deeper
    # nesting of `../`. The relative segments are dropped rather than resolved:
    # every asset lives under the repo-root `assets/` folder.
    RELATIVE_ASSET_REGEX = %r{(?<=["'(])(?:\.{1,2}/)+(assets/)}

    # A root-relative asset path still missing the baseurl. Anchored on the
    # opening quote so an already-prefixed path can't be prefixed twice.
    ROOT_ASSET_ATTR_REGEX = /(src|href)="(\/assets\/[^"]*)"/

    def self.absolutize(content)
      return content if content.nil?

      content.gsub(RELATIVE_ASSET_REGEX, '/\1')
    end

    def self.add_baseurl(content, baseurl)
      return content if content.nil? || baseurl.nil? || baseurl.empty?

      content.gsub(ROOT_ASSET_ATTR_REGEX) do
        %(#{Regexp.last_match(1)}="#{baseurl.chomp('/')}#{Regexp.last_match(2)}")
      end
    end
  end
end

Jekyll::Hooks.register [:pages, :documents], :pre_render do |item|
  item.content = Cervejaria::BaseurlAssetFix.absolutize(item.content)
end

Jekyll::Hooks.register [:pages, :documents], :post_render do |item|
  baseurl = item.site.config['baseurl']
  item.output = Cervejaria::BaseurlAssetFix.add_baseurl(item.output, baseurl)
end
